import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/mechanism_confirmation_semantics.dart';
import 'package:slowave/core/brain/mode_safe_terminal_fallback.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/post_recognition_mechanism_confirmation.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/thinking_function_continuity.dart';
import 'package:slowave/core/brain/thinking_function_detector.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_intelligence_shaping.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';
import 'package:slowave/core/brain/validated_understanding.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

NightSession _session(List<SessionTurn> turns) {
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
    turns: turns,
  );
}

SessionTurn _turn(ConversationExpressionMode mode, {String? text}) {
  return SessionTurn(
    releaseDecision:
        const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
    phase: ConversationPhase.validation,
    expressionMode: mode,
    admittedExpression: text == null
        ? null
        : PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: text,
          ),
  );
}

ValidatedUnderstanding _withTf({
  ThinkingFunctionKind kind = ThinkingFunctionKind.worstCaseRehearsal,
  double confidence = 0.82,
}) {
  return ValidatedUnderstanding(
    thinkingFunctionHypothesis: ThinkingFunctionHypothesis(
      kind: kind,
      confidence: confidence,
      evidenceIds: const ['current:worst_case'],
      supportTurnCount: 2,
    ),
  );
}

NightSession get _afterRecognition => _session([
      _turn(ConversationExpressionMode.observePurity, text: 'observe'),
      _turn(
        ConversationExpressionMode.narrow,
        text: 'bad outcomes or certainty?',
      ),
      _turn(
        ConversationExpressionMode.standard,
        text:
            'Your thoughts are swirling with different scenarios, each one ending badly.',
      ),
    ]);

void main() {
  const detector = ThinkingFunctionDetector();
  const continuity = ThinkingFunctionContinuity();
  const policy = ConversationPolicy();

  group('Live T1–T4 post-recognition confirmation', () {
    test('exact production arc: TF persists + deepen standard', () {
      const t1 = "I can't stop thinking tonight.";
      const t2 =
          'My mind keeps thinking about everything that could go wrong tomorrow.';
      const t3 =
          "It's not one specific thing. My mind keeps creating different scenarios, and every one of them ends badly.";
      const t4 =
          "Maybe. It feels like if I think through every possibility, somehow I'll be more prepared.";

      ThinkingFunctionHypothesis? prior;
      var g = const ConversationGroundingBuffer.empty();

      // T1
      var fresh = detector.detect(currentMessage: t1, conversationGrounding: g);
      prior = continuity.resolve(
        fresh: fresh,
        prior: prior,
        currentMessage: t1,
        conversationGrounding: g,
      );
      g = g.appendUserUtterance(t1);
      expect(prior, isNull);

      // T2
      fresh = detector.detect(currentMessage: t2, conversationGrounding: g);
      prior = continuity.resolve(
        fresh: fresh,
        prior: prior,
        currentMessage: t2,
        conversationGrounding: g,
      );
      g = g.appendUserUtterance(t2);
      expect(prior?.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(prior),
        isTrue,
      );

      // T3
      fresh = detector.detect(currentMessage: t3, conversationGrounding: g);
      prior = continuity.resolve(
        fresh: fresh,
        prior: prior,
        currentMessage: t3,
        conversationGrounding: g,
      );
      g = g.appendUserUtterance(t3);
      expect(prior?.kind, ThinkingFunctionKind.worstCaseRehearsal);

      // T4 — continuity must NOT drop
      fresh = detector.detect(currentMessage: t4, conversationGrounding: g);
      prior = continuity.resolve(
        fresh: fresh,
        prior: prior,
        currentMessage: t4,
        conversationGrounding: g,
        session: _afterRecognition,
      );
      g = g.appendUserUtterance(t4);
      expect(prior, isNotNull);
      expect(prior!.kind, ThinkingFunctionKind.worstCaseRehearsal);
      expect(
        ThinkingFunctionIntelligenceShaping.isSupportedOrStrong(prior),
        isTrue,
      );

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: t4,
        understanding: ValidatedUnderstanding(
          thinkingFunctionHypothesis: prior,
        ),
        session: _afterRecognition,
        conversationGrounding: g,
      );
      expect(decision.expressionMode, ConversationExpressionMode.standard);
      expect(decision.postRecognitionDeepen, isTrue);
      expect(decision.narrowRefinementAfterPartial, isFalse);

      final modeSafe = ModeSafeTerminalFallback.forExpression(
        what: ConversationPhase.validation,
        expressionMode: ConversationExpressionMode.standard,
        userUtterance: t4,
        postRecognitionDeepen: true,
        groundingBlob: g.priorUserUtterances.join('\n'),
        thinkingFunctionHypothesis: prior,
      );
      expect(modeSafe, isNotNull);
      final lower = modeSafe!.text.toLowerCase();
      expect(lower.contains('still here tonight'), isFalse);
      expect(lower.contains('what you said'), isFalse);
      expect(lower.contains('what you named'), isFalse);
    });
  });

  group('Negative / safety cases', () {
    test('A bare Maybe. → no deepen', () {
      expect(MechanismConfirmationSemantics.isSubstantive('Maybe.'), isFalse);
      final d = PostRecognitionMechanismConfirmation.evaluate(
        arc: ConversationArcReader.fromSession(_afterRecognition),
        message: 'Maybe.',
        understanding: _withTf(),
        session: _afterRecognition,
      );
      expect(d, PostRecognitionConfirmationDecision.noBasis);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Maybe.',
        understanding: _withTf(),
        session: _afterRecognition,
      );
      expect(decision.postRecognitionDeepen, isFalse);
      expect(
        decision.expressionMode,
        anyOf(
          ConversationExpressionMode.groundedHold,
          ConversationExpressionMode.observePurity,
        ),
      );
    });

    test('B correction clears TF and blocks deepen', () {
      const msg = "No, that's not it. I'm actually excited.";
      final prior = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 2,
      );
      final resolved = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage: msg,
        session: _afterRecognition,
      );
      expect(resolved, isNull);

      final d = PostRecognitionMechanismConfirmation.evaluate(
        arc: ConversationArcReader.fromSession(_afterRecognition),
        message: msg,
        understanding: const ValidatedUnderstanding(),
        session: _afterRecognition,
      );
      expect(d, PostRecognitionConfirmationDecision.noBasis);
    });

    test('C topic shift does not carry TF', () {
      const msg = 'Anyway, my ex texted me.';
      final prior = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 2,
      );
      final g = const ConversationGroundingBuffer.empty()
          .appendUserUtterance(
            'My mind keeps thinking about everything that could go wrong tomorrow.',
          )
          .appendUserUtterance(
            'My mind keeps creating different scenarios, and every one of them ends badly.',
          );
      final resolved = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage: msg,
        conversationGrounding: g,
        session: _afterRecognition,
      );
      expect(resolved, isNull);
    });

    test('D preparation utility confirmation → deepen', () {
      const msg =
          "It feels like if I think through every possibility, somehow I'll be more prepared.";
      final d = PostRecognitionMechanismConfirmation.evaluate(
        arc: ConversationArcReader.fromSession(_afterRecognition),
        message: msg,
        understanding: _withTf(),
        session: _afterRecognition,
      );
      expect(d, PostRecognitionConfirmationDecision.preferDeepen);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: msg,
        understanding: _withTf(),
        session: _afterRecognition,
      );
      expect(decision.expressionMode, ConversationExpressionMode.standard);
      expect(decision.postRecognitionDeepen, isTrue);
    });

    test('E second deepen consumed → hold', () {
      final afterDeepen = _session([
        ..._afterRecognition.turns,
        _turn(
          ConversationExpressionMode.standard,
          text: 'Using more thinking as preparation may itself keep the mind active tonight.',
        ),
      ]);
      expect(MechanismRecognitionEpoch.deepenConsumed(afterDeepen), isTrue);

      const msg =
          "Yeah — thinking through every possibility so I'll be more prepared.";
      final d = PostRecognitionMechanismConfirmation.evaluate(
        arc: ConversationArcReader.fromSession(afterDeepen),
        message: msg,
        understanding: _withTf(),
        session: afterDeepen,
      );
      expect(d, PostRecognitionConfirmationDecision.alreadyDeepened);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: msg,
        understanding: _withTf(),
        session: afterDeepen,
      );
      expect(decision.expressionMode, ConversationExpressionMode.groundedHold);
      expect(decision.postRecognitionDeepen, isFalse);
    });

    test('F TR equivalent confirmation → deepen', () {
      const msg =
          'Belki. Her ihtimali düşünürsem daha hazırlıklı olacağım gibi geliyor.';
      expect(
        MechanismConfirmationSemantics.confirmsOrElaboratesSameJob(
          msg,
          ThinkingFunctionKind.worstCaseRehearsal,
        ),
        isTrue,
      );
      final prior = ThinkingFunctionHypothesis(
        kind: ThinkingFunctionKind.worstCaseRehearsal,
        confidence: 0.82,
        evidenceIds: const ['current:worst_case'],
        supportTurnCount: 2,
      );
      final resolved = continuity.resolve(
        fresh: null,
        prior: prior,
        currentMessage: msg,
        session: _afterRecognition,
      );
      expect(resolved, isNotNull);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: msg,
        understanding: ValidatedUnderstanding(
          thinkingFunctionHypothesis: resolved,
        ),
        session: _afterRecognition,
      );
      expect(decision.postRecognitionDeepen, isTrue);
      expect(decision.expressionMode, ConversationExpressionMode.standard);
    });

    test('G low-confidence prior → no forced deepen', () {
      final d = PostRecognitionMechanismConfirmation.evaluate(
        arc: ConversationArcReader.fromSession(_afterRecognition),
        message:
            "Maybe. It feels like if I think through every possibility, somehow I'll be more prepared.",
        understanding: _withTf(confidence: 0.50),
        session: _afterRecognition,
      );
      expect(d, PostRecognitionConfirmationDecision.noBasis);
    });
  });
}
