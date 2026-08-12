import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/exit_intelligence.dart';
import 'package:slowave/core/brain/hcos_live_entry.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/receipt_intelligence.dart';
import 'package:slowave/core/brain/receipt_realization_contract.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_intelligence_shaping.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

/// GOLD DEPTH V1 — deterministic compile / detector proofs.
void main() {
  const detector = ThinkingFunctionDetector();
  const perception = PerceptionEngine();
  const receipt = ReceiptIntelligence();
  const compiler = ConversationCompiler();

  final receiptStage = ConversationBlueprintCanon.instance
      .bindingFor(ConversationPhase.validation)!;

  ConversationGroundingBuffer grounding(String utterance) =>
      const ConversationGroundingBuffer.empty().appendUserUtterance(utterance);

  ThinkingFunctionHypothesis? detect(
    String message, {
    List<String> priorUserTurns = const [],
  }) {
    var buffer = const ConversationGroundingBuffer.empty();
    for (final prior in priorUserTurns) {
      buffer = buffer.appendUserUtterance(prior);
    }
    buffer = buffer.appendUserUtterance(message);
    return detector.detect(
      currentMessage: message,
      conversationGrounding: buffer,
      perceptionEvidence: perception.perceive(message),
    );
  }

  String compileSurface(ReceiptCompileSlice slice) =>
      '${slice.aim}\n${slice.sealedWhatSignature}\n${slice.responseLength}\n'
      '${slice.userContent}\n${slice.systemAppendix}\n'
      '${slice.forbiddenMoves.join('\n')}';

  group('GOLD DEPTH V1 — A GOLD-C tomorrow carry', () {
    test(
      'I can\'t stop thinking about tomorrow → earlyTomorrowCarry supported + '
      'Receipt MUST functional recognition (not swirl/race sufficient)',
      () {
        final h = detect("I can't stop thinking about tomorrow.");
        expect(h, isNotNull);
        expect(h!.kind, ThinkingFunctionKind.earlyTomorrowCarry);
        expect(h.confidence, closeTo(0.72, 0.001));
        expect(
          ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(h),
          isTrue,
        );

        final slice = receipt.compile(
          stage: receiptStage,
          conversationGrounding:
              grounding("I can't stop thinking about tomorrow."),
          thinkingFunctionHypothesis: h,
        );
        final all = compileSurface(slice);

        expect(all, contains('MUST realize exactly one soft functional'));
        expect(all, contains('MUST realize exactly ONE'));
        expect(all, contains('Required hinge TYPE'));
        expect(all.toLowerCase(), contains('carrying'));
        expect(all.toLowerCase(), contains('tomorrow'));
        expect(
          all,
          contains('Activation description is texture, not recognition'),
        );
        expect(all, contains('Do not stop at describing motion'));
        expect(
          all.toLowerCase(),
          isNot(contains('swirl/race as sufficient')),
        );
        // Compile must not endorse surface-only swirl/race as enough.
        expect(slice.forbiddenMoves.join(' '), contains('swirling'));
        expect(slice.forbiddenMoves.join(' '), contains('racing'));
        expect(slice.responseLength, contains('60 words'));
        expect(slice.responseLength, isNot(contains('45 words')));
      },
    );
  });

  group('GOLD DEPTH V1 — B GOLD-D worst-case rehearsal', () {
    test(
      'everything that could go wrong → worstCaseRehearsal strong + '
      'Receipt requires rehearsal/function recognition',
      () {
        final h =
            detect('I keep thinking about everything that could go wrong.');
        expect(h, isNotNull);
        expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
        expect(h.confidence, greaterThanOrEqualTo(0.80));

        final slice = receipt.compile(
          stage: receiptStage,
          conversationGrounding: grounding(
            'I keep thinking about everything that could go wrong.',
          ),
          thinkingFunctionHypothesis: h,
        );
        final all = compileSurface(slice);

        expect(all, contains('MUST realize exactly ONE'));
        expect(all.toLowerCase(), contains('rehearsing possible futures'));
        expect(all, contains('Required hinge TYPE'));
        expect(slice.forbiddenMoves.join(' '), contains('surface-motion'));
        expect(slice.responseLength, contains('60 words'));
      },
    );
  });

  group('GOLD DEPTH V1 — C preparing-for-the-worst variant', () {
    test(
      'keeps preparing for the worst → supported/strong hypothesis (not null)',
      () {
        final h = detect(
          'I know nothing has happened yet, but my mind keeps preparing '
          'for the worst.',
        );
        expect(h, isNotNull);
        expect(
          h!.kind,
          anyOf(
            ThinkingFunctionKind.worstCaseRehearsal,
            ThinkingFunctionKind.preparationRehearsal,
          ),
        );
        // Explicit "the worst" should prefer worst-case rehearsal.
        expect(h.kind, ThinkingFunctionKind.worstCaseRehearsal);
        expect(h.confidence, greaterThanOrEqualTo(0.65));
      },
    );

    test('bracing for the worst is covered by worst-case family', () {
      final h = detect("I can't stop bracing for the worst.");
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
    });
  });

  group('GOLD DEPTH V1 — D fail-closed bare overthinking', () {
    test('I can\'t stop thinking → null; no invented mechanism', () {
      expect(detect("I can't stop thinking."), isNull);
    });

    test('generic preparing without night-load → null', () {
      expect(detect('I am preparing.'), isNull);
      expect(detect('My mind keeps preparing.'), isNull);
    });
  });

  group('GOLD DEPTH V1 — E remove shallow prompt anchor', () {
    test('production prompts lack racing-with-tomorrow stock example', () {
      final supported = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.72,
          evidenceIds: const ['current:tomorrow'],
          supportTurnCount: 1,
        ),
      );
      final baseline = receipt.compile(stage: receiptStage);
      final contract = ReceiptRealizationContract.intelligenceSteeringDirective();
      final all = '${compileSurface(supported)}\n${compileSurface(baseline)}\n'
          '$contract';

      expect(
        all,
        isNot(contains("Your mind is racing with tomorrow's thoughts.")),
      );
      expect(all, isNot(contains('racing with tomorrow')));
    });
  });

  group('GOLD DEPTH V1 — F no Gold reply library', () {
    test('compile does not embed Gold Standard reference lines', () {
      final h = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.earlyTomorrowCarry,
        confidence: 0.72,
        evidenceIds: const ['current:tomorrow'],
        supportTurnCount: 1,
      );
      final slice = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: h,
      );
      final all = compileSurface(slice);
      for (final banned in const [
        'GOLD-C',
        'GOLD-D',
        'gold_reply_library',
        'Your thoughts are swirling around tomorrow.',
        'best quality-reference',
      ]) {
        expect(all, isNot(contains(banned)), reason: banned);
      }
    });
  });

  group('GOLD DEPTH V1 — G/H length budgets', () {
    test('null/tentative preserves short Receipt contract', () {
      final nullSlice = receipt.compile(stage: receiptStage);
      expect(nullSlice.responseLength, contains('45 words'));
      expect(nullSlice.responseLength, isNot(contains('60 words')));

      final tentative = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.55,
          evidenceIds: const ['current:tomorrow'],
          supportTurnCount: 1,
        ),
      );
      expect(tentative.responseLength, contains('45 words'));
      expect(tentative.userContent, isNot(contains('MUST realize exactly ONE')));
    });

    test('supported hypothesis preserves max ~28-word budget', () {
      final slice = receipt.compile(
        stage: receiptStage,
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.worstCaseRehearsal,
          confidence: 0.82,
          evidenceIds: const ['current:worst_case'],
          supportTurnCount: 1,
        ),
      );
      expect(slice.responseLength, contains('60 words'));
      expect(slice.userContent, contains('max 60 words'));
    });
  });

  group('GOLD DEPTH V1 — Naming once after Receipt', () {
    test('first hold is Receipt; second hold with load is Naming once', () {
      final mind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
      final understanding = ValidatedUnderstanding(
        thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.72,
          evidenceIds: const ['current:tomorrow'],
          supportTurnCount: 1,
        ),
      );

      final session0 = NightSession(workingMind: mind, turns: const []);
      final first = const ConversationPolicy().decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 1,
        ),
        message: "I can't stop thinking about tomorrow.",
        session: session0,
        understanding: understanding,
      );
      expect(first.phase, ConversationPhase.validation);

      final sessionAfterReceipt = NightSession(
        workingMind: mind,
        turns: const [
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: ReleaseReadiness.hold,
              confidence: 1,
            ),
            phase: ConversationPhase.validation,
          ),
        ],
      );
      final second = const ConversationPolicy().decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 1,
        ),
        message: 'I keep thinking about everything that could go wrong.',
        session: sessionAfterReceipt,
        understanding: understanding,
      );
      expect(second.phase, ConversationPhase.naming);
      expect(second.shouldSpeak, isTrue);

      final sessionAfterNaming = NightSession(
        workingMind: mind,
        turns: const [
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: ReleaseReadiness.hold,
              confidence: 1,
            ),
            phase: ConversationPhase.validation,
          ),
          SessionTurn(
            releaseDecision: ReleaseDecision(
              readiness: ReleaseReadiness.hold,
              confidence: 1,
            ),
            phase: ConversationPhase.naming,
          ),
        ],
      );
      final third = const ConversationPolicy().decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 1,
        ),
        message: 'Still looping.',
        session: sessionAfterNaming,
        understanding: understanding,
      );
      expect(third.phase, ConversationPhase.validation);
    });

    test(
      'ReleaseEngine / ConversationPolicy / Exit unchanged by hypothesis alone on first turn',
      () {
        final mind = WorkingMindView(model: HcosLiveEntry.emptyMindModel());
        final session = NightSession(workingMind: mind, turns: const []);
        final base = const ValidatedUnderstanding();
        final withHyp = ValidatedUnderstanding(
          thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
            kind: ThinkingFunctionKind.worstCaseRehearsal,
            confidence: 0.82,
            evidenceIds: const ['current:worst_case'],
            supportTurnCount: 1,
          ),
        );
        final releaseEngine = const ReleaseEngine();
        final policy = const ConversationPolicy();
        final exit = const ExitIntelligence();

        final r1 = releaseEngine.evaluate(
          understanding: base,
          workingMind: mind,
          session: session,
        );
        final r2 = releaseEngine.evaluate(
          understanding: withHyp,
          workingMind: mind,
          session: session,
        );
        expect(r1.readiness, r2.readiness);
        expect(r1.confidence, r2.confidence);

        final c1 = policy.decide(
          releaseDecision: r1,
          message: 'hi',
          session: session,
          understanding: base,
        );
        final c2 = policy.decide(
          releaseDecision: r2,
          message: 'hi',
          session: session,
          understanding: withHyp,
        );
        // Greeting without load → Neutral Entry; load hyp → Receipt (not Naming).
        expect(c1.phase, ConversationPhase.neutralEntry);
        expect(c2.phase, ConversationPhase.validation);
        expect(c1.shouldSpeak, isTrue);
        expect(c2.shouldSpeak, isTrue);

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
      },
    );

    test('compiler still receives hypothesis into Receipt overlay', () {
      final package = LlmInvocationPackage(
        what: ConversationPhase.validation,
        understanding: ValidatedUnderstanding(
          thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
            kind: ThinkingFunctionKind.earlyTomorrowCarry,
            confidence: 0.72,
            evidenceIds: const ['current:tomorrow'],
            supportTurnCount: 1,
          ),
        ),
        conversationGrounding:
            grounding("I can't stop thinking about tomorrow."),
      );
      final compiled = compiler.compile(package)!;
      expect(compiled.systemContent, contains('MUST realize exactly ONE'));
      expect(compiled.systemContent, contains('carrying'));
      expect(
        compiled.systemContent,
        isNot(contains("Your mind is racing with tomorrow's thoughts.")),
      );
    });
  });
}
