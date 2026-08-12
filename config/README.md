# Production / local secret configuration (SHIP-01)
#
# Never commit real API keys.
# Never ship secrets inside Flutter assets.
#
# Required keys:
#   OPENAI_API_KEY
#   REVENUECAT_API_KEY   (Apple public SDK key: appl_…)
#
# Optional keys:
#   SENTRY_DSN   (production crash reporting; leave empty to disable upload)
#
# Placeholder values (REPLACE_WITH_…) are treated as missing by AppConfig.
#
# Local development:
#   cp config/secrets.example.json config/secrets.local.json
#   # fill real values in secrets.local.json
#   flutter run --dart-define-from-file=config/secrets.local.json
#
# RevenueCat / App Store IAP (Critical Ship #1):
#   See config/REVENUECAT_APPLE_SETUP.md for the full Apple + RC checklist.
#   Catalog IDs live in lib/billing/billing_catalog.dart
#     entitlement: nocta_premium
#     offering:     default
#     products:     nocta_premium_monthly, nocta_premium_yearly
#
# Integration Day 1 (live OpenAI conversation smoke):
#   flutter test --dart-define-from-file=config/secrets.local.json \
#     test/integration/openai_live_conversation_test.dart
#
# Production / CI / App Store build:
#   Inject the same keys at build time (CI secret store → dart-define-from-file).
#   Example:
#   flutter build ipa --dart-define-from-file=config/secrets.local.json
#
# Do not use --dart-define on the command line in shared logs.
# Rotate any key that was previously committed or embedded in the binary.
#
# Crash reporting never logs secrets or private conversation content.
