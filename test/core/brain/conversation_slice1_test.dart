import 'package:flutter_test/flutter_test.dart';
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

void main() {
  const policy = ConversationPolicy();
  const guard = UtteranceGuard();

  group('Slice 1 policy routing', () {
    test('first load turn uses observe purity on Receipt', () {
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, ConversationExpressionMode.observePurity);
    });

    test('second Receipt turn after observe uses narrow not standard', () {
      final session = NightSession(
        workingMind: WorkingMindView(model: _emptyModel()),
        turns: const [
          SessionTurn(
            releaseDecision:
                ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
            phase: ConversationPhase.validation,
            expressionMode: ConversationExpressionMode.observePurity,
            admittedExpression: PriorAdmittedExpression(
              phase: ConversationPhase.validation,
              text: 'Yarınki toplantı kafanda dönüyor gibi.',
            ),
          ),
        ],
      );
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Evet.',
        session: session,
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, ConversationExpressionMode.narrow);
    });

    test('correction routes to repair not permission', () {
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(
              readiness: ReleaseReadiness.regulated,
              confidence: 0.7,
            ),
        message: 'Hayır beni yanlış anladın, sunumdan korkmuyorum.',
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, ConversationExpressionMode.repair);
      expect(decision.repairRepetitionProtest, isFalse);
    });

    test('repetition protest routes to repair with repetition flag', () {
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(
              readiness: ReleaseReadiness.regulated,
              confidence: 0.7,
            ),
        message: 'Aynı şeyi söylüyorsun.',
      );
      expect(decision.expressionMode, ConversationExpressionMode.repair);
      expect(decision.repairRepetitionProtest, isTrue);
    });

    test('light conversation routes to light chat mode', () {
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(
              readiness: ReleaseReadiness.regulated,
              confidence: 0.7,
            ),
        message: 'Arkadaşlarla kahve içtik, çok güldük.',
      );
      expect(decision.phase, ConversationPhase.neutralEntry);
      expect(decision.expressionMode, ConversationExpressionMode.lightChat);
    });
  });

  group('Slice 1 guard contracts', () {
    test('observe purity rejects Belki/Sanki reframe', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Belki de onun gözünde nasıl görüneceğini düşünüyorsun.',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNull);
    });

    test('observe purity admits plain mirror', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Yarınki konuşma kafanda dönüp duruyor gibi.',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'Yarın müdürümle konuşacağım, uyuyamıyorum.',
        expressionMode: ConversationExpressionMode.observePurity,
      );
      expect(admitted, isNotNull);
    });

    test('repair admits concession plus one question', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Tamam, orayı yanlış okudum. Seni uyanık tutan ne?',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'Hayır beni yanlış anladın, sunumdan korkmuyorum.',
        expressionMode: ConversationExpressionMode.repair,
      );
      expect(admitted, isNotNull);
    });

    test('repair rejects permission stem', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Bu gece bunu çözmek zorunda değilsin.',
        ),
        what: ConversationPhase.validation,
        userUtterance: 'Hayır beni yanlış anladın.',
        expressionMode: ConversationExpressionMode.repair,
      );
      expect(admitted, isNull);
    });

    test('light chat admits one follow-up question', () {
      final admitted = guard.allow(
        utterance: const ConversationUtterance(
          text: 'Oh :) En çok neye güldünüz?',
        ),
        what: ConversationPhase.neutralEntry,
        userUtterance: 'Arkadaşlarla kahve içtik, çok güldük.',
        expressionMode: ConversationExpressionMode.lightChat,
      );
      expect(admitted, isNotNull);
    });
  });

  group('Slice 1 guard fallbacks', () {
    test('repair fallback is not generic Anlıyorum', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Hayır beni yanlış anladın.',
        expressionMode: ConversationExpressionMode.repair,
      );
      expect(fallback!.text, contains('yanlış okudum'));
      expect(fallback.text, isNot('Anlıyorum.'));
    });

    test('light chat fallback is not Merhaba hazır olduğunda', () {
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.neutralEntry,
        userUtterance: 'Arkadaşlarla kahve içtik.',
        expressionMode: ConversationExpressionMode.lightChat,
      );
      expect(fallback!.text, isNot('Merhaba, hazır olduğunda.'));
    });
  });
}
