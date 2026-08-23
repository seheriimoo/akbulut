import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slowave/config/app_config.dart';

/// R2 — production secrets pipeline smoke (requires dart-define injection).
///
/// Run:
///   flutter test --dart-define-from-file=config/secrets.local.json \
///     test/config/secrets_pipeline_smoke_test.dart
///
/// Release / Archive must use the same injection:
///   flutter build ipa --dart-define-from-file=config/secrets.local.json
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('R2 secrets pipeline smoke', () {
    test('AppConfig.load wires compile-time defines into dotenv', () async {
      await AppConfig.load();

      expect(
        AppConfig.hasOpenAiApiKey,
        isTrue,
        reason:
            'OPENAI_API_KEY must be injected via --dart-define-from-file '
            '(never committed to repo)',
      );
      expect(
        dotenv.env['OPENAI_API_KEY'],
        AppConfig.openAiApiKey,
        reason: 'dotenv must mirror AppConfig for OpenAIVendorProvider.fromEnv',
      );

      expect(
        AppConfig.hasRevenueCatApiKey,
        isTrue,
        reason:
            'REVENUECAT_API_KEY must be an Apple public SDK key (appl_…) '
            'via --dart-define-from-file',
      );
      expect(
        dotenv.env['REVENUECAT_API_KEY'],
        AppConfig.revenueCatApiKey,
        reason: 'dotenv must mirror AppConfig for billing bootstrap',
      );
    });

    test('Sentry DSN is optional; placeholders count as disabled', () async {
      await AppConfig.load();

      if (AppConfig.hasSentryDsn) {
        expect(
          dotenv.env['SENTRY_DSN'],
          AppConfig.sentryDsn,
          reason: 'When set, Sentry DSN must flow through dotenv',
        );
      } else {
        expect(
          AppConfig.sentryDsn.isEmpty ||
              AppConfig.sentryDsn.toUpperCase().startsWith('REPLACE_WITH_'),
          isTrue,
          reason: 'Empty or REPLACE_WITH_ SENTRY_DSN disables crash upload',
        );
      }
    });
  });
}
