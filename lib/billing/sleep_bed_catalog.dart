import '../billing/premium_product_access.dart';

/// Sleep-bed catalog: night blocker → shipped BG asset.
///
/// Presentation/audio layer only. Does not belong to HCOS.
/// Live beds must match the entitlement timer (free 30m / premium 45m).
/// GlobalSleep (~5m) remains shipped but is not a live V1 bed.
class SleepBedCatalog {
  const SleepBedCatalog();

  /// Resolve asset for [blocker] under current [access].
  ///
  /// Every live blocker uses the duration-matched entitlement bed so the
  /// player timer and file length stay aligned.
  String assetFor({
    required String blocker,
    required PremiumProductAccess access,
  }) {
    switch (blocker) {
      case 'loneliness':
      case 'relationship':
      case 'stress':
      case 'mind':
      default:
        return access.sleepBedAsset;
    }
  }

  /// Soft energy label for player presentation.
  String energyFor(String blocker) {
    switch (blocker) {
      case 'loneliness':
      case 'relationship':
        return 'low';
      case 'stress':
        return 'medium';
      case 'mind':
      default:
        return 'medium';
    }
  }

  /// Soft latency label for player presentation.
  String sleepLatencyFor(String blocker) {
    switch (blocker) {
      case 'stress':
      case 'mind':
        return 'long';
      case 'loneliness':
      case 'relationship':
        return 'medium';
      default:
        return 'medium';
    }
  }

  static const String globalSleepBed =
      'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_GlobalSleep.m4a';

  /// Shipped ~5m stem. Not used as a live V1 bed (timer is 30/45).
  static const String globalSleepPremiumBed =
      'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_GlobalSleep.m4a';
}
