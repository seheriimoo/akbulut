import 'discovery_act.dart';
import 'discovery_dimension.dart';
import 'night_pattern_id.dart';

/// WHAT to learn this turn — never a fixed user-facing question string.
class DiscoveryObjective {
  final DiscoveryDimension dimension;

  final DiscoveryAct act;

  /// Short planner note for shaping (not authority).
  final String intentSummary;

  /// Dimensions already resolved — realization must not re-ask these.
  final List<DiscoveryDimension> forbiddenDimensions;

  /// Optional discrimination poles (hypothesis A vs B labels, internal).
  final String? discriminateA;

  final String? discriminateB;

  /// Leading pattern hint for shaping only.
  final NightPatternId? leadingPattern;

  const DiscoveryObjective({
    required this.dimension,
    required this.act,
    required this.intentSummary,
    this.forbiddenDimensions = const [],
    this.discriminateA,
    this.discriminateB,
    this.leadingPattern,
  });
}
