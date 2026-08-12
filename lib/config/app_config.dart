import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Production configuration loader for App Store / CI / local runs.
///
/// Secrets are supplied only via compile-time dart-defines
/// (`--dart-define` / `--dart-define-from-file`).
///
/// This module does not belong to HCOS. It does not change Conversation
/// architecture. It seeds [dotenv] so existing env readers (including
/// OpenAI vendor bootstrap) resolve the same keys without embedding
/// secrets in source or Flutter assets.
class AppConfig {
  AppConfig._();

  static const String openAiApiKeyDefine = String.fromEnvironment(
    'OPENAI_API_KEY',
  );

  static const String revenueCatApiKeyDefine = String.fromEnvironment(
    'REVENUECAT_API_KEY',
  );

  static const String sentryDsnDefine = String.fromEnvironment(
    'SENTRY_DSN',
  );

  static String _openAiApiKey = '';
  static String _revenueCatApiKey = '';
  static String _sentryDsn = '';

  /// Resolved OpenAI key (never log this value).
  static String get openAiApiKey => _openAiApiKey;

  /// Resolved RevenueCat key (never log this value).
  static String get revenueCatApiKey => _revenueCatApiKey;

  /// Resolved Sentry DSN (never log this value).
  static String get sentryDsn => _sentryDsn;

  static bool get hasOpenAiApiKey => isUsableSecret(_openAiApiKey);

  static bool get hasRevenueCatApiKey => isUsableSecret(_revenueCatApiKey);

  static bool get hasSentryDsn => isUsableSecret(_sentryDsn);

  /// True when a dart-define secret is present and not a placeholder stub.
  static bool isUsableSecret(String value) {
    final key = value.trim();
    if (key.isEmpty) return false;
    final upper = key.toUpperCase();
    if (upper.startsWith('REPLACE_WITH_')) return false;
    if (upper == 'YOUR_KEY_HERE' || upper == 'TODO') return false;
    return true;
  }

  /// Load production configuration from dart-defines and seed dotenv.
  ///
  /// Call once from app bootstrap before HCOS / Purchases initialization.
  static Future<void> load() async {
    _openAiApiKey = openAiApiKeyDefine.trim();
    _revenueCatApiKey = revenueCatApiKeyDefine.trim();
    _sentryDsn = sentryDsnDefine.trim();

    dotenv.loadFromString(
      isOptional: true,
      mergeWith: {
        'OPENAI_API_KEY': _openAiApiKey,
        'REVENUECAT_API_KEY': _revenueCatApiKey,
        'SENTRY_DSN': _sentryDsn,
      },
    );
  }
}
