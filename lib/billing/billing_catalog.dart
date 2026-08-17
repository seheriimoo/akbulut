import 'package:purchases_flutter/purchases_flutter.dart';

/// Canonical RevenueCat / App Store catalog identifiers for Nocta V1.
///
/// These IDs must match App Store Connect products and the RevenueCat
/// dashboard exactly. The paywall only surfaces packages whose store
/// product IDs are listed here.
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

  /// Product ids expected in the current offering.
  ///
  /// Yearly is first so the paywall default/recommended plan is yearly.
  /// Monthly remains available as the alternative.
  ///
  /// A 7-day free trial is a store introductory offer on yearly only.
  /// App code must not simulate trial entitlement.
  static const List<String> premiumProductIds = [
    yearlyProductId,
    monthlyProductId,
  ];

  /// App Store bundle id this catalog is authored against.
  static const String iosBundleId = 'com.seher.slowave';

  /// Keep only catalog product IDs, in [premiumProductIds] order.
  static List<Package> selectCatalogPackages(Iterable<Package> packages) {
    final byProductId = <String, Package>{};
    for (final package in packages) {
      byProductId[package.storeProduct.identifier] = package;
    }
    return [
      for (final id in premiumProductIds)
        if (byProductId.containsKey(id)) byProductId[id]!,
    ];
  }

  static bool isCatalogProductId(String storeProductId) =>
      premiumProductIds.contains(storeProductId);

  static bool isYearlyProduct(String storeProductId) =>
      storeProductId == yearlyProductId;

  /// Yearly is the recommended default. Falls back to the first catalog package.
  static Package? preferredPackage(List<Package> packages) {
    for (final package in packages) {
      if (isYearlyProduct(package.storeProduct.identifier) ||
          package.packageType == PackageType.annual) {
        return package;
      }
    }
    return packages.isEmpty ? null : packages.first;
  }
}
