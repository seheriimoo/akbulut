import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/observe_fallback_builder.dart';
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

  group('Slice 2 ReframeReadinessGate', () {
    test('not ready on first Receipt (no observe yet)', () {
      final arc = ConversationArcReader.fromSession(null);
      expect(
        gate.isReady(
          session: null,
          message: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
          understanding: null,
          arc: arc,
        ),
        isFalse,
      );
    });

    test('ready after narrow + substantive causal answer', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Yarınki konuşma kafanda.',
          ),
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Konuşmanın kendisi mi geriyor seni, yoksa onun vereceği tepki mi?',
          ),
        ),
      ]);
      final arc = ConversationArcReader.fromSession(session);
      expect(
        gate.isReady(
          session: session,
          message: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
          understanding: null,
          arc: arc,
        ),
        isTrue,
      );
    });

    test('ready after narrow + emotional relation answer', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Onu çok özlüyorum.',
          ),
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Onu mu özlüyorsun, yoksa onunlayken nasıl hissettiğini mi?',
          ),
        ),
      ]);
      final arc = ConversationArcReader.fromSession(session);
      expect(
        gate.isReady(
          session: session,
          message: 'Galiba onunlayken kendimi daha güvende hissediyordum.',
          understanding: null,
          arc: arc,
        ),
        isTrue,
      );
    });

    test('not ready on thin ambiguous guess after narrow', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Garip bir gerginlik var.',
          ),
        ),
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Gerginlik mi seni rahatsız ediyor?',
          ),
        ),
      ]);
      final arc = ConversationArcReader.fromSession(session);
      expect(
        gate.isReady(
          session: session,
          message: 'Belki işten.',
          understanding: null,
          arc: arc,
        ),
        isFalse,
      );
    });

    test('evet after observe routes narrow under regulated readiness', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Özlem bu gece daha yakın gibi.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.regulated, confidence: 0.8),
        message: 'Evet.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
    });
  });

  group('Slice 2 golden arc routing', () {
    test('T1 observe → T2 narrow after evet → T3 reframe → T4 integrate',
        () {
      final t1 = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      );
      expect(t1.expressionMode, ConversationExpressionMode.observePurity);

      final s1 = _sessionWithTurns([
        SessionTurn(
          releaseDecision:
              const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.observePurity,
          admittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Yarınki konuşma hâlâ kafanda.',
          ),
        ),
      ]);
      final t2 = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Evet.',
        session: s1,
      );
      expect(t2.expressionMode, ConversationExpressionMode.narrow);

      final s2 = _sessionWithTurns([
        ...s1.turns,
        SessionTurn(
          releaseDecision:
              const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.narrow,
          admittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Konuşmanın kendisi mi geriyor seni, yoksa onun vereceği tepki mi?',
          ),
        ),
      ]);
      final groundingT3 = const ConversationGroundingBuffer.empty()
          .appendUserUtterance('Yarın müdürümle konuşacağım, uyuyamıyorum.')
          .appendUserUtterance('Evet.')
          .appendUserUtterance('Tepkisi. Beni yetersiz bulmasından korkuyorum.');
      final t3 = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        session: s2,
        conversationGrounding: groundingT3,
      );
      expect(t3.expressionMode, ConversationExpressionMode.reframe);

      final s3 = _sessionWithTurns([
        ...s2.turns,
        SessionTurn(
          releaseDecision:
              const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text:
                'O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin geceyi açık tutuyor olabilir.',
          ),
        ),
      ]);
      final t4 = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Evet, tam olarak bu.',
        session: s3,
      );
      expect(t4.expressionMode, ConversationExpressionMode.integrate);
    });

    test('reframe correction routes to repair', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Belki sunum seni geriyor.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Hayır, alakası yok.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.repair);
    });

    test('partial reframe response re-narrows', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'O zaman tepki geceyi açık tutuyor olabilir.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Biraz ama tam değil.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
      expect(decision.narrowRefinementAfterPartial, isTrue);
    });

    test('partial aspect confirm uses refinement narrow', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.reframe,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text: 'Yarınki baskı geceyi açık tutuyor olabilir.',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Evet, baskı kısmı.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
      expect(decision.narrowRefinementAfterPartial, isTrue);
    });
  });

  group('Slice 2 observe fallback', () {
    test('user-object aware mirror for manager meeting', () {
      final mirror = ObserveFallbackBuilder.forValidation(
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      );
      expect(mirror?.text, 'Yarınki konuşma hâlâ kafanda.');
      final admitted = guard.allow(
        utterance: mirror!,
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted?.text, mirror.text);
    });

    test('missing someone mirror', () {
      final mirror = ObserveFallbackBuilder.forValidation(
        userUtterance: 'Onu çok özlüyorum.',
      );
      expect(mirror?.text, 'Özlem bu gece daha yakın gibi.');
    });

    test('short missing mirror with diacritics', () {
      final mirror = ObserveFallbackBuilder.forValidation(
        userUtterance: 'Onu özlüyorum.',
      );
      expect(mirror?.text, 'Özlem bu gece daha yakın gibi.');
    });

    test('ambiguous inner mirror', () {
      final mirror = ObserveFallbackBuilder.forValidation(
        userUtterance: 'Bir şey içime oturdu ama ne olduğunu bilmiyorum.',
      );
      expect(mirror?.text, 'Bir şey hâlâ içinde duruyor.');
    });

    test('GuardSafeFallback uses observe mirror not Anlıyorum', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(fallback?.text, isNot('Anlıyorum.'));
      expect(fallback?.text, contains('Yarın'));
    });
  });

  group('Slice 2 guard contracts', () {
    test('narrow admits fork question', () {
      final utterance = ConversationUtterance(
        text: 'Konuşmanın kendisi mi geriyor seni, yoksa onun vereceği tepki mi?',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
        expressionMode: ConversationExpressionMode.narrow,
      );
      expect(admitted, isNotNull);
    });

    test('narrow rejects generic therapy question', () {
      final utterance = ConversationUtterance(
        text: 'Bu seni nasıl hissettiriyor?',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım.',
        expressionMode: ConversationExpressionMode.narrow,
      );
      expect(admitted, isNull);
    });

    test('reframe rejects generic belki fatigue', () {
      final utterance = ConversationUtterance(
        text: 'Belki bunu bırakmakta zorlanıyorsun.',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        expressionMode: ConversationExpressionMode.reframe,
      );
      expect(admitted, isNull);
    });

    test('reframe admits evidence-based soft angle', () {
      final utterance = ConversationUtterance(
        text:
            'O zaman konuşmanın kendisinden çok, onun gözünde nasıl görüneceğin geceyi açık tutuyor olabilir.',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        expressionMode: ConversationExpressionMode.reframe,
      );
      expect(admitted, isNotNull);
    });

    test('reframe rejects belki/sanki stems', () {
      final utterance = ConversationUtterance(
        text:
            'Onun gözünde yetersiz görünme korkusu, belki de kendini ifade edememe hissiyle bağlantılı olabilir.',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Tepkisi. Beni yetersiz bulmasından korkuyorum.',
        expressionMode: ConversationExpressionMode.reframe,
      );
      expect(admitted, isNull);
    });

    test('postReframeListen admits Tamam', () {
      final utterance = ConversationUtterance(text: 'Tamam.');
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Evet, tam olarak bu.',
        expressionMode: ConversationExpressionMode.postReframeListen,
      );
      expect(admitted, isNotNull);
    });

    test('narrow refinement question admits without yoksa fork', () {
      final utterance = ConversationUtterance(
        text: 'Baskı kısmı doğru gibi. Peki eksik kalan taraf ne?',
      );
      final admitted = guard.allow(
        utterance: utterance,
        what: ConversationPhase.validation,
        userUtterance: 'Evet, baskı kısmı.',
        expressionMode: ConversationExpressionMode.narrow,
      );
      expect(admitted, isNotNull);
    });
  });

  group('Slice 2 light chat continuation', () {
    test('hâlâ gülüyorum stays light after light chat', () {
      final session = _sessionWithTurns(const [
        SessionTurn(
          releaseDecision:
              ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
          phase: ConversationPhase.neutralEntry,
          expressionMode: ConversationExpressionMode.lightChat,
          admittedExpression: PriorAdmittedExpression(
            phase: ConversationPhase.neutralEntry,
            text: 'Güzel geçmiş :)',
          ),
        ),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Şimdi eve geldim, hâlâ gülüyorum.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.lightChat);
    });
  });
}
