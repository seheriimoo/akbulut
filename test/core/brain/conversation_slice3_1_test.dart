import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/arc_evidence_context.dart';
import 'package:slowave/core/brain/closure_fallback_builder.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/reframe_readiness_gate.dart';
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

void main() {
  const policy = ConversationPolicy();
  const gate = ReframeReadinessGate();
  const guard = UtteranceGuard();

  group('Slice 3.1 loneliness evidence', () {
    test('substantive relational loneliness is reframe-ready after narrow', () {
      final arc = ConversationArcReader.fromSession(_sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
        ),
      ]));
      expect(
        gate.isReady(
          session: null,
          message: 'Galiba birinin yanımda olduğunu hissetmeyi özlüyorum.',
          understanding: null,
          conversationGrounding: null,
          arc: arc,
        ),
        isTrue,
      );
    });

    test('thin yalnızım alone is not reframe-ready', () {
      final arc = ConversationArcReader.fromSession(_sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
        ),
      ]));
      expect(
        gate.isReady(
          session: null,
          message: 'Yalnızım.',
          understanding: null,
          arc: arc,
        ),
        isFalse,
      );
      expect(gate.isThinEvidenceAfterNarrow('Yalnızım.'), isTrue);
    });
  });

  group('Slice 3.1 ambiguous thin evidence', () {
    test('belki isten after narrow routes refinement not observe', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
        ),
      ]);
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.hold,
          confidence: 0.8,
        ),
        message: 'Belki işten.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
      expect(decision.narrowRefinementAfterPartial, isTrue);
      expect(gate.isThinEvidence('Belki işten.'), isTrue);
    });
  });

  group('Slice 3.1 closure fallback', () {
    test('never silent for missing_someone arc', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Özlem ve kırgınlık bir arada olabilir.',
          ),
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Zihnin iki duygu arasında gidip geliyor.',
          ),
        ),
      ]);
      final fb = ClosureFallbackBuilder.forValidation(
        userUtterance: 'Doğru.',
        session: session,
      );
      expect(fb.text, contains('özlem'));
      final admitted = guard.allow(
        utterance: fb,
        what: ConversationPhase.validation,
        userUtterance: 'Doğru.',
        expressionMode: ConversationExpressionMode.closure,
      );
      expect(admitted, isNotNull);
    });
  });

  group('Slice 3.1 Anlıyorum last resort', () {
    test('observe fallback mirrors overthinking line not Anlıyorum', () {
      final fb = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance:
            'Düşünmezsem hazırlıksız yakalanacakmışım gibi geliyor.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(fb, isNotNull);
      expect(fb!.text, isNot('Anlıyorum.'));
    });

    test('continuity Turkish after sakinim wind-down', () {
      final fb = GuardSafeFallback.forPhase(
        what: ConversationPhase.continuity,
        userUtterance: 'Biraz daha sakinim.',
      );
      expect(fb!.text, 'Bu kadar yeter.');
    });
  });
}
