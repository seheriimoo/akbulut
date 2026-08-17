import 'package:purchases_flutter/purchases_flutter.dart';

import 'billing_purchases_port.dart';

/// Production [BillingPurchasesPort] backed by purchases_flutter.
class RevenueCatPurchasesClient implements BillingPurchasesPort {
  const RevenueCatPurchasesClient();

  @override
  Future<Offerings> getOfferings() => Purchases.getOfferings();

  @override
  Future<CustomerInfo> getCustomerInfo() => Purchases.getCustomerInfo();

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return result.customerInfo;
  }

  @override
  Future<CustomerInfo> restorePurchases() => Purchases.restorePurchases();
}
