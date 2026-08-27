import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_arc_reader.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/discovery/discovery_act.dart';
import 'package:slowave/core/brain/discovery/discovery_planner.dart';
import 'package:slowave/core/brain/discovery/night_mind_map.dart';
import 'package:slowave/core/brain/discovery/night_pattern_id.dart';
import 'package:slowave/core/brain/discovery/nocta_transition_surface.dart';
import 'package:slowave/core/brain/discovery/post_mirror_transition_intent.dart';
import 'package:slowave/core/brain/discovery/semantic_dimension_ledger.dart';
import 'package:slowave/core/brain/discovery/transition_profile.dart';
import 'package:slowave/core/brain/identity.dart';
import 'package:slowave/core/brain/living_mind_model.dart';
import 'package:slowave/core/brain/night_session.dart';
import 'package:slowave/core/brain/prior_admitted_expression.dart';
import 'package:slowave/core/brain/release_decision.dart';
import 'package:slowave/core/brain/session_turn.dart';
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
  const classifier = PostMirrorTransitionIntentClassifier();
  const surface = NoctaTransitionSurface();

  TransitionProfile _profile({
    NightPatternId pattern = NightPatternId.earlyTomorrowCarry,
    String need = 'set_tomorrow_down',
  }) {
    return TransitionProfile(
      pattern: pattern,
      transitionNeed: need,
      blockerKey: 'mind',
    );
  }

  NightSession _postMirrorSession({
    TransitionProfile? profile,
    bool mirrorSurfaced = true,
    bool transitionReady = true,
  }) {
    final p = profile ?? _profile();
    return NightSession(
      workingMind: WorkingMindView(model: _emptyModel()),
      turns: [
        SessionTurn(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
          phase: ConversationPhase.validation,
          expressionMode: ConversationExpressionMode.integrate,
          admittedExpression: const PriorAdmittedExpression(
            phase: ConversationPhase.validation,
            text:
                'Yarını bu geceye taşımak. Anlattıklarından, yarın erken '
                'gelmiş gibi — gece daha başlamadan yer kaplıyor.',
          ),
          sleepMindMirror: true,
        ),
      ],
      mirrorSurfaced: mirrorSurfaced,
      transitionReady: transitionReady,
      transitionProfile: p,
    );
  }

  group('PostMirrorTransitionIntentClassifier', () {
    test('advance matrix covers the seven device phrases', () {
      const phrases = [
        'Peki şimdi ne yapacağım?',
        'Şimdi ne olacak?',
        'Devam edelim.',
        'Hazırım.',
        'Tamam.',
        'Beni uyut.',
        'Sese geç.',
      ];
      for (final phrase in phrases) {
        expect(
          classifier.classify(phrase),
          PostMirrorTransitionIntent.advanceTransition,
          reason: phrase,
        );
      }
    });

    test('explicit Mirror correction → reopen', () {
      expect(
        classifier.classify('Bu ayna yanlış, öyle değil'),
        PostMirrorTransitionIntent.reopenDiscovery,
      );
      expect(
        classifier.classify("That's not what I meant"),
        PostMirrorTransitionIntent.reopenDiscovery,
      );
    });

    test('materially new topic flag → reopen', () {
      expect(
        classifier.classify(
          'Aslında eski sevgilimi özlüyorum',
          materialNewTopic: true,
        ),
        PostMirrorTransitionIntent.reopenDiscovery,
      );
    });
  });

  group('ConversationArcReader post-Mirror', () {
    test('Sleep Mind Mirror does not set classic integrateAwaitingResponse', () {
      final arc = ConversationArcReader.fromSession(_postMirrorSession());
      expect(arc.mirrorSurfaced, isTrue);
      expect(arc.transitionReady, isTrue);
      expect(arc.transitionProfile, isNotNull);
      expect(arc.integrateAwaitingResponse, isFalse);
    });
  });

  group('ConversationPolicy post-Mirror routing', () {
    test('C12 device sequence: after Mirror, what-now → noctaTransition', () {
      final session = _postMirrorSession();
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
        message: 'Peki şimdi ne yapacağım?',
        session: session,
      );

      expect(decision.noctaTransition, isTrue);
      expect(decision.narrowRefinementAfterPartial, isFalse);
      expect(decision.expressionMode, isNot(ConversationExpressionMode.narrow));
      expect(decision.phase, ConversationPhase.continuity);
      expect(session.mirrorSurfaced, isTrue);
      expect(session.transitionProfile?.transitionNeed, 'set_tomorrow_down');
    });

    test('post-Mirror advance never falls to Narrow refine phrase path', () {
      final session = _postMirrorSession();
      for (final phrase in [
        'Peki şimdi ne yapacağım?',
        'Şimdi ne olacak?',
        'Devam edelim.',
        'Hazırım.',
        'Tamam.',
        'Beni uyut.',
      ]) {
        final decision = policy.decide(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
          message: phrase,
          session: session,
        );
        expect(decision.noctaTransition, isTrue, reason: phrase);
        expect(decision.narrowRefinementAfterPartial, isFalse, reason: phrase);
        expect(
          decision.expressionMode,
          isNot(ConversationExpressionMode.narrow),
          reason: phrase,
        );
      }
    });

    test('Sese geç after Mirror → noctaTransition (profile-bound)', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
        message: 'Sese geç.',
        session: _postMirrorSession(),
      );
      expect(decision.noctaTransition, isTrue);
      expect(decision.phase, ConversationPhase.continuity);
    });

    test('Mirror correction clears bridge and does not Narrow-refine', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
        message: 'Bu ayna yanlış, öyle değil',
        session: _postMirrorSession(),
      );
      expect(decision.clearPostMirrorBridge, isTrue);
      expect(decision.noctaTransition, isFalse);
      expect(decision.narrowRefinementAfterPartial, isFalse);
      expect(decision.expressionMode, isNot(ConversationExpressionMode.narrow));
    });

    test('softHold after Mirror is groundedHold, not Narrow', () {
      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
        message: 'bilmiyorum',
        session: _postMirrorSession(),
      );
      expect(decision.expressionMode, ConversationExpressionMode.groundedHold);
      expect(decision.noctaTransition, isFalse);
      expect(decision.narrowRefinementAfterPartial, isFalse);
    });

    test('applyDiscoveryPlan preserves noctaTransition over deferToArc', () {
      const base = ConversationDecision(
        phase: ConversationPhase.continuity,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.closure,
        noctaTransition: true,
      );
      final plan = DiscoveryPlan(
        act: DiscoveryAct.deferToArc,
        map: NightMindMap.empty.copyWith(mirrorEmitted: true),
        ledger: SemanticDimensionLedger.empty,
        reason: 'mirror_already_emitted',
      );
      final out = policy.applyDiscoveryPlan(base, plan);
      expect(out.noctaTransition, isTrue);
      expect(out.narrowRefinementAfterPartial, isFalse);
    });

    test('classic Integrate awaiting still Narrows on resistance', () {
      final session = NightSession(
        workingMind: WorkingMindView(model: _emptyModel()),
        turns: [
          SessionTurn(
            releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
            phase: ConversationPhase.validation,
            expressionMode: ConversationExpressionMode.integrate,
            admittedExpression: const PriorAdmittedExpression(
              phase: ConversationPhase.validation,
              text: 'Bu döngü seni ayakta tutuyor.',
            ),
          ),
        ],
      );
      final arc = ConversationArcReader.fromSession(session);
      expect(arc.integrateAwaitingResponse, isTrue);
      expect(arc.mirrorSurfaced, isFalse);

      final decision = policy.decide(
        releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
        message: 'ama hala durmuyor',
        session: session,
      );
      // Classic resistance may Narrow or hold — must not be noctaTransition.
      expect(decision.noctaTransition, isFalse);
    });
  });

  group('NoctaTransitionSurface', () {
    test('compiles from TransitionProfile.transitionNeed (TR)', () {
      final text = surface.compile(
        _profile(need: 'set_tomorrow_down'),
        preferTurkish: true,
      );
      expect(text.toLowerCase(), contains('yarın'));
      expect(text.toLowerCase(), contains('ses'));
      expect(text, isNot(contains('Tam oturmayan taraf')));
    });
  });

  group('DiscoveryPlanner post-Mirror C13 reopen', () {
    const planner = DiscoveryPlanner();

    test('mirror_already_emitted defers when no reopen', () {
      final plan = planner.plan(
        map: NightMindMap.empty.copyWith(
          mirrorEmitted: true,
          leadingPattern: NightPatternId.earlyTomorrowCarry,
          mapConfidence: 0.9,
        ),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
      );
      expect(plan.act, DiscoveryAct.deferToArc);
      expect(plan.reason, 'mirror_already_emitted');
    });

    test('hypothesisReopenRequired after Mirror → negation_correction_reopen', () {
      final plan = planner.plan(
        map: NightMindMap.empty.copyWith(
          mirrorEmitted: true,
          hypothesisReopenRequired: true,
          leadingPattern: NightPatternId.earlyTomorrowCarry,
          mapConfidence: 0.9,
        ),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
      );
      expect(plan.act, DiscoveryAct.discriminatingQuestion);
      expect(plan.reason, 'negation_correction_reopen');
      expect(plan.map.mirrorEmitted, isFalse);
    });
  });

  group('NightSession Mirror bridge persistence', () {
    test('withMirrorSurfaced / clearPostMirrorBridge', () {
      var session = NightSession(
        workingMind: WorkingMindView(model: _emptyModel()),
        turns: const [],
      );
      final profile = _profile();
      session = session.withMirrorSurfaced(profile);
      expect(session.mirrorSurfaced, isTrue);
      expect(session.transitionReady, isTrue);
      expect(session.transitionProfile?.transitionNeed, 'set_tomorrow_down');

      session = session.recordTurn(
        SessionTurn(
          releaseDecision: const ReleaseDecision(
            readiness: ReleaseReadiness.hold,
            confidence: 1.0,
          ),
          phase: ConversationPhase.continuity,
          expressionMode: ConversationExpressionMode.closure,
        ),
      );
      expect(session.mirrorSurfaced, isTrue);
      expect(session.transitionProfile, isNotNull);

      session = session.clearPostMirrorBridge();
      expect(session.mirrorSurfaced, isFalse);
      expect(session.transitionReady, isFalse);
      expect(session.transitionProfile, isNull);
    });
  });
}
