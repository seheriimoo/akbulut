#!/usr/bin/env bash
# R2 — verify production secrets reach the build via dart-define-from-file.
# Never prints secret values. Exit 0 = pipeline ready for Archive/TestFlight.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SECRETS_FILE="${SECRETS_FILE:-config/secrets.local.json}"

echo "== R2 secrets pipeline verify =="
echo "secrets file: $SECRETS_FILE"

if [[ ! -f "$SECRETS_FILE" ]]; then
  echo "FAIL: $SECRETS_FILE missing."
  echo "  cp config/secrets.example.json config/secrets.local.json"
  exit 1
fi

python3 - <<'PY' "$SECRETS_FILE"
import json, sys
path = sys.argv[1]
d = json.load(open(path))
required = ["OPENAI_API_KEY", "REVENUECAT_API_KEY"]
optional = ["SENTRY_DSN"]
fail = False
for k in required:
    v = (d.get(k) or "").strip()
    if not v or v.upper().startswith("REPLACE_WITH_"):
        print(f"FAIL: {k} missing or placeholder in {path}")
        fail = True
    elif k == "REVENUECAT_API_KEY" and not v.startswith("appl_"):
        print(f"FAIL: {k} must start with appl_ (Apple public SDK key)")
        fail = True
    else:
        print(f"OK:   {k} set")
for k in optional:
    v = (d.get(k) or "").strip()
    if not v or v.upper().startswith("REPLACE_WITH_"):
        print(f"WARN: {k} empty/placeholder — crash upload disabled")
    else:
        print(f"OK:   {k} set")
sys.exit(1 if fail else 0)
PY

echo ""
echo "== Offline AppConfig contract tests =="
flutter test test/billing/billing_catalog_test.dart test/billing/billing_service_contract_test.dart

echo ""
echo "== R2 injection smoke (dart-define-from-file) =="
flutter test --dart-define-from-file="$SECRETS_FILE" \
  test/config/secrets_pipeline_smoke_test.dart

echo ""
echo "== Release compile check (no codesign) =="
flutter build ios --no-codesign --dart-define-from-file="$SECRETS_FILE"

echo ""
echo "R2 PASS: secrets inject via dart-define-from-file; no repo embedding required."
echo "Archive: flutter build ipa --dart-define-from-file=$SECRETS_FILE"
