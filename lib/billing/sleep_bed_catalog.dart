import '../billing/premium_product_access.dart';

/// Sleep-bed catalog: night blocker → shipped BG asset.
///
/// Presentation/audio layer only. Does not belong to HCOS.
/// Entitlement still gates free vs premium duration where applicable.
class SleepBedCatalog {
  const SleepBedCatalog();

  /// Resolve asset for [blocker] under current [access].
  ///
  /// - mind / default → CoreDefaultAir entitlement bed
  /// - loneliness / relationship → GlobalSleep bed (softer hold)
  /// - stress → longer quiet bed when premium, else free bed
  String assetFor({
    required String blocker,
    required PremiumProductAccess access,
  }) {
    switch (blocker) {
      case 'loneliness':
      case 'relationship':
        return access.isPremium
            ? SleepBedCatalog.globalSleepPremiumBed
            : SleepBedCatalog.globalSleepBed;
      case 'stress':
        return access.isPremium
            ? PremiumProductAccess.premiumSleepBedAsset
            : PremiumProductAccess.freeSleepBedAsset;
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

  /// Premium loneliness/relationship uses the same GlobalSleep master until
  /// dedicated premium stems ship; length still follows entitlement timer.
  static const String globalSleepPremiumBed =
      'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_GlobalSleep.m4a';
}
