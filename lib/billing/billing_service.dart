import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'billing_catalog.dart';
import '../config/app_config.dart';

/// RevenueCat billing for Nocta V1.
///
/// Owns offerings load, purchase, restore, and entitlement checks.
/// Does not own HCOS cognition or Conversation.
class BillingService {
  BillingService._();

  static final BillingService instance = BillingService._();

  /// Must match the active entitlement identifier in RevenueCat.
  /// See [BillingCatalog.premiumEntitlementId].
  static const String premiumEntitlementId =
      BillingCatalog.premiumEntitlementId;

  bool get isConfigured => AppConfig.hasRevenueCatApiKey;

  /// Live current offering from RevenueCat (null if none / unconfigured).
  ///
  /// Prefers [BillingCatalog.offeringId] when present; otherwise falls back to
  /// RevenueCat's current offering so a correctly marked Current offering still
  /// works during dashboard setup.
  Future<Offering?> loadCurrentOffering() async {
    if (!isConfigured) return null;
    final offerings = await Purchases.getOfferings();
    final named = offerings.getOffering(BillingCatalog.offeringId);
    if (named != null) return named;
    return offerings.current;
  }

  /// Packages available on the current offering, store order preserved.
  Future<List<Package>> loadPackages() async {
    final offering = await loadCurrentOffering();
    if (offering == null) return const [];
    return List<Package>.unmodifiable(offering.availablePackages);
  }

  Future<CustomerInfo> getCustomerInfo() {
    return Purchases.getCustomerInfo();
  }

  /// Entitlement ownership: Premium is active only via RevenueCat entitlements.
  Future<bool> hasPremiumEntitlement() async {
    if (!isConfigured) return false;
    final info = await getCustomerInfo();
    return _entitlementActive(info);
  }

  bool _entitlementActive(CustomerInfo info) {
    return info.entitlements.active.containsKey(premiumEntitlementId);
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
      final result = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      return result.customerInfo;
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
      return await Purchases.restorePurchases();
    } on PlatformException catch (error) {
      throw BillingException.fromPlatform(error);
    }
  }

  bool customerHasPremium(CustomerInfo info) => _entitlementActive(info);
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
