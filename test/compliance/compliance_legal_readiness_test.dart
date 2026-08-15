import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/compliance/compliance_texts.dart';
import 'package:slowave/screens/compliance/consent_gate_screen.dart';
import 'package:slowave/screens/compliance/legal_document_screen.dart';

void main() {
  group('ComplianceTexts hosted legal URLs', () {
    test('defaults are the canonical GitHub Pages https URLs', () {
      expect(
        ComplianceTexts.defaultPrivacyPolicyUrl,
        'https://seheriimoo.github.io/akbulut/privacy/',
      );
      expect(
        ComplianceTexts.defaultTermsOfServiceUrl,
        'https://seheriimoo.github.io/akbulut/terms/',
      );
      expect(
        ComplianceTexts.privacyPolicyUrl,
        'https://seheriimoo.github.io/akbulut/privacy/',
      );
      expect(
        ComplianceTexts.termsOfServiceUrl,
        'https://seheriimoo.github.io/akbulut/terms/',
      );
    });

    test('rejects placeholder / non-https stubs', () {
      expect(ComplianceTexts.isUsableHostedLegalUrl(''), isFalse);
      expect(
        ComplianceTexts.isUsableHostedLegalUrl('REPLACE_WITH_PRIVACY_URL'),
        isFalse,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl(
          'http://seheriimoo.github.io/akbulut/privacy/',
        ),
        isFalse,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl('https://example.com/privacy'),
        isFalse,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl('https://localhost/privacy'),
        isFalse,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl(
          'https://seheriimoo.github.io/akbulut/privacy/',
        ),
        isTrue,
      );
      expect(
        ComplianceTexts.isUsableHostedLegalUrl(
          'https://seheriimoo.github.io/akbulut/terms/',
        ),
        isTrue,
      );
    });

    test('baseline bodies disclose V1 processors, age, and operator', () {
      final privacy = ComplianceTexts.privacyPolicyBody.toLowerCase();
      expect(privacy, contains('openai'));
      expect(privacy, contains('revenuecat'));
      expect(privacy, contains('apple'));
      expect(privacy, contains('sentry'));
      expect(privacy, contains('not a medical'));
      expect(privacy, contains('18'));
      expect(privacy, contains('seher akbulut'));
      expect(privacy, contains('privacy@nocta.app'));
      expect(privacy, contains('not published'));

      final terms = ComplianceTexts.termsOfServiceBody.toLowerCase();
      expect(terms, contains('ai-generated'));
      expect(terms, contains('not medical'));
      expect(terms, contains('apple'));
      expect(terms, contains('subscription'));
      expect(terms, contains('18'));
      expect(
        terms.contains('republic of türkiye') ||
            terms.contains('republic of turkiye'),
        isTrue,
      );
      expect(terms, contains('standard'));
      expect(terms, contains('support@nocta.app'));
      expect(terms, contains('not published'));
    });
  });

  group('Production legal site publish tree', () {
    final siteRoot = Directory('legal/site');

    test('privacy and terms pages exist for clean URL paths', () {
      expect(File('legal/site/privacy/index.html').existsSync(), isTrue);
      expect(File('legal/site/terms/index.html').existsSync(), isTrue);
      expect(File('legal/site/index.html').existsSync(), isTrue);
      expect(File('legal/site/CNAME').existsSync(), isFalse);
      expect(siteRoot.existsSync(), isTrue);
    });

    test('production pages omit accidental draft/template ship tokens', () {
      const forbidden = [
        'OWNER_INPUT',
        'OWNER SETUP REQUIRED',
        'REPLACE_WITH_',
        'Draft — not yet published',
        'Still unresolved before publication',
        'YOUR_URL_HERE',
        'example.com',
        'TODO insert',
      ];
      for (final path in const [
        'legal/site/privacy/index.html',
        'legal/site/terms/index.html',
        'legal/site/index.html',
      ]) {
        final body = File(path).readAsStringSync();
        for (final token in forbidden) {
          expect(
            body.contains(token),
            isFalse,
            reason: '$path must not contain "$token"',
          );
        }
        expect(body.toLowerCase(), contains('nocta'));
      }
      final privacy = File('legal/site/privacy/index.html').readAsStringSync();
      final terms = File('legal/site/terms/index.html').readAsStringSync();
      expect(privacy, contains('18'));
      expect(privacy, contains('privacy@nocta.app'));
      expect(privacy, contains('Seher Akbulut'));
      expect(privacy, contains('https://seheriimoo.github.io/akbulut/privacy/'));
      expect(terms, contains('18'));
      expect(terms, contains('support@nocta.app'));
      expect(terms, contains('Standard'));
      expect(terms, contains('https://seheriimoo.github.io/akbulut/terms/'));
      expect(terms.contains('Türkiye') || terms.contains('Turkiye'), isTrue);
    });

    test('HTML nav uses /akbulut/ project-site paths, not apex-root paths', () {
      for (final path in const [
        'legal/site/index.html',
        'legal/site/privacy/index.html',
        'legal/site/terms/index.html',
      ]) {
        final body = File(path).readAsStringSync();
        expect(
          body.contains('href="/privacy/"') || body.contains("href='/privacy/'"),
          isFalse,
          reason: '$path must not use apex-root /privacy/ on a project site',
        );
        expect(
          body.contains('href="/terms/"') || body.contains("href='/terms/'"),
          isFalse,
          reason: '$path must not use apex-root /terms/ on a project site',
        );
        expect(body.contains('/akbulut/'), isTrue, reason: '$path');
      }
      expect(
        File('legal/site/index.html').readAsStringSync(),
        contains('href="/akbulut/privacy/"'),
      );
      expect(
        File('legal/site/index.html').readAsStringSync(),
        contains('href="/akbulut/terms/"'),
      );
    });

    test('app canonical URLs do not use obsolete placeholder domains', () {
      expect(
        ComplianceTexts.privacyPolicyUrl.startsWith(
          'https://seheriimoo.github.io/akbulut/',
        ),
        isTrue,
      );
      expect(
        ComplianceTexts.termsOfServiceUrl.startsWith(
          'https://seheriimoo.github.io/akbulut/',
        ),
        isTrue,
      );
      expect(ComplianceTexts.privacyPolicyUrl.contains('nocta.app'), isFalse);
      expect(ComplianceTexts.termsOfServiceUrl.contains('nocta.app'), isFalse);
      expect(ComplianceTexts.privacyPolicyUrl.contains('example.com'), isFalse);
      expect(ComplianceTexts.termsOfServiceUrl.contains('localhost'), isFalse);
    });
  });

  group('In-app legal entry points', () {
    testWidgets('Consent gate exposes Privacy and Terms actions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(home: ConsentGateScreen()),
      );

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);

      await tester.ensureVisible(find.text('Privacy Policy'));
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalDocumentScreen), findsOneWidget);
      expect(
        find.textContaining(
          'Hosted page: https://seheriimoo.github.io/akbulut/privacy/',
        ),
        findsOneWidget,
      );
      expect(find.text('Open hosted Privacy Policy'), findsOneWidget);
    });

    testWidgets('Legal screen surfaces Terms hosted URL from ComplianceTexts',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LegalDocumentScreen(kind: LegalDocumentKind.termsOfService),
        ),
      );

      expect(
        find.textContaining('Hosted page: ${ComplianceTexts.termsOfServiceUrl}'),
        findsOneWidget,
      );
      expect(find.text('Open hosted Terms of Service'), findsOneWidget);
      expect(find.text('Copy hosted Terms of Service link'), findsOneWidget);
    });
  });
}
