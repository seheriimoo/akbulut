import '../thinking_function_hypothesis.dart';
import '../thinking_function_kind.dart';
import 'discovery_dimension.dart';
import 'night_pattern_id.dart';

/// Soft competing hypothesis for tonight (never user-facing).
class DiscoveryHypothesis {
  final NightPatternId pattern;

  final ThinkingFunctionKind? function;

  final double confidence;

  final List<String> evidenceIds;

  const DiscoveryHypothesis({
    required this.pattern,
    required this.confidence,
    this.function,
    this.evidenceIds = const [],
  });

  DiscoveryHypothesis copyWith({
    NightPatternId? pattern,
    ThinkingFunctionKind? function,
    double? confidence,
    List<String>? evidenceIds,
  }) {
    return DiscoveryHypothesis(
      pattern: pattern ?? this.pattern,
      function: function ?? this.function,
      confidence: confidence ?? this.confidence,
      evidenceIds: evidenceIds ?? this.evidenceIds,
    );
  }
}

/// Night-scoped structured cognitive map for Adaptive Discovery.
///
/// Orchestrator-owned for the night. Not durable memory.
class NightMindMap {
  final String? topicDomain;
  final String? temporalOrientation;
  final String? thoughtForm;
  final ThinkingFunctionKind? thinkingFunction;
  final String? perceivedUtility;
  final String? actualEffect;
  final String? loopStructure;
  final String? emotionalDriver;
  final String? arousalType;
  final String? unresolvedNeed;

  final NightPatternId leadingPattern;
  final List<DiscoveryHypothesis> hypotheses;

  final Set<DiscoveryDimension> askedDimensions;
  final Set<DiscoveryDimension> resolvedDimensions;
  final List<String> contradictions;
  final List<String> evidenceIds;

  final int discoveryDepth;
  final bool mirrorEmitted;
  final double mapConfidence;

  /// First-turn meet (Receipt/Observe) already granted this night.
  final bool meetCompleted;

  /// Previous discovery plan was a question act (cadence brake).
  final bool lastPlanWasQuestion;

  /// How many recognition-hold turns since Recognition surfaced.
  final int recognitionHoldCount;

  /// Acute heart/breath-style phrases — safety hold, not sleep Mirror.
  final bool acuteSomaticCaution;

  /// Explicit user correction invalidated a prior inference — Mirror blocked
  /// until a fresh discriminating turn lands.
  final bool hypothesisReopenRequired;

  const NightMindMap({
    this.topicDomain,
    this.temporalOrientation,
    this.thoughtForm,
    this.thinkingFunction,
    this.perceivedUtility,
    this.actualEffect,
    this.loopStructure,
    this.emotionalDriver,
    this.arousalType,
    this.unresolvedNeed,
    this.leadingPattern = NightPatternId.unknown,
    this.hypotheses = const [],
    this.askedDimensions = const {},
    this.resolvedDimensions = const {},
    this.contradictions = const [],
    this.evidenceIds = const [],
    this.discoveryDepth = 0,
    this.mirrorEmitted = false,
    this.mapConfidence = 0,
    this.meetCompleted = false,
    this.lastPlanWasQuestion = false,
    this.recognitionHoldCount = 0,
    this.acuteSomaticCaution = false,
    this.hypothesisReopenRequired = false,
  });

  static const empty = NightMindMap();

  bool get isEmpty =>
      topicDomain == null &&
      temporalOrientation == null &&
      thoughtForm == null &&
      thinkingFunction == null &&
      hypotheses.isEmpty &&
      evidenceIds.isEmpty;

  List<DiscoveryDimension> get missingHighValue {
    const priority = [
      DiscoveryDimension.temporalOrientation,
      DiscoveryDimension.thoughtForm,
      DiscoveryDimension.thinkingFunction,
      DiscoveryDimension.perceivedUtility,
      DiscoveryDimension.actualEffect,
      DiscoveryDimension.loopStructure,
    ];
    return [
      for (final d in priority)
        if (!resolvedDimensions.contains(d)) d,
    ];
  }

  NightMindMap copyWith({
    String? topicDomain,
    String? temporalOrientation,
    String? thoughtForm,
    ThinkingFunctionKind? thinkingFunction,
    String? perceivedUtility,
    String? actualEffect,
    String? loopStructure,
    String? emotionalDriver,
    String? arousalType,
    String? unresolvedNeed,
    NightPatternId? leadingPattern,
    List<DiscoveryHypothesis>? hypotheses,
    Set<DiscoveryDimension>? askedDimensions,
    Set<DiscoveryDimension>? resolvedDimensions,
    List<String>? contradictions,
    List<String>? evidenceIds,
    int? discoveryDepth,
    bool? mirrorEmitted,
    double? mapConfidence,
    bool? meetCompleted,
    bool? lastPlanWasQuestion,
    int? recognitionHoldCount,
    bool? acuteSomaticCaution,
    bool? hypothesisReopenRequired,
    bool clearPerceivedUtility = false,
    bool clearThinkingFunction = false,
    bool clearLoopStructure = false,
    bool clearEmotionalDriver = false,
    bool clearUnresolvedNeed = false,
    bool clearHypothesisReopen = false,
  }) {
    return NightMindMap(
      topicDomain: topicDomain ?? this.topicDomain,
      temporalOrientation: temporalOrientation ?? this.temporalOrientation,
      thoughtForm: thoughtForm ?? this.thoughtForm,
      thinkingFunction: clearThinkingFunction
          ? null
          : (thinkingFunction ?? this.thinkingFunction),
      perceivedUtility: clearPerceivedUtility
          ? null
          : (perceivedUtility ?? this.perceivedUtility),
      actualEffect: actualEffect ?? this.actualEffect,
      loopStructure:
          clearLoopStructure ? null : (loopStructure ?? this.loopStructure),
      emotionalDriver: clearEmotionalDriver
          ? null
          : (emotionalDriver ?? this.emotionalDriver),
      arousalType: arousalType ?? this.arousalType,
      unresolvedNeed: clearUnresolvedNeed
          ? null
          : (unresolvedNeed ?? this.unresolvedNeed),
      leadingPattern: leadingPattern ?? this.leadingPattern,
      hypotheses: hypotheses ?? this.hypotheses,
      askedDimensions: askedDimensions ?? this.askedDimensions,
      resolvedDimensions: resolvedDimensions ?? this.resolvedDimensions,
      contradictions: contradictions ?? this.contradictions,
      evidenceIds: evidenceIds ?? this.evidenceIds,
      discoveryDepth: discoveryDepth ?? this.discoveryDepth,
      mirrorEmitted: mirrorEmitted ?? this.mirrorEmitted,
      mapConfidence: mapConfidence ?? this.mapConfidence,
      meetCompleted: meetCompleted ?? this.meetCompleted,
      lastPlanWasQuestion: lastPlanWasQuestion ?? this.lastPlanWasQuestion,
      recognitionHoldCount: recognitionHoldCount ?? this.recognitionHoldCount,
      acuteSomaticCaution:
          acuteSomaticCaution ?? this.acuteSomaticCaution,
      hypothesisReopenRequired: clearHypothesisReopen
          ? false
          : (hypothesisReopenRequired ?? this.hypothesisReopenRequired),
    );
  }

  /// Seed / refresh function from existing TF continuity (no duplicate ontology).
  NightMindMap withThinkingFunction(ThinkingFunctionHypothesis? hyp) {
    if (hyp == null) return this;
    final resolved = {
      ...resolvedDimensions,
      if (hyp.confidence >= 0.65) DiscoveryDimension.thinkingFunction,
    };
    return copyWith(
      thinkingFunction: hyp.kind,
      resolvedDimensions: resolved,
      evidenceIds: [
        ...evidenceIds,
        ...hyp.evidenceIds.map((e) => 'tf:$e'),
      ],
    );
  }
}
