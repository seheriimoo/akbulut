/// Canonical RevenueCat / App Store catalog identifiers for Nocta V1.
///
/// These IDs must match App Store Connect products and the RevenueCat
/// dashboard exactly. The paywall loads whatever packages are attached to
/// [offeringId]; it does not invent products.
///
/// Does not belong to HCOS or Conversation.
class BillingCatalog {
  const BillingCatalog._();

  /// RevenueCat entitlement unlocked by any premium package.
  static const String premiumEntitlementId = 'nocta_premium';

  /// RevenueCat current offering identifier (must be marked Current in RC).
  static const String offeringId = 'default';

  /// App Store Connect product id — monthly auto-renewable subscription.
  static const String monthlyProductId = 'nocta_premium_monthly';

  /// App Store Connect product id — yearly auto-renewable subscription.
  static const String yearlyProductId = 'nocta_premium_yearly';

  /// Product ids expected in the current offering (order is display preference).
  static const List<String> premiumProductIds = [
    monthlyProductId,
    yearlyProductId,
  ];

  /// App Store bundle id this catalog is authored against.
  static const String iosBundleId = 'com.seher.slowave';
}
