import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/belief_detector.dart';
import 'package:slowave/core/brain/cognitive_orchestrator.dart';
import 'package:slowave/core/brain/conversation_engine.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/emotional_pattern_detector.dart';
import 'package:slowave/core/brain/exit_decision.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/language_model_client.dart';
import 'package:slowave/core/brain/memory_engine.dart';
import 'package:slowave/core/brain/mental_pattern_detector.dart';
import 'package:slowave/core/brain/need_detector.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/preference_detector.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_summarizer.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

import 'faithful_test_vendor_provider.dart';

void main() {
  const detector = ThinkingFunctionDetector();
  const perception = PerceptionEngine();

  ThinkingFunctionHypothesis? detect(
    String message, {
    List<String> priorUserTurns = const [],
  }) {
    var grounding = const ConversationGroundingBuffer.empty();
    for (final prior in priorUserTurns) {
      grounding = grounding.appendUserUtterance(prior);
    }
    grounding = grounding.appendUserUtterance(message);
    final evidence = perception.perceive(message);
    return detector.detect(
      currentMessage: message,
      conversationGrounding: grounding,
      perceptionEvidence: evidence,
    );
  }

  group('ThinkingFunctionKind', () {
    test('exposes the five runtime kinds', () {
      expect(
        ThinkingFunctionKind.values,
        containsAll([
          ThinkingFunctionKind.protectiveHolding,
          ThinkingFunctionKind.preparationRehearsal,
          ThinkingFunctionKind.earlyTomorrowCarry,
          ThinkingFunctionKind.worstCaseRehearsal,
          ThinkingFunctionKind.certaintyChase,
        ]),
      );
      expect(ThinkingFunctionKind.values, hasLength(5));
    });
  });

  group('ThinkingFunctionHypothesis contract', () {
    test('accepts valid hypothesis', () {
      final h = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.earlyTomorrowCarry,
        confidence: 0.72,
        evidenceIds: const ['current:tomorrow'],
        supportTurnCount: 1,
      );
      expect(h.kind, ThinkingFunctionKind.earlyTomorrowCarry);
      expect(h.confidence, 0.72);
      expect(h.evidenceIds, ['current:tomorrow']);
      expect(h.supportTurnCount, 1);
      expect(() => h.evidenceIds.add('x'), throwsUnsupportedError);
    });
  });

  group('A. Detector positive cases', () {
    test('1. tomorrow continuation → earlyTomorrowCarry supported, not prep',
        () {
      final h = detect("I can't stop thinking about tomorrow.");
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.earlyTomorrowCarry);
      expect(h.confidence, greaterThanOrEqualTo(0.65));
      expect(h.confidence, lessThan(0.80));
      expect(h.kind, isNot(ThinkingFunctionKind.preparationRehearsal));
      expect(h.supportTurnCount, 1);
    });

    test('2. preparation threat → preparationRehearsal strong', () {
      final h =
          detect("I need to keep thinking or I won't be prepared.");
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.preparationRehearsal);
      expect(h.confidence, greaterThanOrEqualTo(0.80));
    });

    test('3. what-if worst → worstCaseRehearsal supported or strong', () {
      final h = detect('What if everything goes wrong?');
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(h.confidence, greaterThanOrEqualTo(0.65));
    });

    test('3b. could-go-wrong family → worstCaseRehearsal strong', () {
      final h =
          detect('I keep thinking about everything that could go wrong.');
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(h.confidence, greaterThanOrEqualTo(0.80));
    });

    test('3c. preparing for the worst → worstCaseRehearsal not null', () {
      final h = detect(
        'I know nothing has happened yet, but my mind keeps preparing '
        'for the worst.',
      );
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(h.confidence, greaterThanOrEqualTo(0.65));
    });

    test('4. one more thought → certaintyChase strong', () {
      final h =
          detect("Maybe one more thought and I'll figure it out.");
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.certaintyChase);
      expect(h.confidence, greaterThanOrEqualTo(0.80));
    });

    test('5. strong protective language → protectiveHolding', () {
      final h = detect(
        'I keep thinking because stopping feels unsafe.',
      );
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.protectiveHolding);
      expect(h.confidence, greaterThanOrEqualTo(0.65));
    });
  });

  group('B. Fail-closed negatives', () {
    test('bare overthinking → null', () {
      expect(detect("I can't stop thinking."), isNull);
    });

    test('generic anxiety → null', () {
      expect(detect("I'm anxious."), isNull);
    });

    test('bare tomorrow → null', () {
      expect(detect('Tomorrow.'), isNull);
    });

    test('bare cannot let go → null (no invented prep/worst/certainty)', () {
      final h = detect("I can't let go.");
      expect(h, isNull);
    });
  });

  group('C. History', () {
    test(
      'T1 tomorrow-load + T2 cannot let go → protectiveHolding supported',
      () {
        final h = detect(
          "I can't let go.",
          priorUserTurns: const [
            "I can't stop thinking about tomorrow.",
          ],
        );
        expect(h, isNotNull);
        expect(h!.kind, ThinkingFunctionKind.protectiveHolding);
        expect(h.confidence, greaterThanOrEqualTo(0.65));
        expect(h.confidence, lessThan(0.80));
        expect(h.supportTurnCount, greaterThanOrEqualTo(2));
        expect(
          h.evidenceIds.any((e) => e.contains('tomorrow')),
          isTrue,
        );
        expect(
          h.evidenceIds.any((e) => e.contains('holding')),
          isTrue,
        );
        // Must not invent prep / worst / certainty from this pair.
        expect(h.kind, isNot(ThinkingFunctionKind.preparationRehearsal));
        expect(h.kind, isNot(ThinkingFunctionKind.worstCaseRehearsal));
        expect(h.kind, isNot(ThinkingFunctionKind.certaintyChase));
      },
    );

    test('history does not invent preparation from tomorrow alone', () {
      final h = detect(
        "I can't stop thinking.",
        priorUserTurns: const ['Tomorrow is coming.'],
      );
      // Current has continuation; prior has tomorrow → earlyTomorrowCarry OK.
      // Must not become preparation.
      if (h != null) {
        expect(h.kind, isNot(ThinkingFunctionKind.preparationRehearsal));
      }
    });
  });

  group('D. Conflict', () {
    test('more specific preparation wins over tomorrow carry cues', () {
      final h = detect(
        "I can't stop thinking about tomorrow because "
        "I won't be prepared if I stop.",
      );
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.preparationRehearsal);
    });

    test('certainty chase wins over bare continuation when both cued', () {
      final h = detect(
        "I can't stop — maybe one more thought and I'll figure it out.",
      );
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.certaintyChase);
    });
  });

  group('E. Architecture regression — Slice 1 does not alter decisions', () {
    late CognitiveOrchestrator orchestrator;
    late WorkingMindView workingMind;

    setUp(() {
      final vendor = FaithfulTestVendorProvider();
      orchestrator = CognitiveOrchestrator(
        perceptionEngine: const PerceptionEngine(),
        mentalPatternDetector: const MentalPatternDetector(),
        emotionalPatternDetector: const EmotionalPatternDetector(),
        beliefDetector: const BeliefDetector(),
        needDetector: const NeedDetector(),
        preferenceDetector: const PreferenceDetector(),
        releaseEngine: const ReleaseEngine(),
        conversationPolicy: const ConversationPolicy(),
        conversationEngine: ConversationEngine(
          languageModelClient: LanguageModelClient(vendorProvider: vendor),
        ),
        exitIntelligence: const ExitIntelligence(),
        sessionSummarizer: const SessionSummarizer(),
        memoryEngine: MemoryEngine(),
      );
      workingMind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
    });

    test('hypothesis attaches without changing Release/Policy/Exit path',
        () async {
      const message = "I can't stop thinking about tomorrow.";
      final evidence = perception.perceive(message);
      final mental = const MentalPatternDetector().detect(evidence);
      final emotional = const EmotionalPatternDetector().detect(evidence);
      final withoutHypothesis = ValidatedUnderstanding(
        mentalPatterns: mental,
        emotionalPatterns: emotional,
      );
      final withHypothesis = ValidatedUnderstanding(
        mentalPatterns: mental,
        emotionalPatterns: emotional,
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.72,
          evidenceIds: const ['current:tomorrow'],
          supportTurnCount: 1,
        ),
      );

      final session = NightSession(workingMind: workingMind, turns: const []);
      final release = const ReleaseEngine();
      final policy = const ConversationPolicy();
      final exit = const ExitIntelligence();

      final r1 = release.evaluate(
        understanding: withoutHypothesis,
        workingMind: workingMind,
        session: session,
      );
      final r2 = release.evaluate(
        understanding: withHypothesis,
        workingMind: workingMind,
        session: session,
      );
      expect(r1.readiness, r2.readiness);
      expect(r1.confidence, r2.confidence);

      final c1 = policy.decide(
        releaseDecision: r1,
        message: message,
        session: session,
        understanding: withoutHypothesis,
      );
      final c2 = policy.decide(
        releaseDecision: r2,
        message: message,
        session: session,
        understanding: withHypothesis,
      );
      expect(c1.phase, c2.phase);
      expect(c1.shouldSpeak, c2.shouldSpeak);
      // First-turn hold stays Receipt; Naming requires prior Receipt.
      expect(c2.phase, ConversationPhase.validation);

      final e1 = exit.decide(
        releaseDecision: r1,
        conversationDecision: c1,
        session: session,
      );
      final e2 = exit.decide(
        releaseDecision: r2,
        conversationDecision: c2,
        session: session,
      );
      expect(e1, e2);
    });

    test('orchestrator attaches hypothesis; grounding stays user-only',
        () async {
      var session = NightSession(workingMind: workingMind, turns: const []);
      final t1 = await orchestrator.processTurn(
        message: "I can't stop thinking about tomorrow.",
        session: session,
        workingMind: workingMind,
      );
      session = t1.session;

      expect(
        t1.conversationGroundingBuffer.userUtterances,
        ["I can't stop thinking about tomorrow."],
      );

      final h = detect("I can't stop thinking about tomorrow.");
      expect(h?.kind, ThinkingFunctionKind.earlyTomorrowCarry);

      final t2 = await orchestrator.processTurn(
        message: "I can't let go.",
        session: session,
        workingMind: workingMind,
        conversationGroundingBuffer: t1.conversationGroundingBuffer,
      );

      expect(
        t2.conversationGroundingBuffer.userUtterances,
        [
          "I can't stop thinking about tomorrow.",
          "I can't let go.",
        ],
      );
      expect(
        t2.conversationDecision.phase,
        anyOf(ConversationPhase.naming, ConversationPhase.validation),
      );
      expect(t2.exitDecision, ExitDecision.continueConversation);

      final historyH = detect(
        "I can't let go.",
        priorUserTurns: const [
          "I can't stop thinking about tomorrow.",
        ],
      );
      expect(historyH?.kind, ThinkingFunctionKind.protectiveHolding);
    });

    test('completeSession still discards grounding (lifecycle unchanged)',
        () async {
      final session = NightSession(workingMind: workingMind, turns: const []);
      final turn = await orchestrator.processTurn(
        message: "I can't stop thinking about tomorrow.",
        session: session,
        workingMind: workingMind,
      );
      expect(turn.conversationGroundingBuffer.isEmpty, isFalse);

      final model = HcosLiveEntry.emptyMindModel();
      orchestrator.completeSession(
        session: turn.session,
        model: model,
      );
      expect(orchestrator.conversationGroundingBuffer.isEmpty, isTrue);
    });

    test('ReleaseEngine ignores thinkingFunctionHypothesis field', () {
      final base = ValidatedUnderstanding(
        mentalPatterns: const MentalPatternDetector().detect(
          perception.perceive("I can't stop thinking about tomorrow."),
        ),
      );
      final decorated = ValidatedUnderstanding(
        mentalPatterns: base.mentalPatterns,
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.certaintyChase,
          confidence: 0.99,
          evidenceIds: const ['forced'],
          supportTurnCount: 1,
        ),
      );
      final session = NightSession(workingMind: workingMind, turns: const []);
      final a = const ReleaseEngine().evaluate(
        understanding: base,
        workingMind: workingMind,
        session: session,
      );
      final b = const ReleaseEngine().evaluate(
        understanding: decorated,
        workingMind: workingMind,
        session: session,
      );
      expect(a.readiness, ReleaseReadiness.hold);
      expect(b.readiness, a.readiness);
    });
  });
}
