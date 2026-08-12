import 'billing_service.dart';

/// Maps [BillingService] entitlement ownership to concrete product value.
///
/// V1 duration contract (live path only):
/// - Free: [freeSessionLength] matched to [freeSleepBedAsset] (~30m runtime)
/// - Premium: [premiumSessionLength] matched to [premiumSleepBedAsset] (~45m)
///
/// Player timer, player copy, and entitlement resolution all read these values.
/// Does not own purchase/restore (see [BillingService]).
/// Does not belong to HCOS or Conversation.
class PremiumProductAccess {
  final bool isPremium;

  const PremiumProductAccess({required this.isPremium});

  /// Free night: matches shipped [freeSleepBedAsset] (~30 minutes).
  static const Duration freeSessionLength = Duration(minutes: 30);

  /// Premium night: matches shipped [premiumSleepBedAsset] (~45 minutes).
  static const Duration premiumSessionLength = Duration(minutes: 45);

  static const String freeSleepBedAsset =
      'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_30m.m4a';

  static const String premiumSleepBedAsset =
      'assets/audio/bg/CoreDefaultAir/CoreDefaultAir_BG_45m_premium.m4a';

  Duration get sessionLength =>
      isPremium ? premiumSessionLength : freeSessionLength;

  String get sleepBedAsset =>
      isPremium ? premiumSleepBedAsset : freeSleepBedAsset;

  /// Resolve current access from live RevenueCat entitlement state.
  static Future<PremiumProductAccess> resolve({
    BillingService? billing,
  }) async {
    final service = billing ?? BillingService.instance;
    final premium = await service.hasPremiumEntitlement();
    return PremiumProductAccess(isPremium: premium);
  }
}
