import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/closure_fallback_builder.dart';
import 'package:slowave/core/brain/closure_readiness_gate.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/integrate_fallback_builder.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/release_engine.dart';
import 'package:slowave/core/brain/session_turn.dart';
import 'package:slowave/core/brain/utterance_guard.dart';
import 'package:slowave/core/brain/working_mind_view.dart';

LivingMindModel _emptyModel() {
  final now = DateTime.now().toUtc();
  return LivingMindModel(
    identity: Identity(
      userId: 'test',
      preferredLanguage: 'tr',
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
  );
}

NightSession _sessionWithTurns(List<SessionTurn> turns) {
  return NightSession(
    workingMind: WorkingMindView(model: _emptyModel()),
    turns: turns,
  );
}

List<SessionTurn> _goldenThroughReframeConfirm() {
  return const [
    SessionTurn(
      releaseDecision:
          ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
      phase: ConversationPhase.validation,
      expressionMode: ConversationExpressionMode.observePurity,
      admittedExpression: PriorAdmittedExpression(
        phase: ConversationPhase.validation,
        text: 'Yarın müdürünle konuşacaksın ama uyuyamıyorsun.',
      ),
    ),
    SessionTurn(
      releaseDecision:
          ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
      phase: ConversationPhase.validation,
      expressionMode: ConversationExpressionMode.narrow,
      admittedExpression: PriorAdmittedExpression(
        phase: ConversationPhase.validation,
        text:
            'Müdürünle konuşmak mı seni endişelendiriyor, yoksa o konuşmanın sonucunu düşünmek mi?',
      ),
    ),
    SessionTurn(
      releaseDecision:
          ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
      phase: ConversationPhase.validation,
      expressionMode: ConversationExpressionMode.reframe,
      admittedExpression: PriorAdmittedExpression(
        phase: ConversationPhase.validation,
        text:
            'O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin geceyi açık tutuyor olabilir.',
      ),
    ),
  ];
}

void main() {
  const policy = ConversationPolicy();
  const guard = UtteranceGuard();
  const closureGate = ClosureReadinessGate();
  const releaseEngine = ReleaseEngine();

  group('Slice 3 golden arc routing', () {
    test('reframe confirm → integrate (not postReframeListen)', () {
      final session = _sessionWithTurns(_goldenThroughReframeConfirm());
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Evet, tam olarak bu.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.integrate);
    });

    test('integrate ack → closure', () {
      final session = _sessionWithTurns([
        ..._goldenThroughReframeConfirm(),
        const SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text:
                'O zaman zihnin yarınki konuşmayı çözmekten çok, onun gözünde nasıl görüneceğini şimdiden güvenceye almaya çalışıyor.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Doğru.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.closure);
    });

    test('adversarial: evet ama hala korkuyorum → narrow, not closure', () {
      final session = _sessionWithTurns(_goldenThroughReframeConfirm());
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Evet ama hâlâ çok korkuyorum.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
      expect(decision.narrowRefinementAfterPartial, isTrue);
    });

    test('settling does not Release before closure', () {
      final session = _sessionWithTurns(_goldenThroughReframeConfirm());
      final arc = ConversationArcReader.fromSession(session);
      expect(
        closureGate.allowsRelease(
          arc: arc,
          message: 'Tamam.',
          isLightConversation: false,
        ),
        isFalse,
      );
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.settling,
          confidence: 0.78,
        ),
        message: 'Tamam.',
        session: session,
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, isNot(ConversationExpressionMode.standard));
    });
  });

  group('Slice 3 fallbacks + guard', () {
    test('integrate fallback is evidence-shaped', () {
      final fb = IntegrateFallbackBuilder.forValidation(
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        session: null,
      );
      expect(fb, isNotNull);
      expect(fb!.text, contains('zihnin'));
      expect(fb.text, contains('gözünde'));
    });

    test('closure fallback is personalized', () {
      final fb = ClosureFallbackBuilder.forValidation(
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        session: null,
      );
      expect(fb, isNotNull);
      expect(fb!.text, contains('bu gece'));
      expect(fb.text, isNot(contains('Bu gece bunu çözmek zorunda değilsin')));
    });

    test('integrate guard admits golden line', () {
      const line =
          'O zaman zihnin yarınki konuşmayı çözmekten çok, onun gözünde nasıl görüneceğini şimdiden güvenceye almaya çalışıyor.';
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: line),
        what: ConversationPhase.validation,
        userUtterance: 'Evet, tam olarak bu.',
        expressionMode: ConversationExpressionMode.integrate,
      );
      expect(admitted, isNotNull);
    });

    test('closure guard admits personalized boundary', () {
      const line =
          'Ama onun seni nasıl göreceğini bu gece kesinleştiremezsin. Yarınki konuşma yarının işi. Bu gece kendini onun gözünde kanıtlamak zorunda değilsin.';
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: line),
        what: ConversationPhase.validation,
        userUtterance: 'Doğru.',
        expressionMode: ConversationExpressionMode.closure,
      );
      expect(admitted, isNotNull);
    });

    test('integrate guard rejects Anlıyorum', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(text: 'Anlıyorum.'),
        what: ConversationPhase.validation,
        userUtterance: 'Evet.',
        expressionMode: ConversationExpressionMode.integrate,
      );
      expect(admitted, isNull);
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        expressionMode: ConversationExpressionMode.integrate,
      );
      expect(fallback, isNotNull);
      expect(fallback!.text, isNot('Anlıyorum.'));
    });
  });

  group('Slice 3 arc reader', () {
    test('tracks integrate and closure milestones', () {
      final session = _sessionWithTurns([
        ..._goldenThroughReframeConfirm(),
        const SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Integrate line.',
          ),
        ),
      ]);
      final arc = ConversationArcReader.fromSession(session);
      expect(arc.hadIntegrate, isTrue);
      expect(arc.integrateAwaitingResponse, isTrue);
      expect(arc.problemFocusedArcIncomplete, isTrue);
      expect(arc.reframeConfirmed, isTrue);
    });
  });

  group('Slice 3 resistance recovery', () {
    test('post-closure resistance reopens narrow', () {
      final session = _sessionWithTurns([
        ..._goldenThroughReframeConfirm(),
        const SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Integrate.',
          ),
        ),
        const SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.closure,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Closure.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.settling,
          confidence: 0.78,
        ),
        message: 'Ama yine de düşünmeden duramıyorum.',
        session: session,
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
    });
  });
}
