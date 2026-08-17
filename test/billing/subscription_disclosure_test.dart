import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/billing/subscription_disclosure.dart';
import 'package:slowave/compliance/compliance_texts.dart';

void main() {
  group('Subscription disclosure V1', () {
    test('includes Guideline 3.1.2 auto-renew terms', () {
      expect(
        SubscriptionDisclosure.autoRenewTerms,
        contains('automatically renews'),
      );
      expect(
        SubscriptionDisclosure.autoRenewTerms,
        contains('24 hours'),
      );
      expect(
        SubscriptionDisclosure.autoRenewTerms,
        contains('Apple ID'),
      );
    });

    test('paywall source binds disclosure, legal links, and duration copy', () {
      final paywall =
          File('lib/screens/paywall_screen.dart').readAsStringSync();
      expect(paywall, contains('SubscriptionDisclosure.autoRenewTerms'));
      expect(paywall, contains('LegalDocumentKind.privacyPolicy'));
      expect(paywall, contains('LegalDocumentKind.termsOfService'));
      expect(paywall, contains('Every night your mind is still awake'));
      expect(paywall, contains('Recommended'));
      expect(paywall, contains('BillingCatalog.preferredPackage'));
      expect(paywall, isNot(contains('Continue with limited version')));
      expect(paywall, isNot(contains('45-minute')));
      expect(paywall, isNot(contains('45 minutes')));
    });

    test('legal URLs remain public https', () {
      expect(
        ComplianceTexts.isUsableHostedLegalUrl(ComplianceTexts.privacyPolicyUrl),
        isTrue,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl(ComplianceTexts.termsOfServiceUrl),
        isTrue,
      );
    });
  });
}
