import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/core/brain/conversation_decision.dart';
import 'package:slowave/core/brain/conversation_expression_mode.dart';
import 'package:slowave/core/brain/conversation_phase.dart';
import 'package:slowave/core/brain/conversation_policy.dart';
import 'package:slowave/core/brain/discovery/discovery_act.dart';
import 'package:slowave/core/brain/discovery/discovery_dimension.dart';
import 'package:slowave/core/brain/discovery/discovery_objective.dart';
import 'package:slowave/core/brain/discovery/discovery_planner.dart';
import 'package:slowave/core/brain/discovery/evidence_extractor.dart';
import 'package:slowave/core/brain/discovery/hypothesis_board.dart';
import 'package:slowave/core/brain/discovery/night_mind_map.dart';
import 'package:slowave/core/brain/discovery/night_pattern_id.dart';
import 'package:slowave/core/brain/discovery/semantic_dimension_ledger.dart';
import 'package:slowave/core/brain/discovery/sleep_mind_mirror.dart';
import 'package:slowave/core/brain/discovery/transition_profile.dart';
import 'package:slowave/core/brain/thinking_function_hypothesis.dart';
import 'package:slowave/core/brain/thinking_function_kind.dart';

void main() {
  group('EvidenceExtractor', () {
    const extractor = EvidenceExtractor();

    test('resolves prep + scenario dimensions from one turn', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message:
            'I keep running scenarios about tomorrow so I feel more prepared, '
            'but each check creates another scenario.',
      );
      expect(map.resolvedDimensions, contains(DiscoveryDimension.thoughtForm));
      expect(
        map.resolvedDimensions,
        contains(DiscoveryDimension.perceivedUtility),
      );
      expect(map.resolvedDimensions, contains(DiscoveryDimension.actualEffect));
      expect(map.perceivedUtility, 'thinking_as_preparation');
      expect(map.actualEffect, 'perpetuates_new_scenarios');
    });

    test('resolves TR perpetual scenario effect', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message: 'Her seferinde yeni bir senaryo daha çıkıyor. Kapanmıyor.',
      );
      expect(map.actualEffect, 'perpetuates_new_scenarios');
      expect(map.resolvedDimensions, contains(DiscoveryDimension.actualEffect));
    });

    test('C14: TR loneliness stem resolves emotionalDriver', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message: 'Bu gece çok yalnızım.',
      );
      expect(map.emotionalDriver, 'loneliness_absence');
      expect(map.unresolvedNeed, 'companionship_presence');
      expect(
        map.resolvedDimensions,
        contains(DiscoveryDimension.emotionalDriver),
      );
      expect(map.resolvedDimensions, isNot(isEmpty));
    });

    test('C03: rehearsal + prepared + temporary relief resolves loop', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message:
            "I'm rehearsing what I'll say in the interview so I feel more "
            'prepared. It helps for a second, then I start again.',
      );
      expect(map.perceivedUtility, 'thinking_as_preparation');
      expect(map.actualEffect, 'perpetuates_new_scenarios');
      expect(map.thoughtForm, isNotNull);
      expect(map.resolvedDimensions, contains(DiscoveryDimension.thoughtForm));
      expect(map.resolvedDimensions, contains(DiscoveryDimension.loopStructure));
    });

    test('C05: protective watch utility from stop-watching/slip', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message: "I can't let it go. If I stop watching, something will slip.",
      );
      expect(map.perceivedUtility, 'protective_watch');
      expect(
        map.resolvedDimensions,
        contains(DiscoveryDimension.perceivedUtility),
      );
    });

    test('C10b: miss having someone resolves loneliness', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message: 'I just miss having someone here.',
      );
      expect(map.emotionalDriver, 'loneliness_absence');
    });

    test('C09: acute heart+breath sets safety caution', () {
      final map = extractor.extract(
        prior: NightMindMap.empty,
        message: 'Kalbim hızlı atıyor. Nefesim yetmiyor.',
      );
      expect(map.acuteSomaticCaution, isTrue);
      expect(map.arousalType, 'somatic_acute');
    });

    test('C13: "I don\'t feel prepared" does not resolve prep utility', () {
      final map = extractor.extract(
        prior: const NightMindMap(
          thoughtForm: 'multiplying_negative_scenarios',
          leadingPattern: NightPatternId.worstCaseRehearsal,
          mapConfidence: 0.8,
          resolvedDimensions: {
            DiscoveryDimension.thoughtForm,
            DiscoveryDimension.arousalType,
          },
        ),
        message: "I don't feel prepared. I feel scared it'll go wrong.",
      );
      expect(map.perceivedUtility, isNot('thinking_as_preparation'));
      expect(map.hypothesisReopenRequired, isTrue);
      expect(
        map.resolvedDimensions.contains(DiscoveryDimension.perceivedUtility),
        isFalse,
      );
    });
  });

  group('HypothesisBoard', () {
    const board = HypothesisBoard();

    test('ranks rehearsal family for prep+scenario language', () {
      final extracted = const EvidenceExtractor().extract(
        prior: NightMindMap.empty,
        message:
            'Scenarios keep ending badly; I rehearse so I won\'t be caught '
            'off guard tomorrow.',
      );
      final hyps = board.rank(
        map: extracted,
        currentMessage:
            'Scenarios keep ending badly; I rehearse so I won\'t be caught '
            'off guard tomorrow.',
        thinkingFunction: ThinkingFunctionHypothesis(
          kind: ThinkingFunctionKind.preparationRehearsal,
          confidence: 0.8,
          evidenceIds: const ['t'],
          supportTurnCount: 2,
        ),
      );
      final mapped = board.applyToMap(extracted, hyps);
      expect(
        mapped.leadingPattern,
        anyOf(
          NightPatternId.worstCaseRehearsal,
          NightPatternId.preparationRehearsal,
        ),
      );
      expect(mapped.mapConfidence, greaterThan(0.3));
    });

    test('C05: protectiveHolding leads from stop-watching language', () {
      final extracted = const EvidenceExtractor().extract(
        prior: NightMindMap.empty,
        message: "I can't let it go. If I stop watching, something will slip.",
      );
      final hyps = board.rank(
        map: extracted,
        currentMessage:
            "I can't let it go. If I stop watching, something will slip.",
      );
      final mapped = board.applyToMap(extracted, hyps);
      expect(mapped.leadingPattern, NightPatternId.protectiveHolding);
    });

    test('C14: lonelinessPresence leads from yalnızım', () {
      final extracted = const EvidenceExtractor().extract(
        prior: NightMindMap.empty,
        message: 'Bu gece çok yalnızım.',
      );
      final hyps = board.rank(
        map: extracted,
        currentMessage: 'Bu gece çok yalnızım.',
      );
      final mapped = board.applyToMap(extracted, hyps);
      expect(mapped.leadingPattern, NightPatternId.lonelinessPresence);
    });

    test('sticky prior survives low-signal follow-up', () {
      final prior = NightMindMap(
        leadingPattern: NightPatternId.earlyTomorrowCarry,
        mapConfidence: 0.7,
        temporalOrientation: 'future',
        topicDomain: 'tomorrow',
        resolvedDimensions: {
          DiscoveryDimension.temporalOrientation,
          DiscoveryDimension.topicDomain,
        },
      );
      final hyps = board.rank(
        map: prior,
        currentMessage: "I don't know, it won't stop.",
      );
      expect(hyps.first.pattern, NightPatternId.earlyTomorrowCarry);
    });
  });

  group('DiscoveryPlanner', () {
    const planner = DiscoveryPlanner();

    test('preserves postRecognitionDeepen over questions', () {
      final plan = planner.plan(
        map: const NightMindMap(
          thoughtForm: 'multiplying_negative_scenarios',
          perceivedUtility: 'thinking_as_preparation',
          leadingPattern: NightPatternId.preparationRehearsal,
          mapConfidence: 0.5,
          resolvedDimensions: {
            DiscoveryDimension.thoughtForm,
          },
        ),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: true,
        preferPostRecognitionDeepen: true,
      );
      expect(plan.act, DiscoveryAct.postRecognitionDeepen);
    });

    test('mirrors when evidence is sufficient', () {
      final map = NightMindMap(
        thoughtForm: 'multiplying_negative_scenarios',
        perceivedUtility: 'thinking_as_preparation',
        actualEffect: 'perpetuates_new_scenarios',
        thinkingFunction: ThinkingFunctionKind.preparationRehearsal,
        leadingPattern: NightPatternId.worstCaseRehearsal,
        mapConfidence: 0.85,
        hypotheses: const [
          DiscoveryHypothesis(
            pattern: NightPatternId.worstCaseRehearsal,
            confidence: 0.85,
          ),
          DiscoveryHypothesis(
            pattern: NightPatternId.certaintyChase,
            confidence: 0.4,
          ),
        ],
        resolvedDimensions: {
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.thinkingFunction,
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.actualEffect,
        },
      );
      final plan = planner.plan(
        map: map,
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
      );
      expect(plan.act, DiscoveryAct.sleepMindMirror);
      expect(plan.stopDiscovery, isTrue);
    });

    test('C03-class: evidence-rich prep mirrors under hard confidence bar', () {
      final extracted = const EvidenceExtractor().extract(
        prior: NightMindMap.empty,
        message:
            "I'm rehearsing what I'll say in the interview so I feel more "
            'prepared. It helps for a second, then I start again.',
      );
      final hyps = const HypothesisBoard().rank(
        map: extracted,
        currentMessage:
            "I'm rehearsing what I'll say in the interview so I feel more "
            'prepared. It helps for a second, then I start again.',
      );
      final mapped = const HypothesisBoard().applyToMap(extracted, hyps);
      final plan = planner.plan(
        map: mapped,
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
        isFirstUserTurn: true,
      );
      expect(plan.act, DiscoveryAct.sleepMindMirror);
      expect(plan.reason, 'sufficient_evidence');
    });

    test('C09: acute somatic routes to safety hold not Mirror', () {
      final extracted = const EvidenceExtractor().extract(
        prior: NightMindMap.empty,
        message: 'Kalbim hızlı atıyor. Nefesim yetmiyor.',
      );
      final hyps = const HypothesisBoard().rank(
        map: extracted,
        currentMessage: 'Kalbim hızlı atıyor. Nefesim yetmiyor.',
      );
      final mapped = const HypothesisBoard().applyToMap(extracted, hyps);
      final plan = planner.plan(
        map: mapped,
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
        isFirstUserTurn: true,
      );
      expect(plan.act, DiscoveryAct.hold);
      expect(plan.reason, 'acute_somatic_safety_hold');
      expect(plan.stopDiscovery, isTrue);
    });

    test('C13: negation reopens — blocks Mirror asserting preparation', () {
      final prior = NightMindMap(
        thoughtForm: 'multiplying_negative_scenarios',
        leadingPattern: NightPatternId.worstCaseRehearsal,
        mapConfidence: 0.84,
        meetCompleted: true,
        arousalType: 'cognitive',
        resolvedDimensions: {
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.thinkingFunction,
          DiscoveryDimension.arousalType,
        },
        hypotheses: const [
          DiscoveryHypothesis(
            pattern: NightPatternId.worstCaseRehearsal,
            confidence: 0.84,
          ),
        ],
      );
      final extracted = const EvidenceExtractor().extract(
        prior: prior,
        message: "I don't feel prepared. I feel scared it'll go wrong.",
      );
      final hyps = const HypothesisBoard().rank(
        map: extracted,
        currentMessage: "I don't feel prepared. I feel scared it'll go wrong.",
      );
      final mapped = const HypothesisBoard().applyToMap(extracted, hyps);
      final plan = planner.plan(
        map: mapped.copyWith(meetCompleted: true),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
        isFirstUserTurn: false,
      );
      expect(plan.act, isNot(DiscoveryAct.sleepMindMirror));
      expect(plan.reason, 'negation_correction_reopen');
      expect(mapped.perceivedUtility, isNot('thinking_as_preparation'));
    });

    test('first turn meets instead of asking', () {
      final plan = planner.plan(
        map: const NightMindMap(
          temporalOrientation: 'future',
          leadingPattern: NightPatternId.earlyTomorrowCarry,
          mapConfidence: 0.6,
          resolvedDimensions: {DiscoveryDimension.temporalOrientation},
        ),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
        isFirstUserTurn: true,
      );
      expect(plan.act, DiscoveryAct.meet);
      expect(plan.reason, 'first_turn_meet');
      expect(plan.map.meetCompleted, isTrue);
    });

    test('asks one IG question when dimensions missing after meet', () {
      final plan = planner.plan(
        map: const NightMindMap(
          thoughtForm: 'multiplying_negative_scenarios',
          leadingPattern: NightPatternId.worstCaseRehearsal,
          mapConfidence: 0.5,
          meetCompleted: true,
          resolvedDimensions: {DiscoveryDimension.thoughtForm},
          hypotheses: [
            DiscoveryHypothesis(
              pattern: NightPatternId.worstCaseRehearsal,
              confidence: 0.5,
            ),
          ],
        ),
        ledger: SemanticDimensionLedger.empty,
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
        isFirstUserTurn: false,
      );
      expect(
        plan.act,
        anyOf(
          DiscoveryAct.clarifyingQuestion,
          DiscoveryAct.deepeningQuestion,
          DiscoveryAct.discriminatingQuestion,
          DiscoveryAct.confirmationQuestion,
        ),
      );
      expect(plan.objective, isNotNull);
      expect(plan.objective!.dimension, isNot(DiscoveryDimension.thoughtForm));
    });

    test('blocks re-ask of already-asked dimension', () {
      final plan = planner.plan(
        map: const NightMindMap(
          thoughtForm: 'multiplying_negative_scenarios',
          leadingPattern: NightPatternId.worstCaseRehearsal,
          mapConfidence: 0.5,
          meetCompleted: true,
          askedDimensions: {DiscoveryDimension.perceivedUtility},
          resolvedDimensions: {DiscoveryDimension.thoughtForm},
        ),
        ledger: const SemanticDimensionLedger(
          asked: {DiscoveryDimension.perceivedUtility},
        ),
        recognitionSurfaced: false,
        preferPostRecognitionDeepen: false,
      );
      expect(plan.objective?.dimension, isNot(DiscoveryDimension.perceivedUtility));
    });
  });

  group('SleepMindMirror + TransitionProfile', () {
    test('compiles mirror and maps blockerKey', () {
      const map = NightMindMap(
        leadingPattern: NightPatternId.worstCaseRehearsal,
        thoughtForm: 'multiplying_negative_scenarios',
        perceivedUtility: 'thinking_as_preparation',
        actualEffect: 'perpetuates_new_scenarios',
        mapConfidence: 0.9,
      );
      final mirror = const SleepMindMirrorCompiler().compile(map);
      expect(mirror.body, contains('prepared'));
      final mirrorTr = const SleepMindMirrorCompiler().compile(
        map,
        preferTurkish: true,
      );
      expect(mirrorTr.body, contains('hazır'));
      final profile = const TransitionProfileBuilder().fromMap(
        map,
        mirror: mirror,
      );
      expect(profile.blockerKey, 'mind');
      expect(profile.transitionNeed, 'permission_to_leave_tomorrow_unresolved');
    });
  });

  group('ConversationPolicy.applyDiscoveryPlan', () {
    const policy = ConversationPolicy();

    test('never overrides postRecognitionDeepen', () {
      const base = ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.standard,
        postRecognitionDeepen: true,
      );
      final plan = DiscoveryPlan(
        act: DiscoveryAct.sleepMindMirror,
        map: NightMindMap.empty,
        ledger: SemanticDimensionLedger.empty,
        reason: 'test',
        stopDiscovery: true,
      );
      final out = policy.applyDiscoveryPlan(base, plan);
      expect(out.postRecognitionDeepen, isTrue);
      expect(out.sleepMindMirror, isFalse);
      expect(out.discoveryAct, DiscoveryAct.postRecognitionDeepen);
    });

    test('maps sleepMindMirror act to integrate + flag', () {
      const base = ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      final plan = DiscoveryPlan(
        act: DiscoveryAct.sleepMindMirror,
        map: NightMindMap.empty,
        ledger: SemanticDimensionLedger.empty,
        reason: 'test',
        stopDiscovery: true,
      );
      final out = policy.applyDiscoveryPlan(base, plan);
      expect(out.sleepMindMirror, isTrue);
      expect(out.expressionMode, ConversationExpressionMode.integrate);
    });

    test('maps question act to narrow + objective', () {
      const base = ConversationDecision(
        phase: ConversationPhase.validation,
        shouldSpeak: true,
        expressionMode: ConversationExpressionMode.observePurity,
      );
      final plan = DiscoveryPlan(
        act: DiscoveryAct.deepeningQuestion,
        map: NightMindMap.empty,
        ledger: SemanticDimensionLedger.empty,
        reason: 'ig',
        objective: const DiscoveryObjective(
          dimension: DiscoveryDimension.actualEffect,
          act: DiscoveryAct.deepeningQuestion,
          intentSummary: 'Test loop effect',
        ),
      );
      final out = policy.applyDiscoveryPlan(base, plan);
      expect(out.expressionMode, ConversationExpressionMode.narrow);
      expect(out.discoveryObjective?.dimension, DiscoveryDimension.actualEffect);
    });
  });
}
