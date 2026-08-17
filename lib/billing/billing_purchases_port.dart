import 'package:purchases_flutter/purchases_flutter.dart';

/// Narrow store/Purchases surface used by [BillingService].
///
/// Keeps RevenueCat SDK calls out of unit tests. Production uses
/// [RevenueCatPurchasesClient]. Does not belong to HCOS.
abstract class BillingPurchasesPort {
  Future<Offerings> getOfferings();

  Future<CustomerInfo> getCustomerInfo();

  Future<CustomerInfo> purchasePackage(Package package);

  Future<CustomerInfo> restorePurchases();
}
