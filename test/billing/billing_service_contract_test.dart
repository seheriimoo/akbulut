import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:slowave/billing/billing_catalog.dart';
import 'package:slowave/billing/billing_purchases_port.dart';
import 'package:slowave/billing/billing_service.dart';
import 'package:slowave/billing/night_access.dart';
import 'package:slowave/billing/premium_product_access.dart';
import 'package:slowave/config/app_config.dart';

CustomerInfo _customerInfo({
  required bool premium,
  String productId = BillingCatalog.monthlyProductId,
  PeriodType periodType = PeriodType.normal,
}) {
  final entitlement = EntitlementInfo(
    BillingCatalog.premiumEntitlementId,
    true,
    true,
    '2026-01-01T00:00:00Z',
    '2026-01-01T00:00:00Z',
    productId,
    true,
    periodType: periodType,
  );
  final active = premium
      ? <String, EntitlementInfo>{
          BillingCatalog.premiumEntitlementId: entitlement,
        }
      : <String, EntitlementInfo>{};
  final all = Map<String, EntitlementInfo>.from(active);
  return CustomerInfo(
    EntitlementInfos(all, active),
    const {},
    premium ? [productId] : const [],
    premium ? [productId] : const [],
    const [],
    '2026-01-01T00:00:00Z',
    'test-user',
    const {},
    '2026-01-01T00:00:00Z',
  );
}

Package _package({
  required String productId,
  required String packageId,
  required PackageType type,
}) {
  return Package(
    packageId,
    type,
    StoreProduct(
      productId,
      'desc',
      productId,
      9.99,
      '\$9.99',
      'USD',
    ),
    const PresentedOfferingContext(BillingCatalog.offeringId, null, null),
  );
}

class _FakePurchases implements BillingPurchasesPort {
  _FakePurchases({
    this.offerings,
    CustomerInfo? customerInfo,
    this.purchaseResult,
    this.purchaseError,
    this.restoreResult,
    this.restoreError,
  }) : customerInfo = customerInfo ?? _customerInfo(premium: false);

  Offerings? offerings;
  CustomerInfo customerInfo;
  CustomerInfo? purchaseResult;
  Object? purchaseError;
  CustomerInfo? restoreResult;
  Object? restoreError;
  int purchaseCalls = 0;
  int restoreCalls = 0;

  @override
  Future<Offerings> getOfferings() async {
    final value = offerings;
    if (value == null) {
      throw StateError('offerings not stubbed');
    }
    return value;
  }

  @override
  Future<CustomerInfo> getCustomerInfo() async => customerInfo;

  @override
  Future<CustomerInfo> purchasePackage(Package package) async {
    purchaseCalls += 1;
    final error = purchaseError;
    if (error != null) {
      throw error;
    }
    final result = purchaseResult ?? _customerInfo(premium: true);
    customerInfo = result;
    return result;
  }

  @override
  Future<CustomerInfo> restorePurchases() async {
    restoreCalls += 1;
    final error = restoreError;
    if (error != null) {
      throw error;
    }
    final result = restoreResult ?? customerInfo;
    customerInfo = result;
    return result;
  }
}

void main() {
  group('AppConfig RevenueCat Apple key', () {
    test('accepts appl_ public SDK key shape', () {
      expect(
        AppConfig.isUsableRevenueCatAppleSdkKey('appl_live_example_key'),
        isTrue,
      );
    });

    test('rejects placeholder, empty, and non-Apple keys', () {
      expect(AppConfig.isUsableRevenueCatAppleSdkKey(''), isFalse);
      expect(
        AppConfig.isUsableRevenueCatAppleSdkKey(
          'REPLACE_WITH_REVENUECAT_APPLE_API_KEY',
        ),
        isFalse,
      );
      expect(
        AppConfig.isUsableRevenueCatAppleSdkKey('goog_android_key'),
        isFalse,
      );
      expect(
        AppConfig.isUsableRevenueCatAppleSdkKey('sk_live_not_rc'),
        isFalse,
      );
    });
  });

  group('BillingCatalog package selection', () {
    test('maps monthly/yearly store products in catalog order', () {
      final yearly = _package(
        productId: BillingCatalog.yearlyProductId,
        packageId: r'$rc_annual',
        type: PackageType.annual,
      );
      final monthly = _package(
        productId: BillingCatalog.monthlyProductId,
        packageId: r'$rc_monthly',
        type: PackageType.monthly,
      );
      final unknown = _package(
        productId: 'other_product',
        packageId: 'custom',
        type: PackageType.custom,
      );

      final selected = BillingCatalog.selectCatalogPackages([
        yearly,
        unknown,
        monthly,
      ]);

      expect(
        selected.map((p) => p.storeProduct.identifier).toList(),
        [
          BillingCatalog.yearlyProductId,
          BillingCatalog.monthlyProductId,
        ],
      );
      expect(
        BillingCatalog.preferredPackage(selected)?.storeProduct.identifier,
        BillingCatalog.yearlyProductId,
      );
    });
  });

  group('BillingService production IAP contract', () {
    late _FakePurchases fake;
    late Package monthly;
    late Package yearly;
    late Offering defaultOffering;

    setUp(() {
      monthly = _package(
        productId: BillingCatalog.monthlyProductId,
        packageId: r'$rc_monthly',
        type: PackageType.monthly,
      );
      yearly = _package(
        productId: BillingCatalog.yearlyProductId,
        packageId: r'$rc_annual',
        type: PackageType.annual,
      );
      defaultOffering = Offering(
        BillingCatalog.offeringId,
        'Nocta default',
        const {},
        [yearly, monthly],
        monthly: monthly,
        annual: yearly,
      );
      fake = _FakePurchases(
        offerings: Offerings(
          {BillingCatalog.offeringId: defaultOffering},
          current: defaultOffering,
        ),
        customerInfo: _customerInfo(premium: false),
      );
    });

    test('missing/unconfigured key fails safely and never unlocks premium',
        () async {
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: false,
      );

      expect(billing.isConfigured, isFalse);
      expect(await billing.hasPremiumEntitlement(), isFalse);
      expect(await billing.loadCurrentOffering(), isNull);
      expect(await billing.loadPackages(), isEmpty);

      await expectLater(
        billing.purchasePackage(monthly),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            BillingErrorCode.notConfigured,
          ),
        ),
      );
      expect(fake.purchaseCalls, 0);
      expect(await billing.hasPremiumEntitlement(), isFalse);
    });

    test('loads offering default and catalog monthly/yearly packages',
        () async {
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final offering = await billing.loadCurrentOffering();
      expect(offering?.identifier, BillingCatalog.offeringId);

      final packages = await billing.loadPackages();
      expect(
        packages.map((p) => p.storeProduct.identifier).toList(),
        [
          BillingCatalog.yearlyProductId,
          BillingCatalog.monthlyProductId,
        ],
      );
    });

    test('prefers named default offering over unrelated current', () async {
      final other = Offering(
        'promo',
        'promo',
        const {},
        [yearly],
        annual: yearly,
      );
      fake.offerings = Offerings(
        {
          BillingCatalog.offeringId: defaultOffering,
          'promo': other,
        },
        current: other,
      );

      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );
      final offering = await billing.loadCurrentOffering();
      expect(offering?.identifier, BillingCatalog.offeringId);
    });

    test('purchase success grants nocta_premium and premium session access',
        () async {
      fake.purchaseResult = _customerInfo(premium: true);
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      expect(await billing.hasPremiumEntitlement(), isFalse);

      final info = await billing.purchasePackage(monthly);
      expect(billing.customerHasPremium(info), isTrue);
      expect(await billing.hasPremiumEntitlement(), isTrue);

      final access = await PremiumProductAccess.resolve(billing: billing);
      expect(access.isPremium, isTrue);
      expect(
        access.sessionLength,
        PremiumProductAccess.premiumSessionLength,
      );
      expect(access.sessionLength, const Duration(minutes: 45));
      expect(
        access.sleepBedAsset,
        PremiumProductAccess.premiumSleepBedAsset,
      );
    });

    test('yearly purchase and yearly trial entitlement both unlock premium',
        () async {
      fake.purchaseResult = _customerInfo(
        premium: true,
        productId: BillingCatalog.yearlyProductId,
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final purchased = await billing.purchasePackage(yearly);
      expect(billing.customerHasPremium(purchased), isTrue);

      final trialInfo = _customerInfo(
        premium: true,
        productId: BillingCatalog.yearlyProductId,
        periodType: PeriodType.intro,
      );
      expect(billing.customerHasPremium(trialInfo), isTrue);
      expect(
        NightAccess.canStartConversation(
          isPremium: true,
          completedNights: 99,
        ),
        isTrue,
      );
    });

    test('purchase cancellation is safe and does not unlock premium',
        () async {
      fake.purchaseError = PlatformException(
        code: '${PurchasesErrorCode.purchaseCancelledError.index}',
        message: 'Purchase was cancelled.',
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      await expectLater(
        billing.purchasePackage(monthly),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            BillingErrorCode.cancelled,
          ),
        ),
      );
      expect(await billing.hasPremiumEntitlement(), isFalse);

      final access = await PremiumProductAccess.resolve(billing: billing);
      expect(access.isPremium, isFalse);
      expect(access.sessionLength, PremiumProductAccess.freeSessionLength);
    });

    test('store/network failure does not unlock premium', () async {
      fake.purchaseError = PlatformException(
        code: '${PurchasesErrorCode.networkError.index}',
        message: 'Network error',
      );
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      await expectLater(
        billing.purchasePackage(yearly),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            BillingErrorCode.storeProblem,
          ),
        ),
      );
      expect(await billing.hasPremiumEntitlement(), isFalse);
    });

    test('restore purchases grants nocta_premium when entitlement active',
        () async {
      fake.restoreResult = _customerInfo(premium: true);
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final info = await billing.restorePurchases();
      expect(billing.customerHasPremium(info), isTrue);
      expect(await billing.hasPremiumEntitlement(), isTrue);
      expect(fake.restoreCalls, 1);
    });

    test('restore with no entitlement keeps free access', () async {
      fake.restoreResult = _customerInfo(premium: false);
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );

      final info = await billing.restorePurchases();
      expect(billing.customerHasPremium(info), isFalse);
      expect(await billing.hasPremiumEntitlement(), isFalse);

      final access = await PremiumProductAccess.resolve(billing: billing);
      expect(access.isPremium, isFalse);
      expect(access.sessionLength, const Duration(minutes: 30));
    });

    test('premium is derived only from nocta_premium entitlement key', () {
      final billing = BillingService.forTesting(
        purchases: fake,
        configured: true,
      );
      final other = CustomerInfo(
        const EntitlementInfos(
          {
            'wrong_entitlement': EntitlementInfo(
              'wrong_entitlement',
              true,
              true,
              '2026-01-01T00:00:00Z',
              '2026-01-01T00:00:00Z',
              BillingCatalog.monthlyProductId,
              true,
            ),
          },
          {
            'wrong_entitlement': EntitlementInfo(
              'wrong_entitlement',
              true,
              true,
              '2026-01-01T00:00:00Z',
              '2026-01-01T00:00:00Z',
              BillingCatalog.monthlyProductId,
              true,
            ),
          },
        ),
        const {},
        const [BillingCatalog.monthlyProductId],
        const [BillingCatalog.monthlyProductId],
        const [],
        '2026-01-01T00:00:00Z',
        'test-user',
        const {},
        '2026-01-01T00:00:00Z',
      );

      expect(billing.customerHasPremium(other), isFalse);
      expect(billing.customerHasPremium(_customerInfo(premium: true)), isTrue);
    });
  });
}
