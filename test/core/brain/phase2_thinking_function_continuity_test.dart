import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_blueprint_binding.dart';
import 'package:slowave/core/brain/conversation_compiler.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/llm_invocation_package.dart';
import 'package:slowave/core/brain/narrow_intelligence.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/perception_engine.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_continuity.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

NightSession _emptySession() {
  final now = DateTime.now().toUtc();
  return NightSession(
    workingMind: WorkingMindView(
      model: LivingMindModel(
        identity: Identity(
          userId: 't',
          preferredLanguage: 'en',
          timezone: 'UTC',
          createdAt: now,
          lastInteractionAt: now,
          totalSessions: 0,
        ),
        mentalPatterns: const [],
        emotionalPatterns: const [],
        triggers: const [],
        beliefs: const [],
        needs: const [],
        preferences: const [],
      ),
    ),
    turns: const [],
  );
}

ThinkingFunctionHypothesis _worst({double c = 0.82}) => ThinkingFunctionHypothesis(
      kind: ThinkingFunctionKind.worstCaseRehearsal,
      confidence: c,
      evidenceIds: const ['current:worst_case'],
      supportTurnCount: 1,
    );

void main() {
  const detector = ThinkingFunctionDetector();
  const continuity = ThinkingFunctionContinuity();
  const perception = PerceptionEngine();
  const policy = ConversationPolicy();
  const narrow = NarrowIntelligence();
  const compiler = ConversationCompiler();

  ThinkingFunctionHypothesis? detectFresh(
    String message, {
    List<String> priors = const [],
  }) {
    var g = const ConversationGroundingBuffer.empty();
    for (final p in priors) {
      g = g.appendUserUtterance(p);
    }
    g = g.appendUserUtterance(message);
    return detector.detect(
      currentMessage: message,
      conversationGrounding: g,
      perceptionEvidence: perception.perceive(message),
    );
  }

  group('Phase 2 semantic family', () {
    test('Build5 T3 scenarios/ends badly → worstCaseRehearsal', () {
      final h = detectFresh(
        "It's not one specific thing. My mind keeps creating different "
        'scenarios, and every one of them ends badly.',
        priors: [
          "I can't stop thinking tonight.",
          'My mind keeps thinking about everything that could go wrong tomorrow.',
        ],
      );
      expect(h, isNotNull);
      expect(h!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(h.confidence, greaterThanOrEqualTo(0.65));
    });

    test('EN paraphrases fire worstCase family', () {
      for (final msg in const [
        'My brain keeps inventing disasters.',
        'Every path I imagine ends worse.',
        'I keep coming up with new worst-case outcomes.',
        'All the scenarios end badly.',
      ]) {
        final h = detectFresh(msg);
        expect(h?.kind, ThinkingFunctionKind.worstCaseRehearsal, reason: msg);
      }
    });

    test('TR paraphrases fire worstCase family', () {
      for (final msg in const [
        'Aklım sürekli kötü senaryolar üretiyor.',
        'Tek bir şey değil, aklım her ihtimali kötüye bağlıyor.',
        'Birini bitiriyorum, başka bir kötü ihtimal geliyor.',
        'Aklım sürekli en kötü sonucu düşünüyor.',
      ]) {
        final h = detectFresh(msg);
        expect(h?.kind, ThinkingFunctionKind.worstCaseRehearsal, reason: msg);
      }
    });
  });

  group('Phase 2 TF continuity', () {
    test('A elaborates same mechanism → persists', () {
      final prior = _worst();
      final resolved = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage:
            'Different scenarios keep showing up and they all end badly.',
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
              'everything that could go wrong tomorrow',
            )
            .appendUserUtterance(
              'Different scenarios keep showing up and they all end badly.',
            ),
        session: _emptySession(),
      );
      expect(resolved, isNotNull);
      expect(resolved!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(resolved.confidence, lessThan(prior.confidence));
      expect(resolved.evidenceIds, contains('continuity:elaboration_refresh'));
    });

    test('B correction invalidates worstCase', () {
      final resolved = continuity.resolve(
        fresh: null,
        prior: _worst(),
        currentMessage:
            "No, I'm not imagining bad outcomes. I'm just excited.",
        session: _emptySession(),
      );
      expect(resolved, isNull);
    });

    test('C topic shift to ex invalidates', () {
      final resolved = continuity.resolve(
        fresh: null,
        prior: _worst(),
        currentMessage: 'Anyway, my ex texted me.',
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
              'everything that could go wrong at work tomorrow',
            )
            .appendUserUtterance('Anyway, my ex texted me.'),
        session: _emptySession(),
      );
      expect(resolved, isNull);
    });

    test('D ambiguous soft continuation decays then can drop', () {
      var prior = _worst(c: 0.50);
      final first = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage: 'I still keep thinking.',
        session: _emptySession(),
      );
      // Prior below supported floor must not persist.
      expect(first, isNull);

      prior = _worst(c: 0.70);
      final soft = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage: 'I still keep thinking.',
        session: _emptySession(),
      );
      expect(soft, isNotNull);
      expect(soft!.confidence, lessThan(0.70));
    });

    test('fresh detection wins over prior', () {
      final fresh = detectFresh(
        'I keep coming up with new worst-case outcomes.',
      );
      final resolved = continuity.resolve(
        fresh: fresh,
        prior: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.earlyTomorrowCarry,
          confidence: 0.72,
          evidenceIds: const ['current:tomorrow'],
          supportTurnCount: 1,
        ),
        currentMessage: 'I keep coming up with new worst-case outcomes.',
        session: _emptySession(),
      );
      expect(resolved!.kind, ThinkingFunctionKind.worstCaseRehearsal);
    });
  });

  group('Phase 2 mechanism-aware Narrow', () {
    test('supported TF shapes mechanism fork overlay', () {
      final stage = ConversationBlueprintCanon.instance
          .bindingFor(ConversationPhase.validation)!;
      final slice = narrow.compile(
        stage: stage,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
              'My mind keeps thinking about everything that could go wrong tomorrow.',
            ),
        thinkingFunctionHypothesis: _worst(),
      );
      expect(slice.aim.toLowerCase(), contains('mechanism'));
      expect(slice.userContent.toLowerCase(), contains('mind-job'));
      expect(slice.userContent.toLowerCase(), contains('rehears'));
      expect(slice.forbiddenMoves.join(' '), contains('GOLD'));
    });

    test('compiler wires TF into Narrow overlay', () {
      final pkg = LlmInvocationPackage(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.narrow,
        understanding: ValidatedUnderstanding(
          thinkingFunctionHypothesis: _worst(),
        ),
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance(
              'everything that could go wrong tomorrow',
            ),
      );
      final compiled = compiler.compile(pkg)!;
      expect(compiled.systemContent.toLowerCase(), contains('mechanism'));
      expect(compiled.userContent.toLowerCase(), contains('rehears'));
    });
  });

  group('Phase 2 Build5 policy progression', () {
    test('after observe+narrow, T3 → standard', () {
      final session = NightSession(
        workingMind: _emptySession().workingMind,
        turns: const [
          SessionTurn(
            releaseDecision:
                ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
            phase: ConversationPhase.validation,
            expressionMode: ConversationExpressionMode.observePurity,
            admittedExpression: PriorAdmittedExpression(
              phase: ConversationPhase.validation,
              text: 'Thinking is loud tonight.',
            ),
          ),
          SessionTurn(
            releaseDecision:
                ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
            phase: ConversationPhase.validation,
            expressionMode: ConversationExpressionMode.narrow,
            admittedExpression: PriorAdmittedExpression(
              phase: ConversationPhase.validation,
              text: 'Specific events or general uncertainty?',
            ),
          ),
        ],
      );
      const t3 =
          "It's not one specific thing. My mind keeps creating different "
          'scenarios, and every one of them ends badly.';
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: t3,
        session: session,
        conversationGrounding: const ConversationGroundingBuffer.empty()
            .appendUserUtterance("I can't stop thinking tonight.")
            .appendUserUtterance(
              'My mind keeps thinking about everything that could go wrong tomorrow.',
            )
            .appendUserUtterance(t3),
        understanding: ValidatedUnderstanding(
          thinkingFunctionHypothesis: detectFresh(t3, priors: [
            "I can't stop thinking tonight.",
            'My mind keeps thinking about everything that could go wrong tomorrow.',
          ]),
        ),
      );
      expect(decision.expressionMode, ConversationExpressionMode.standard);
    });
  });
}
