import 'discovery_dimension.dart';

/// Prevents semantic re-ask of dimensions already explored this night.
///
/// Once asked OR resolved, the dimension must not be asked again
/// (extract-first: answers update resolved; asked alone still blocks re-ask).
class SemanticDimensionLedger {
  final Set<DiscoveryDimension> asked;
  final Set<DiscoveryDimension> resolved;
  final Set<DiscoveryDimension> blockedReask;

  const SemanticDimensionLedger({
    this.asked = const {},
    this.resolved = const {},
    this.blockedReask = const {},
  });

  static const empty = SemanticDimensionLedger();

  bool mayAsk(DiscoveryDimension dimension) {
    if (resolved.contains(dimension)) return false;
    if (asked.contains(dimension)) return false;
    if (blockedReask.contains(dimension)) return false;
    return true;
  }

  SemanticDimensionLedger markAsked(DiscoveryDimension dimension) {
    return SemanticDimensionLedger(
      asked: {...asked, dimension},
      resolved: resolved,
      blockedReask: {...blockedReask, dimension},
    );
  }

  SemanticDimensionLedger markResolved(DiscoveryDimension dimension) {
    return SemanticDimensionLedger(
      asked: {...asked, dimension},
      resolved: {...resolved, dimension},
      blockedReask: {...blockedReask, dimension},
    );
  }

  SemanticDimensionLedger mergeFromMap({
    required Set<DiscoveryDimension> mapAsked,
    required Set<DiscoveryDimension> mapResolved,
  }) {
    return SemanticDimensionLedger(
      asked: {...asked, ...mapAsked},
      resolved: {...resolved, ...mapResolved},
      blockedReask: {
        ...blockedReask,
        ...mapAsked,
        ...mapResolved,
      },
    );
  }
}
