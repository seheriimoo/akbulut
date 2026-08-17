import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/turn_response_stance_detector.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

void main() {
  const perception = PerceptionEngine();
  const mental = MentalPatternDetector();
  const emotional = EmotionalPatternDetector();
  const stanceDetector = TurnResponseStanceDetector();
  const release = ReleaseEngine();
  const policy = ConversationPolicy();

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

  group('Perception catches common night-load language', () {
    test('spiraling is mental overload', () {
      final evidence = perception.perceive("hi I'm spiraling");
      expect(
        evidence.any((e) => e.value == 'mental_overload'),
        isTrue,
      );
      expect(mental.detect(evidence), isNotEmpty);
    });

    test('stressed is emotional activation', () {
      final evidence = perception.perceive("Yes, I'm very stressed.");
      expect(
        evidence.any((e) => e.value == 'emotional_activation'),
        isTrue,
      );
      expect(emotional.detect(evidence), isNotEmpty);
    });

    test("can't let go is mental overload", () {
      final evidence = perception.perceive("I can't let go");
      expect(
        evidence.any((e) => e.value == 'mental_overload'),
        isTrue,
      );
      expect(mental.detect(evidence), isNotEmpty);
    });

    test('ASCII TR load stems fire mental overload', () {
      for (final line in const [
        'aklim durmuyor',
        'yani yarin toplantida bir sey kaciracagim gibi. durmuyor.',
        'kafayi yicem ya bu gece',
        'yani o kadar dusunuyom ki duramiyom',
      ]) {
        final evidence = perception.perceive(line);
        expect(
          mental.detect(evidence),
          isNotEmpty,
          reason: 'TR load "$line" must be perceived',
        );
      }
    });
  });

  group('ReleaseEngine under active load', () {
    test('screenshot night stays on hold / Receipt — no Permission/Release rush',
        () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      const turns = [
        "hi I'm spiraling",
        "Yes, I'm very stressed.",
        "I can't let go",
      ];

      for (final message in turns) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );

        expect(
          decision.readiness,
          ReleaseReadiness.hold,
          reason: 'load turn "$message" must stay on hold',
        );
        expect(
          conversation.phase,
          anyOf(ConversationPhase.validation, ConversationPhase.naming),
          reason:
              'load turn "$message" must stay Receipt/Naming, not Permission/Release',
        );
        expect(
          conversation.phase,
          isNot(ConversationPhase.permission),
        );
        expect(
          conversation.phase,
          isNot(ConversationPhase.release),
        );

        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }
    });

    test('calm empty turns still climb the ladder', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      ReleaseReadiness? readiness;
      for (var i = 0; i < 8; i++) {
        final decision = release.evaluate(
          understanding: const ValidatedUnderstanding(),
          workingMind: session.workingMind,
          session: session,
        );
        readiness = decision.readiness;
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: ConversationPhase.validation,
          ),
        );
        if (readiness == ReleaseReadiness.transitionReady) break;
      }

      expect(readiness, ReleaseReadiness.transitionReady);
    });
  });

  group('V1 P0: TR / slang / sparse load stays on hold', () {
    test('TR overthinking keeps hold through continued looping', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      const turns = [
        'kafam durmuyor ya. ayni seyi donup duruyorum.',
        'yani yarin toplantida bir sey kaciracagim gibi. durmuyor.',
        'biliyorum ki dusunmek ise yaramıyor ama durduramiyorum.',
        'hala ayni yerdeyim.',
      ];

      for (final message in turns) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );

        expect(
          decision.readiness,
          ReleaseReadiness.hold,
          reason: 'TR load "$message" must stay on hold',
        );
        expect(
          conversation.phase,
          anyOf(ConversationPhase.validation, ConversationPhase.naming),
          reason: 'TR load must stay Receipt/Naming, not Permission/Release',
        );

        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }
    });

    test('uyuyamiyorum / ozledim / kavga register as load', () {
      expect(
        perception.perceive('uyuyamiyorum').isNotEmpty,
        isTrue,
      );
      expect(
        perception.perceive('onu ozledim yine').isNotEmpty,
        isTrue,
      );
      expect(
        perception.perceive('onunla kavga ettik. o donuyor.').isNotEmpty,
        isTrue,
      );
    });

    test('topic change to kavga stays Receipt/Naming, not Permission', () {
      final mind = HcosLiveEntry.emptyMindModel();
      var session = NightSession(
        workingMind: WorkingMindView(model: mind),
        turns: const [],
      );

      for (final message in const [
        'is kafamda. yarin yetisemeyecegim.',
        'aslinda is degil. onunla kavga ettik. o donuyor.',
      ]) {
        final priorPhase =
            session.turns.isEmpty ? null : session.turns.last.phase;
        final understanding = understand(message, priorPhase: priorPhase);
        final decision = release.evaluate(
          understanding: understanding,
          workingMind: session.workingMind,
          session: session,
        );
        final conversation = policy.decide(
          releaseDecision: decision,
          message: message,
          session: session,
          understanding: understanding,
        );
        expect(decision.readiness, ReleaseReadiness.hold);
        expect(
          conversation.phase,
          anyOf(ConversationPhase.validation, ConversationPhase.naming),
        );
        expect(conversation.phase, isNot(ConversationPhase.permission));
        session = session.recordTurn(
          SessionTurn(
            releaseDecision: decision,
            phase: conversation.phase,
          ),
        );
      }
    });
  });
}
