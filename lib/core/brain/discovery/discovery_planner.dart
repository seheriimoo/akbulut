import 'discovery_act.dart';
import 'discovery_dimension.dart';
import 'discovery_objective.dart';
import 'night_mind_map.dart';
import 'night_pattern_id.dart';
import 'semantic_dimension_ledger.dart';

/// Planner output for one turn.
class DiscoveryPlan {
  final DiscoveryAct act;
  final DiscoveryObjective? objective;
  final NightMindMap map;
  final SemanticDimensionLedger ledger;
  final bool stopDiscovery;
  final String reason;

  const DiscoveryPlan({
    required this.act,
    required this.map,
    required this.ledger,
    required this.reason,
    this.objective,
    this.stopDiscovery = false,
  });
}

/// Information-gain discovery planner.
///
/// Owns WHAT to learn / when to mirror. Never owns fixed question wording.
///
/// Rhythm contract (audit correction):
/// MEET → EXPLORE → REFLECT/ASK → RECOGNIZE → MIRROR
class DiscoveryPlanner {
  const DiscoveryPlanner({
    this.minMirrorConfidence = 0.72,
    this.minGapToSecond = 0.12,
    this.maxDiscoveryDepth = 6,
  });

  final double minMirrorConfidence;
  final double minGapToSecond;
  final int maxDiscoveryDepth;

  DiscoveryPlan plan({
    required NightMindMap map,
    required SemanticDimensionLedger ledger,
    required bool recognitionSurfaced,
    required bool preferPostRecognitionDeepen,
    bool isFirstUserTurn = false,
    int userTurnIndex = 0,
  }) {
    final mergedLedger = ledger.mergeFromMap(
      mapAsked: map.askedDimensions,
      mapResolved: map.resolvedDimensions,
    );

    if (map.mirrorEmitted) {
      return DiscoveryPlan(
        act: DiscoveryAct.deferToArc,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        reason: 'mirror_already_emitted',
      );
    }

    // Preserve Build 8 deepen path when policy/confirmation earns it.
    if (preferPostRecognitionDeepen) {
      return DiscoveryPlan(
        act: DiscoveryAct.postRecognitionDeepen,
        map: map.copyWith(
          discoveryDepth: map.discoveryDepth + 1,
          lastPlanWasQuestion: false,
        ),
        ledger: mergedLedger,
        reason: 'post_recognition_deepen',
      );
    }

    // Acute somatic: do not Mirror as a sleep pattern. Soft safety hold.
    if (map.acuteSomaticCaution) {
      return DiscoveryPlan(
        act: DiscoveryAct.hold,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        stopDiscovery: true,
        reason: 'acute_somatic_safety_hold',
      );
    }

    // Explicit negation/correction: never Mirror the rejected claim.
    // Prefer a fresh discriminating probe.
    if (map.hypothesisReopenRequired && !map.mirrorEmitted) {
      final act = DiscoveryAct.discriminatingQuestion;
      final dimension = DiscoveryDimension.emotionalDriver;
      final objective = DiscoveryObjective(
        dimension: dimension,
        act: act,
        intentSummary:
            'User corrected a prior inference. Discriminate what remains '
            'strongest in their words without re-asserting the rejected claim '
            '(e.g. fear of outcomes vs need to know what will happen).',
        forbiddenDimensions: [
          ...mergedLedger.resolved,
          DiscoveryDimension.perceivedUtility,
        ],
        discriminateA: 'fear_of_bad_ending',
        discriminateB: 'need_to_know_what_happens',
        leadingPattern: map.leadingPattern,
      );
      return DiscoveryPlan(
        act: act,
        objective: objective,
        map: map.copyWith(
          askedDimensions: {...map.askedDimensions, dimension},
          discoveryDepth: map.discoveryDepth + 1,
          lastPlanWasQuestion: true,
          clearHypothesisReopen: true,
        ),
        ledger: mergedLedger.markAsked(dimension),
        reason: 'negation_correction_reopen',
      );
    }

    if (_shouldMirror(map)) {
      return DiscoveryPlan(
        act: DiscoveryAct.sleepMindMirror,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        stopDiscovery: true,
        reason: 'sufficient_evidence',
      );
    }

    // First-turn contract: meet (Receipt/Observe), never forced-choice ask.
    // Exception: sufficient evidence already mirrored above.
    if (isFirstUserTurn || !map.meetCompleted) {
      return DiscoveryPlan(
        act: DiscoveryAct.meet,
        map: map.copyWith(
          meetCompleted: true,
          lastPlanWasQuestion: false,
        ),
        ledger: mergedLedger,
        reason: 'first_turn_meet',
      );
    }

    // Prefer soft mirror over unknown escape; avoid still-here sink.
    if (recognitionSurfaced) {
      if (_softMirrorEligible(map) || map.recognitionHoldCount >= 1) {
        return DiscoveryPlan(
          act: DiscoveryAct.sleepMindMirror,
          map: map.copyWith(lastPlanWasQuestion: false),
          ledger: mergedLedger,
          stopDiscovery: true,
          reason: map.recognitionHoldCount >= 1
              ? 'recognition_hold_escape_mirror'
              : 'recognition_soft_mirror',
        );
      }
      return DiscoveryPlan(
        act: DiscoveryAct.hold,
        map: map.copyWith(
          lastPlanWasQuestion: false,
          recognitionHoldCount: map.recognitionHoldCount + 1,
        ),
        ledger: mergedLedger,
        reason: 'recognition_soft_hold',
      );
    }

    // Hard stop before more questions: long nights must Mirror.
    if (userTurnIndex >= 4) {
      return DiscoveryPlan(
        act: DiscoveryAct.sleepMindMirror,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        stopDiscovery: true,
        reason: 'turn_cap_soft_mirror',
      );
    }

    if (map.discoveryDepth >= maxDiscoveryDepth) {
      return DiscoveryPlan(
        act: DiscoveryAct.sleepMindMirror,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        stopDiscovery: true,
        reason: map.leadingPattern == NightPatternId.unknown
            ? 'depth_cap_unknown_soft_mirror'
            : 'depth_cap_low_confidence_mirror',
      );
    }

    // Cadence: never question-every-turn. After a question → mirror or reflect.
    if (map.lastPlanWasQuestion) {
      if (_softMirrorEligible(map) || map.discoveryDepth >= 2) {
        return DiscoveryPlan(
          act: DiscoveryAct.sleepMindMirror,
          map: map.copyWith(lastPlanWasQuestion: false),
          ledger: mergedLedger,
          stopDiscovery: true,
          reason: 'cadence_mirror_after_question',
        );
      }
      return DiscoveryPlan(
        act: DiscoveryAct.deferToArc,
        map: map.copyWith(
          lastPlanWasQuestion: false,
          discoveryDepth: map.discoveryDepth + 1,
        ),
        ledger: mergedLedger,
        reason: 'cadence_reflect_after_question',
      );
    }

    final missing = _missingForPattern(map)
        .where(mergedLedger.mayAsk)
        .toList(growable: false);
    if (missing.isEmpty) {
      if (map.leadingPattern != NightPatternId.unknown &&
          map.mapConfidence >= 0.5) {
        return DiscoveryPlan(
          act: DiscoveryAct.sleepMindMirror,
          map: map.copyWith(lastPlanWasQuestion: false),
          ledger: mergedLedger,
          stopDiscovery: true,
          reason: 'dimensions_exhausted',
        );
      }
      return DiscoveryPlan(
        act: DiscoveryAct.deferToArc,
        map: map.copyWith(lastPlanWasQuestion: false),
        ledger: mergedLedger,
        reason: 'nothing_to_ask_defer',
      );
    }

    final dimension = _pickHighestGain(map, missing);
    final act = _actForDimension(map, dimension);
    final objective = DiscoveryObjective(
      dimension: dimension,
      act: act,
      intentSummary: _intentFor(dimension, map),
      forbiddenDimensions: mergedLedger.resolved.toList(growable: false),
      discriminateA: map.hypotheses.isNotEmpty
          ? map.hypotheses.first.pattern.name
          : null,
      discriminateB: map.hypotheses.length > 1
          ? map.hypotheses[1].pattern.name
          : null,
      leadingPattern: map.leadingPattern,
    );

    return DiscoveryPlan(
      act: act,
      objective: objective,
      map: map.copyWith(
        askedDimensions: {...map.askedDimensions, dimension},
        discoveryDepth: map.discoveryDepth + 1,
        lastPlanWasQuestion: true,
      ),
      ledger: mergedLedger.markAsked(dimension),
      reason: 'ig:$dimension',
    );
  }

  bool _shouldMirror(NightMindMap map) {
    if (map.hypothesisReopenRequired) return false;
    if (map.leadingPattern == NightPatternId.unknown) return false;
    if (!_patternMirrorReady(map)) return false;
    // Evidence-rich nights may Mirror slightly under the hard confidence bar
    // when the pattern dimensions are already resolved (C03-class).
    final evidenceRich = map.resolvedDimensions.length >= 3 &&
        map.mapConfidence >= 0.55;
    if (map.mapConfidence < minMirrorConfidence && !evidenceRich) {
      return false;
    }
    if (map.hypotheses.length >= 2) {
      final gap = map.hypotheses.first.confidence - map.hypotheses[1].confidence;
      if (gap < minGapToSecond && !evidenceRich) return false;
    }
    return true;
  }

  /// Softer mirror gate for recognition escape / cadence (not first-turn).
  bool _softMirrorEligible(NightMindMap map) {
    if (map.hypothesisReopenRequired) return false;
    if (map.leadingPattern == NightPatternId.unknown) return false;
    if (map.mapConfidence < 0.5) return false;
    return _patternMirrorReady(map) || map.resolvedDimensions.length >= 2;
  }

  bool _patternMirrorReady(NightMindMap map) {
    switch (map.leadingPattern) {
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
        return map.resolvedDimensions.contains(
              DiscoveryDimension.perceivedUtility,
            ) &&
            (map.resolvedDimensions.contains(DiscoveryDimension.actualEffect) ||
                map.resolvedDimensions.contains(DiscoveryDimension.loopStructure) ||
                map.resolvedDimensions.contains(DiscoveryDimension.thoughtForm));
      case NightPatternId.certaintyChase:
        return map.resolvedDimensions
            .contains(DiscoveryDimension.perceivedUtility);
      case NightPatternId.earlyTomorrowCarry:
        // "Tomorrow" alone is not enough — need mind-form or utility/effect.
        return map.resolvedDimensions
                .contains(DiscoveryDimension.temporalOrientation) &&
            (map.resolvedDimensions.contains(DiscoveryDimension.thoughtForm) ||
                map.resolvedDimensions
                    .contains(DiscoveryDimension.perceivedUtility) ||
                map.resolvedDimensions
                    .contains(DiscoveryDimension.actualEffect));
      case NightPatternId.lonelinessPresence:
        return map.resolvedDimensions
                .contains(DiscoveryDimension.emotionalDriver) ||
            map.resolvedDimensions
                .contains(DiscoveryDimension.unresolvedNeed);
      case NightPatternId.bodyAlarm:
        // Acute caution is routed to safety hold, never Mirror-ready.
        if (map.acuteSomaticCaution || map.arousalType == 'somatic_acute') {
          return false;
        }
        return map.arousalType == 'somatic' ||
            map.resolvedDimensions.contains(DiscoveryDimension.arousalType);
      case NightPatternId.relationalReplay:
        return map.resolvedDimensions
                .contains(DiscoveryDimension.thoughtForm) ||
            map.resolvedDimensions
                .contains(DiscoveryDimension.emotionalDriver) ||
            map.topicDomain == 'relationship';
      case NightPatternId.protectiveHolding:
        return map.resolvedDimensions
                .contains(DiscoveryDimension.perceivedUtility) ||
            map.resolvedDimensions
                .contains(DiscoveryDimension.unresolvedNeed);
      case NightPatternId.unfinishedLoop:
        return map.resolvedDimensions
                .contains(DiscoveryDimension.unresolvedNeed) ||
            map.resolvedDimensions.contains(DiscoveryDimension.thoughtForm);
      case NightPatternId.decisionPendulum:
        return map.resolvedDimensions.contains(DiscoveryDimension.thoughtForm);
      case NightPatternId.unknown:
        return false;
    }
  }

  List<DiscoveryDimension> _missingForPattern(NightMindMap map) {
    final order = _gainOrderFor(map.leadingPattern);
    return [
      for (final d in order)
        if (!map.resolvedDimensions.contains(d)) d,
    ];
  }

  List<DiscoveryDimension> _gainOrderFor(NightPatternId pattern) {
    switch (pattern) {
      case NightPatternId.lonelinessPresence:
        return const [
          DiscoveryDimension.unresolvedNeed,
          DiscoveryDimension.emotionalDriver,
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.temporalOrientation,
        ];
      case NightPatternId.bodyAlarm:
        return const [
          DiscoveryDimension.arousalType,
          DiscoveryDimension.emotionalDriver,
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.unresolvedNeed,
        ];
      case NightPatternId.relationalReplay:
        return const [
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.emotionalDriver,
          DiscoveryDimension.unresolvedNeed,
          DiscoveryDimension.temporalOrientation,
        ];
      case NightPatternId.worstCaseRehearsal:
      case NightPatternId.preparationRehearsal:
        return const [
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.actualEffect,
          DiscoveryDimension.loopStructure,
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.thinkingFunction,
          DiscoveryDimension.temporalOrientation,
        ];
      case NightPatternId.certaintyChase:
        return const [
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.thinkingFunction,
          DiscoveryDimension.actualEffect,
          DiscoveryDimension.thoughtForm,
        ];
      case NightPatternId.earlyTomorrowCarry:
        return const [
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.actualEffect,
          DiscoveryDimension.temporalOrientation,
        ];
      case NightPatternId.protectiveHolding:
        return const [
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.unresolvedNeed,
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.actualEffect,
        ];
      case NightPatternId.unfinishedLoop:
        return const [
          DiscoveryDimension.unresolvedNeed,
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.loopStructure,
          DiscoveryDimension.emotionalDriver,
        ];
      case NightPatternId.decisionPendulum:
        return const [
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.unresolvedNeed,
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.emotionalDriver,
        ];
      case NightPatternId.unknown:
        return const [
          DiscoveryDimension.thoughtForm,
          DiscoveryDimension.emotionalDriver,
          DiscoveryDimension.temporalOrientation,
          DiscoveryDimension.perceivedUtility,
          DiscoveryDimension.actualEffect,
        ];
    }
  }

  DiscoveryDimension _pickHighestGain(
    NightMindMap map,
    List<DiscoveryDimension> missing,
  ) {
    final gainOrder = _gainOrderFor(map.leadingPattern);
    for (final d in gainOrder) {
      if (missing.contains(d)) return d;
    }
    return missing.first;
  }

  DiscoveryAct _actForDimension(NightMindMap map, DiscoveryDimension d) {
    if (map.hypotheses.length >= 2 &&
        (d == DiscoveryDimension.thinkingFunction ||
            d == DiscoveryDimension.thoughtForm)) {
      final gap =
          map.hypotheses.first.confidence - map.hypotheses[1].confidence;
      if (gap < 0.2) return DiscoveryAct.discriminatingQuestion;
    }
    switch (d) {
      case DiscoveryDimension.actualEffect:
      case DiscoveryDimension.loopStructure:
        return DiscoveryAct.deepeningQuestion;
      case DiscoveryDimension.perceivedUtility:
        return map.thinkingFunction != null
            ? DiscoveryAct.confirmationQuestion
            : DiscoveryAct.deepeningQuestion;
      case DiscoveryDimension.temporalOrientation:
      case DiscoveryDimension.topicDomain:
        return DiscoveryAct.clarifyingQuestion;
      default:
        return DiscoveryAct.clarifyingQuestion;
    }
  }

  String _intentFor(DiscoveryDimension d, NightMindMap map) {
    switch (d) {
      case DiscoveryDimension.actualEffect:
        return 'Test whether preparation/checking closes the loop or '
            'creates another scenario to check.';
      case DiscoveryDimension.perceivedUtility:
        return 'Discover what the person believes this thinking gives them, '
            'using their words.';
      case DiscoveryDimension.thinkingFunction:
        return 'Discriminate the soft job of tonight\'s thinking '
            '(prepare / certainty / hold / carry).';
      case DiscoveryDimension.thoughtForm:
        return 'Clarify whether thought is one concern or multiplying scenarios.';
      case DiscoveryDimension.temporalOrientation:
        return 'Clarify whether the load is past, present, or tomorrow-facing.';
      case DiscoveryDimension.loopStructure:
        return 'Make the repeating structure explicit without diagnosis.';
      case DiscoveryDimension.emotionalDriver:
        return 'Name the felt tone in their words without clinical labels.';
      case DiscoveryDimension.unresolvedNeed:
        return 'Discover what feels missing or unfinished tonight, in their words.';
      case DiscoveryDimension.arousalType:
        return 'Clarify whether tonight is mostly body activation or mind looping.';
      default:
        return 'Resolve missing dimension ${d.name} with user language.';
    }
  }
}
