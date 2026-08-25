import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:slowave/billing/billing_catalog.dart';
import 'package:slowave/billing/billing_purchases_port.dart';
import 'package:slowave/billing/billing_service.dart';

CustomerInfo _customerInfo({required bool premium}) {
  final entitlement = EntitlementInfo(
    BillingCatalog.premiumEntitlementId,
    true,
    true,
    '2026-01-01T00:00:00Z',
    '2026-01-01T00:00:00Z',
    BillingCatalog.yearlyProductId,
    true,
  );
  final active = premium
      ? <String, EntitlementInfo>{
          BillingCatalog.premiumEntitlementId: entitlement,
        }
      : <String, EntitlementInfo>{};
  return CustomerInfo(
    EntitlementInfos(Map<String, EntitlementInfo>.from(active), active),
    const {},
    premium ? [BillingCatalog.yearlyProductId] : const [],
    premium ? [BillingCatalog.yearlyProductId] : const [],
    const [],
    '2026-01-01T00:00:00Z',
    'test-user',
    const {},
    '2026-01-01T00:00:00Z',
  );
}

Package _yearlyPackage() {
  return Package(
    r'$rc_annual',
    PackageType.annual,
    StoreProduct(
      BillingCatalog.yearlyProductId,
      'desc',
      BillingCatalog.yearlyProductId,
      59.99,
      r'$59.99',
      'USD',
    ),
    const PresentedOfferingContext(BillingCatalog.offeringId, null, null),
  );
}

class _PostPurchaseFake implements BillingPurchasesPort {
  _PostPurchaseFake({
    required this.purchaseResult,
    CustomerInfo? initialCustomerInfo,
    this.purchaseError,
    this.getCustomerInfoResults,
  }) : customerInfo = initialCustomerInfo ?? _customerInfo(premium: false);

  final CustomerInfo purchaseResult;
  final Object? purchaseError;
  final List<CustomerInfo>? getCustomerInfoResults;

  CustomerInfo customerInfo;
  int purchaseCalls = 0;
  int getCustomerInfoCalls = 0;

  @override
  Future<CustomerInfo> getCustomerInfo() async {
    getCustomerInfoCalls += 1;
    final scripted = getCustomerInfoResults;
    if (scripted != null && getCustomerInfoCalls <= scripted.length) {
      return scripted[getCustomerInfoCalls - 1];
    }
    return customerInfo;
  }

  @override
  Future<Offerings> getOfferings() {
    throw UnimplementedError();
  }

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    purchaseCalls += 1;
    final error = purchaseError;
    if (error != null) throw error;
    return purchaseResult;
  }

  @override
  Future<CustomerInfo> restorePurchases() {
    throw UnimplementedError();
  }
}

void main() {
  const instantBackoff = [Duration.zero, Duration.zero, Duration.zero];

  group('post-purchase premium resolve', () {
    test('A purchase result already premium → immediate success', () async {
      final fake = _PostPurchaseFake(
        purchaseResult: _customerInfo(premium: true),
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final premium = await billing.resolvePremiumAfterPurchase(
        _customerInfo(premium: true),
      );

      expect(premium, isTrue);
      expect(fake.getCustomerInfoCalls, 0);
    });

    test('B purchase result stale, fresh CustomerInfo becomes premium → success',
        () async {
      final fake = _PostPurchaseFake(
        purchaseResult: _customerInfo(premium: false),
        getCustomerInfoResults: [
          _customerInfo(premium: false),
          _customerInfo(premium: true),
        ],
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final premium = await billing.resolvePremiumAfterPurchase(
        _customerInfo(premium: false),
        backoff: instantBackoff,
      );

      expect(premium, isTrue);
      expect(fake.getCustomerInfoCalls, 2);
      expect(fake.purchaseCalls, 0);
    });

    test('C purchase result stale, refresh remains non-premium → no false unlock',
        () async {
      final fake = _PostPurchaseFake(
        purchaseResult: _customerInfo(premium: false),
        getCustomerInfoResults: [
          _customerInfo(premium: false),
          _customerInfo(premium: false),
          _customerInfo(premium: false),
        ],
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final premium = await billing.resolvePremiumAfterPurchase(
        _customerInfo(premium: false),
        backoff: instantBackoff,
      );

      expect(premium, isFalse);
      expect(fake.purchaseCalls, 0);
    });

    test('D purchase throws/cancels → error surfaces, no refresh unlock', () async {
      final fake = _PostPurchaseFake(
        purchaseResult: _customerInfo(premium: false),
        purchaseError: PlatformException(
          code: '${PurchasesErrorCode.purchaseCancelledError.index}',
          message: 'cancelled',
        ),
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      expect(
        () => billing.purchasePackageWithBoundedWait(_yearlyPackage()),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            BillingErrorCode.cancelled,
          ),
        ),
      );
      expect(fake.purchaseCalls, 1);
      expect(fake.getCustomerInfoCalls, 0);
    });

    test('E resolve retry does not trigger duplicate purchase', () async {
      final fake = _PostPurchaseFake(
        purchaseResult: _customerInfo(premium: false),
        getCustomerInfoResults: [
          _customerInfo(premium: false),
          _customerInfo(premium: true),
        ],
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final info = await billing.purchasePackageWithBoundedWait(_yearlyPackage());
      expect(fake.purchaseCalls, 1);

      final premium = await billing.resolvePremiumAfterPurchase(
        info,
        backoff: instantBackoff,
      );

      expect(premium, isTrue);
      expect(fake.purchaseCalls, 1);
    });
  });
}
