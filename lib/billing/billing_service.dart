import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'billing_catalog.dart';
import 'billing_purchases_port.dart';
import 'revenue_cat_purchases_client.dart';
import '../config/app_config.dart';

/// RevenueCat billing for Nocta V1.
///
/// Owns offerings load, purchase, restore, and entitlement checks.
/// Does not own HCOS cognition or Conversation.
class BillingService {
  BillingService._({
    BillingPurchasesPort? purchases,
    bool? configuredOverride,
  })  : _purchases = purchases ?? const RevenueCatPurchasesClient(),
        _configuredOverride = configuredOverride;

  static BillingService instance = BillingService._();

  /// Test seam: inject a fake Purchases port and/or configured flag.
  @visibleForTesting
  static BillingService forTesting({
    required BillingPurchasesPort purchases,
    required bool configured,
  }) {
    return BillingService._(
      purchases: purchases,
      configuredOverride: configured,
    );
  }

  /// Must match the active entitlement identifier in RevenueCat.
  /// See [BillingCatalog.premiumEntitlementId].
  static const String premiumEntitlementId =
      BillingCatalog.premiumEntitlementId;

  final BillingPurchasesPort _purchases;
  final bool? _configuredOverride;

  bool get isConfigured =>
      _configuredOverride ?? AppConfig.hasRevenueCatApiKey;

  /// Live current offering from RevenueCat (null if none / unconfigured).
  ///
  /// Prefers [BillingCatalog.offeringId] when present; otherwise falls back to
  /// RevenueCat's current offering so a correctly marked Current offering still
  /// works during dashboard setup.
  Future<Offering?> loadCurrentOffering() async {
    if (!isConfigured) return null;
    final offerings = await _purchases.getOfferings();
    final named = offerings.getOffering(BillingCatalog.offeringId);
    if (named != null) return named;
    return offerings.current;
  }

  /// Packages on the current offering that match catalog product IDs.
  ///
  /// Order follows [BillingCatalog.premiumProductIds]
  /// (yearly first, then monthly). Unknown store products are dropped.
  Future<List<Package>> loadPackages() async {
    final offering = await loadCurrentOffering();
    if (offering == null) return const [];
    return BillingCatalog.selectCatalogPackages(offering.availablePackages);
  }

  Future<CustomerInfo> getCustomerInfo() {
    return _purchases.getCustomerInfo();
  }

  /// Entitlement ownership: Premium is active only via RevenueCat entitlements.
  Future<bool> hasPremiumEntitlement() async {
    if (!isConfigured) return false;
    final info = await getCustomerInfo();
    return customerHasPremium(info);
  }

  /// Purchase one store package. Returns updated customer info.
  ///
  /// Throws [BillingException] on failure. User cancel is [BillingException.cancelled].
  Future<CustomerInfo> purchasePackage(Package package) async {
    if (!isConfigured) {
      throw const BillingException(
        code: BillingErrorCode.notConfigured,
        message: 'Billing is not configured',
      );
    }

    try {
      return await _purchases.purchasePackage(package);
    } on PlatformException catch (error) {
      throw BillingException.fromPlatform(error);
    }
  }

  /// Restore previous purchases and refresh entitlements.
  Future<CustomerInfo> restorePurchases() async {
    if (!isConfigured) {
      throw const BillingException(
        code: BillingErrorCode.notConfigured,
        message: 'Billing is not configured',
      );
    }

    try {
      return await _purchases.restorePurchases();
    } on PlatformException catch (error) {
      throw BillingException.fromPlatform(error);
    }
  }

  bool customerHasPremium(CustomerInfo info) {
    return info.entitlements.active.containsKey(premiumEntitlementId);
  }
}

enum BillingErrorCode {
  notConfigured,
  cancelled,
  storeProblem,
  unknown,
}

class BillingException implements Exception {
  final BillingErrorCode code;
  final String message;

  const BillingException({
    required this.code,
    required this.message,
  });

  factory BillingException.fromPlatform(PlatformException error) {
    final purchasesCode = PurchasesErrorHelper.getErrorCode(error);
    if (purchasesCode == PurchasesErrorCode.purchaseCancelledError) {
      return const BillingException(
        code: BillingErrorCode.cancelled,
        message: 'Purchase cancelled',
      );
    }

    return BillingException(
      code: BillingErrorCode.storeProblem,
      message: error.message ?? 'Store purchase failed',
    );
  }

  @override
  String toString() => 'BillingException(${code.name}): $message';
}
