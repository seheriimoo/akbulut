import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/billing/billing_catalog.dart';
import 'package:slowave/billing/billing_service.dart';
import 'package:slowave/config/app_config.dart';

void main() {
  group('Billing catalog readiness', () {
    test('exposes stable entitlement, offering, and product ids', () {
      expect(BillingCatalog.premiumEntitlementId, 'nocta_premium');
      expect(BillingCatalog.offeringId, 'default');
      expect(BillingCatalog.monthlyProductId, 'nocta_premium_monthly');
      expect(BillingCatalog.yearlyProductId, 'nocta_premium_yearly');
      expect(BillingCatalog.iosBundleId, 'com.seher.slowave');
      expect(
        BillingCatalog.premiumProductIds,
        containsAll([
          BillingCatalog.monthlyProductId,
          BillingCatalog.yearlyProductId,
        ]),
      );
    });

    test('BillingService entitlement matches catalog', () {
      expect(
        BillingService.premiumEntitlementId,
        BillingCatalog.premiumEntitlementId,
      );
    });
  });

  group('AppConfig secret usability', () {
    test('rejects placeholder stubs and empty values', () {
      expect(AppConfig.isUsableSecret(''), isFalse);
      expect(
        AppConfig.isUsableSecret('REPLACE_WITH_REVENUECAT_APPLE_API_KEY'),
        isFalse,
      );
      expect(AppConfig.isUsableSecret('appl_live_example_key'), isTrue);
    });
  });
}
