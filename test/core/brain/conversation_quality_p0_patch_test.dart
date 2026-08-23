import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/explicit_exit_intent.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/release_intelligence.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance.dart';
import 'package:slowave/core/brain/turn_response_stance_detector.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const guard = UtteranceGuard();
  const perception = PerceptionEngine();
  const mental = MentalPatternDetector();
  const emotional = EmotionalPatternDetector();
  const stanceDetector = TurnResponseStanceDetector();
  const release = ReleaseEngine();
  const policy = ConversationPolicy();
  const exit = ExitIntelligence();
  const intent = ExplicitExitIntent();

  ValidatedUnderstanding understand(
    String message, {
    ConversationPhase? priorPhase,
  }) {
    final evidence = perception.perceive(message);
    final mentalPatterns = mental.detect(evidence);
    final emotionalPatterns = emotional.detect(evidence);
    return ValidatedUnderstanding(
      mentalPatterns: mentalPatterns,
      emotionalPatterns: emotionalPatterns,
      turnResponseStance: stanceDetector.detect(
        evidence: evidence,
        hasLoad: mentalPatterns.isNotEmpty || emotionalPatterns.isNotEmpty,
        priorPhase: priorPhase,
      ),
    );
  }

  group('1 language lock', () {
    test('rejects English Release on a Turkish current turn', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Set this down for tonight. The night can hold it.',
          ),
          what: ConversationPhase.release,
          userUtterance: 'sadece uyuyamiyorum iste.',
        ),
        isNull,
      );
    });

    test('admits Turkish Receipt on a Turkish current turn', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Bu gece zor geliyor.',
          ),
          what: ConversationPhase.validation,
          userUtterance: 'sadece uyuyamiyorum iste.',
        ),
        isNotNull,
      );
    });

    test('compiler binds same-language rule', () {
      final compiled = const ConversationCompiler().compile(
        LlmInvocationPackage(what: ConversationPhase.validation),
      )!;
      expect(
        compiled.systemContent,
        contains('Reply in the same language as the current-turn user line'),
      );
    });
  });

  group('2 thin-turn honesty', () {
    test('Receipt compile forbids inventing tomorrow on idk', () {
      var grounding = const ConversationGroundingBuffer.empty();
      grounding = grounding.appendUserUtterance('idk');
      final slice = const ReceiptIntelligence().compile(
        stage: ConversationBlueprintCanon.instance.bindingFor(
          ConversationPhase.validation,
        )!,
        conversationGrounding: grounding,
      );
      expect(slice.userContent.toLowerCase(), contains('anti-invention'));
      expect(slice.userContent.toLowerCase(), contains('tomorrow'));
    });

    test('Guard drops invented tomorrow on bilmiyorum', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Tomorrow feels uncertain, and that can be heavy.',
          ),
          what: ConversationPhase.validation,
          userUtterance: 'bilmiyorum.',
        ),
        isNull,
      );
    });

    test('idk still admits a thin here-now Receipt', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: "That's hard.",
          ),
          what: ConversationPhase.validation,
          userUtterance: 'idk',
        ),
        isNotNull,
      );
    });
  });

  group('3 ASCII close / protest', () {
    test('ASCII konusmak istemiyorum is an explicit night close', () {
      expect(intent.matches('konusmak istemiyorum.'), isTrue);
      expect(
        intent.matches('sadece burdayim. konusmak istemiyorum.'),
        isTrue,
      );
    });

    test('ASCII close routes Enough then audio', () {
      final mind = HcosLiveEntry.emptyMindModel();
      final session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );
      const message = 'konusmak istemiyorum.';
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 1,
        ),
        message: message,
        session: session,
        understanding: const ValidatedUnderstanding(),
      );
      expect(decision.phase, ConversationPhase.continuity);
      expect(
        exit.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1,
          ),
          conversationDecision: decision,
          session: session,
          message: message,
        ),
        ExitDecision.transitionToAudio,
      );
    });

    test('protest recalibrates via Permission, not Receipt restamp', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );
      const first = 'kafam durmuyor.';
      final u1 = understand(first);
      final r1 = release.evaluate(
        understanding: u1,
        workingMind: session.workingMind,
        session: session,
      );
      final p1 = policy.decide(
        releaseDecision: r1,
        message: first,
        session: session,
        understanding: u1,
      );
      session = session.recordTurn(
        SessionTurn(releaseDecision: r1, phase: p1.phase),
      );

      const protest = 'ya yeter bu robot gibi konusma. beni anlamıyosun.';
      final u2 = understand(protest, priorPhase: p1.phase);
      expect(u2.turnResponseStance, TurnResponseStance.holdingAgainstEase);
      final r2 = release.evaluate(
        understanding: u2,
        workingMind: session.workingMind,
        session: session,
      );
      final p2 = policy.decide(
        releaseDecision: r2,
        message: protest,
        session: session,
        understanding: u2,
      );
      expect(intent.matches(protest), isFalse);
      // P1-2: leave failed Receipt pattern via Permission recalibration.
      expect(p2.phase, ConversationPhase.permission);
      expect(p2.phase, isNot(ConversationPhase.release));
      expect(p2.phase, isNot(ConversationPhase.audio));
      expect(p2.phase, isNot(ConversationPhase.validation));
    });
  });

  group('4 Guard-legal Release compile', () {
    test('forbids Naming stems and mixed-language Release', () {
      var grounding = const ConversationGroundingBuffer.empty();
      grounding = grounding.appendUserUtterance(
        "I can't stop thinking about tomorrow.",
      );
      final slice = const ReleaseIntelligence().compile(
        stage: ConversationBlueprintCanon.instance.bindingFor(
          ConversationPhase.release,
        )!,
        conversationGrounding: grounding,
      );
      final blob = '${slice.forbiddenMoves.join('\n')} ${slice.putDownDirective}';
      expect(blob.toLowerCase(), contains('on your mind'));
      expect(blob.toLowerCase(), contains('naming'));
    });

    test('admits a plain put-down without Naming drift', () {
      expect(
        guard.allow(
          utterance: const ConversationUtterance(
            text: 'Leave some of that here tonight.',
          ),
          what: ConversationPhase.release,
          userUtterance: "I can't stop thinking about tomorrow.",
        ),
        isNotNull,
      );
    });
  });

  group('5 TR load / Naming', () {
    test('ASCII TR load stays on hold so Naming can fire after Receipt', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      const t1 = 'kafam durmuyor ya. ayni seyi donup duruyorum.';
      final u1 = understand(t1);
      expect(u1.mentalPatterns, isNotEmpty);
      final r1 = release.evaluate(
        understanding: u1,
        workingMind: session.workingMind,
        session: session,
      );
      final p1 = policy.decide(
        releaseDecision: r1,
        message: t1,
        session: session,
        understanding: u1,
      );
      expect(r1.readiness, ReleaseReadiness.hold);
      expect(p1.phase, ConversationPhase.validation);
      session = session.recordTurn(
        SessionTurn(releaseDecision: r1, phase: p1.phase),
      );

      const t2 = 'yani yarin toplantida bir sey kaciracagim gibi. durmuyor.';
      final u2 = understand(t2, priorPhase: p1.phase);
      expect(u2.mentalPatterns, isNotEmpty);
      final r2 = release.evaluate(
        understanding: u2,
        workingMind: session.workingMind,
        session: session,
      );
      final p2 = policy.decide(
        releaseDecision: r2,
        message: t2,
        session: session,
        understanding: u2,
      );
      expect(r2.readiness, ReleaseReadiness.hold);
      expect(p2.phase, ConversationPhase.naming);
    });

    test('uyuyamiyorum is mental load, not an empty greeting', () {
      final u = understand('uyuyamiyorum.');
      expect(u.mentalPatterns, isNotEmpty);
    });
  });
}
