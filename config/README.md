# Production / local secret configuration (SHIP-01)
#
# Never commit real API keys.
# Never ship secrets inside Flutter assets.
#
# Required keys:
#   OPENAI_API_KEY
#   REVENUECAT_API_KEY
#
# Optional keys:
#   SENTRY_DSN   (production crash reporting; leave empty to disable upload)
#
# Local development:
#   cp config/secrets.example.json config/secrets.local.json
#   # fill real values in secrets.local.json
#   flutter run --dart-define-from-file=config/secrets.local.json
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
