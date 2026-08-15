# Production / local secret configuration (SHIP-01)
#
# Never commit real API keys.
# Never ship secrets inside Flutter assets.
#
# Required keys:
#   OPENAI_API_KEY
#   REVENUECAT_API_KEY   (Apple public SDK key ONLY: appl_… — not goog_/secret keys)
#
# Optional keys:
#   SENTRY_DSN   (production crash reporting; leave empty to disable upload)
#   PRIVACY_POLICY_URL   (https only; defaults to https://seheriimoo.github.io/akbulut/privacy/)
#   TERMS_OF_SERVICE_URL (https only; defaults to https://seheriimoo.github.io/akbulut/terms/)
#
# Legal publishing (P0-3):
#   Publish tree: legal/site/  → GitHub Pages project site (see legal/HOSTING_AND_DNS.md)
#   Owner checklist: config/LEGAL_PUBLISHING_CHECKLIST.md
#   In-app baseline: lib/compliance/compliance_texts.dart
#   Canonical URLs: https://seheriimoo.github.io/akbulut/privacy/ , https://seheriimoo.github.io/akbulut/terms/
#   V1 uses the default github.io URL (no custom domain).
#   Emails privacy@ / support@nocta.app remain intended; mailbox setup is OWNER ACTION and deferred.
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
