import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_grounding_buffer.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/conversation_utterance.dart';
import 'package:slowave/core/brain/grounded_progression.dart';
import 'package:slowave/core/brain/guard_safe_fallback.dart';
import 'package:slowave/core/brain/hold_act_dedup.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/narrow_fallback_builder.dart';
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

NightSession _sessionWithTurns(List<SessionTurn> turns) {
  return NightSession(
    workingMind: WorkingMindView(model: _emptyModel()),
    turns: turns,
  );
}

void main() {
  const guard = UtteranceGuard();
  const policy = ConversationPolicy();

  group('GroundedNarrowContract', () {
    test('rejects invented baskı when user spoke about nefes', () {
      const user = 'Sanırım yanımda birinin nefes aldığını duymak istiyorum.';
      expect(
        GroundedNarrowContract.admitsNarrowText(
          noctaText: 'Baskı kısmı doğru gibi. Peki eksik kalan taraf ne?',
          userUtterance: user,
        ),
        isFalse,
      );
      final fallback = NarrowFallbackBuilder.forValidation(
        userUtterance: 'Evet, öyle.',
        refinementAfterPartial: true,
        groundingBlob: user,
      );
      expect(fallback!.text.toLowerCase(), isNot(contains('baskı')));
    });

    test('allows grounded fragment from user words', () {
      expect(
        GroundedNarrowContract.admitsNarrowText(
          noctaText: 'Yalnızlık kısmı doğru gibi. Peki eksik kalan taraf ne?',
          userUtterance: 'Evet, yalnızlık kısmı doğru ama başka bir şey de var.',
        ),
        isTrue,
      );
    });
  });

  group('Mirror saturation', () {
    test('blocks third consecutive mirror', () {
      final session = _sessionWithTurns([
        _turn('Uyuyamıyorum söylüyorsun.'),
        _turn('iş stresi söylüyorsun.'),
      ]);
      expect(ProgressionStateReader.isMirrorSaturated(session), isTrue);
      final mirror = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'evet',
        expressionMode: ConversationExpressionMode.observePurity,
        session: session,
      );
      expect(mirror!.text.toLowerCase(), isNot(contains('söylüyorsun')));
    });
  });

  group('Arc preservation B02', () {
    test('scheduling detail after integrate routes to closure', () {
      final session = _sessionWithTurns([
        _turn('Patron güven reframe.', mode: ConversationExpressionMode.reframe),
        _turn('Integrate line.', mode: ConversationExpressionMode.integrate),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Yarın sabah erken toplantı var, içim gıcır gıcır.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.closure);
    });
  });

  group('Vent vs light chat', () {
    test('frustration vent is not light conversation', () {
      expect(
        VentStackDetector.hasFrustrationMarkers(
          'Bir de komşu gürültü yaptı, sinir oldum.',
        ),
        isTrue,
      );
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.regulated, confidence: 0.8),
        message: 'Bir de komşu gürültü yaptı, sinir oldum.',
        session: null,
      );
      expect(decision.expressionMode, isNot(ConversationExpressionMode.lightChat));
    });

    test('guard rejects playful light ack on vent user line', () {
      expect(
        guard.allow(
          utterance: ConversationUtterance(text: 'Güzel :)'),
          what: ConversationPhase.neutralEntry,
          expressionMode: ConversationExpressionMode.lightChat,
          userUtterance: 'Bir de komşu gürültü yaptı, sinir oldum.',
        ),
        isNull,
      );
    });

    test('rejects playful light ack on pseudo-positive after vent corpus', () {
      expect(
        guard.allow(
          utterance: ConversationUtterance(text: 'Güzel :)'),
          what: ConversationPhase.neutralEntry,
          expressionMode: ConversationExpressionMode.lightChat,
          userUtterance: 'Tamam biraz konuştum.',
          mirrorGroundingUtterance:
              'Bugün her şey üst üste geldi. Bir de komşu gürültü yaptı, sinir oldum.',
        ),
        isNull,
      );
    });

    test('B10 pseudo-positive after vent routes to validation not lightChat', () {
      final session = _sessionWithTurns([
        _turn('Fork?', mode: ConversationExpressionMode.narrow),
      ]);
      // Grounding window is only 3 turns — vent fell out; latch must carry it.
      final grounding = ConversationGroundingBuffer.empty()
          .appendUserUtterance('Aslında en çok yalnız kalmaktan korkuyorum.')
          .appendUserUtterance('Evet evet.')
          .appendUserUtterance('Tamam biraz konuştum.');
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
          readiness: ReleaseReadiness.regulated,
          confidence: 0.8,
        ),
        message: 'Tamam biraz konuştum.',
        session: session,
        conversationGrounding: grounding,
        sessionVentCorpus:
            'Bugün her şey üst üste geldi, sinir oldum. Bir de komşu gürültü yaptı, sinir oldum.',
      );
      expect(decision.phase, ConversationPhase.validation);
      expect(decision.expressionMode, isNot(ConversationExpressionMode.lightChat));
    });
  });

  group('Narrow exhaustion hold', () {
    test('third narrow attempt becomes grounded hold', () {
      final session = _sessionWithTurns([
        _turn('Fork?', mode: ConversationExpressionMode.narrow),
        _turn('Refine?', mode: ConversationExpressionMode.narrow),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Bilmiyorum, hâlâ net değil.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.groundedHold);
    });
  });

  group('Session vent memory', () {
    test('blocks playful light after vent until genuine shift', () {
      expect(
        SessionVentMemory.blocksPlayfulLight(
          session: null,
          grounding: ConversationGroundingBuffer.empty()
              .appendUserUtterance('Aslında en çok yalnız kalmaktan korkuyorum.')
              .appendUserUtterance('Evet evet.'),
          currentMessage: 'Tamam biraz konuştum.',
          sessionVentCorpus:
              'Bugün her şey üst üste geldi, sinir oldum.',
        ),
        isTrue,
      );
      expect(
        SessionVentMemory.isPseudoPositiveContinuation('Tamam biraz konuştum.'),
        isTrue,
      );
    });
  });

  group('Concern shift B29', () {
    test('detects pivot from headache to loneliness', () {
      expect(
        ConcernShiftDetector.isShift(
          currentMessage: 'Yalnız kaldığımı fark ettim az önce.',
          grounding: ConversationGroundingBuffer.empty()
              .appendUserUtterance('Başım ağrıyor sanırım.')
              .appendUserUtterance('Aslında ağrı değil de boşluk gibi.'),
        ),
        isTrue,
      );
    });
  });

  group('Post-hold narrow budget B24', () {
    test('settling after groundedHold stays hold not third narrow', () {
      final session = _sessionWithTurns([
        _turn('Fork 1', mode: ConversationExpressionMode.narrow),
        _turn('Fork 2', mode: ConversationExpressionMode.narrow),
        _turn('Hold', mode: ConversationExpressionMode.groundedHold),
      ]);
      final decision = policy.decide(
        releaseDecision:
            const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
        message: 'Tamam halledeceğim sabah.',
        session: session,
      );
      expect(decision.expressionMode, ConversationExpressionMode.groundedHold);
    });

    test('narrow count persists across groundedHold', () {
      final session = _sessionWithTurns([
        _turn('Fork 1', mode: ConversationExpressionMode.narrow),
        _turn('Fork 2', mode: ConversationExpressionMode.narrow),
        _turn('Hold', mode: ConversationExpressionMode.groundedHold),
      ]);
      expect(
        NarrowConcernBudget.countForCurrentConcern(session: session),
        2,
      );
      expect(NarrowConcernBudget.isExhausted(session: session), isTrue);
    });
  });

  group('Dismiss minimization B03', () {
    test('observe fallback avoids Anlıyorum on dismiss with prior load', () {
      final session = _sessionWithTurns([
        _turn('Para işleri biraz sıkıştı yine söylüyorsun.'),
      ]);
      final fallback = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Önemli değil aslında, hallederim.',
        expressionMode: ConversationExpressionMode.observePurity,
        session: session,
        grounding: ConversationGroundingBuffer.empty()
            .appendUserUtterance('Para işleri biraz sıkıştı yine.'),
      );
      expect(fallback!.text, isNot('Anlıyorum.'));
    });
  });

  group('GroundedHold contract', () {
    test('rejects vent ack without vent evidence', () {
      expect(
        GroundedHoldContract.admits(
          noctaText: 'Bugün gerçekten üst üste gelmiş.',
          userUtterance:
              'Sanırım yanımda birinin nefes aldığını duymak istiyorum.',
        ),
        isFalse,
      );
    });
  });

  group('B4.1.1 hold dedup', () {
    test('second groundedHold on same concern uses alternate act', () {
      final session = _sessionWithTurns([
        _turn(
          'Henüz tam oturmadı ama seni kaybetmedim. Bu gece burada kalabilir.',
          mode: ConversationExpressionMode.groundedHold,
        ),
      ]);
      final hold = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Evet.',
        expressionMode: ConversationExpressionMode.groundedHold,
        session: session,
        grounding: ConversationGroundingBuffer.empty()
            .appendUserUtterance('Belki de asıl korkum başarısız görünmek.'),
      );
      expect(hold!.text, isNot(contains('Henüz tam oturmadı')));
    });

    test('B11 minimal ack does not repeat Tamam after Tamam', () {
      final session = _sessionWithTurns([
        _turn('Tamam.', mode: ConversationExpressionMode.observePurity),
      ]);
      final alt = HoldActDedup.alternateMinimalLanding(
        session: session,
        userUtterance: 'tamam.',
        prefersTurkish: true,
      );
      expect(alt!.text.trim(), isNot('Tamam.'));
    });

    test('B24 settling after hold mirrors instead of repeating hold', () {
      final session = _sessionWithTurns([
        _turn('Fork 1', mode: ConversationExpressionMode.narrow),
        _turn('Fork 2', mode: ConversationExpressionMode.narrow),
        _turn(
          'Henüz tam oturmadı ama seni kaybetmedim. Bu gece burada kalabilir.',
          mode: ConversationExpressionMode.groundedHold,
        ),
      ]);
      final hold = GuardSafeFallback.forPhase(
        what: ConversationPhase.validation,
        userUtterance: 'Tamam halledeceğim sabah.',
        expressionMode: ConversationExpressionMode.groundedHold,
        session: session,
      );
      expect(hold!.text.toLowerCase(), isNot(contains('henüz tam oturmad')));
    });
  });

  group('B4.1.1 concern shift ack B29', () {
    test('shift disclosure gets mirror not terminal phrase', () {
      final ack = HoldActDedup.concernShiftAcknowledge(
        userUtterance: 'Yalnız kaldığımı fark ettim az önce.',
        grounding: ConversationGroundingBuffer.empty()
            .appendUserUtterance('Başım ağrıyor sanırım.')
            .appendUserUtterance('Aslında ağrı değil de boşluk gibi.'),
      );
      expect(ack, isNotNull);
      expect(ack!.text.toLowerCase(), isNot(contains('az önce söylediğin')));
      expect(ack.text.toLowerCase(), anyOf(contains('yalniz'), contains('yalnız')));
    });
  });
}

SessionTurn _turn(
  String text, {
  ConversationExpressionMode mode = ConversationExpressionMode.observePurity,
}) {
  return SessionTurn(
    releaseDecision:
        const ReleaseDecision(readiness: ReleaseReadiness.hold, confidence: 0.8),
    phase: ConversationPhase.validation,
    admittedExpression: PriorAdmittedExpression(
      phase: ConversationPhase.validation,
      text: text,
    ),
    expressionMode: mode,
  );
}
