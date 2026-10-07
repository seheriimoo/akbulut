# Codemagic → TestFlight Internal (owner checklist)

Manual-only iOS workflow defined in repo-root `codemagic.yaml`
(`ios-testflight-internal`). No App Store release step.

Bundle ID: `com.seher.slowave`  
Apple team (Xcode): `9FR5QMHLSY`  
Flutter pin: `3.41.7` (matches GitHub V1 CI)

## Dart-define keys injected at build time

Required (Codemagic **Secure** variables):

| Variable | Notes |
|---|---|
| `OPENAI_API_KEY` | Live chat in the IPA |
| `REVENUECAT_API_KEY` | Apple public SDK key only (`appl_…`) |

Optional Secure / plain:

| Variable | Notes |
|---|---|
| `SENTRY_DSN` | Crash reporting; omit to disable upload |
| `PRIVACY_POLICY_URL` | Defaults in app if omitted |
| `TERMS_OF_SERVICE_URL` | Defaults in app if omitted |

Non-secret (plain variable):

| Variable | Notes |
|---|---|
| `APP_STORE_APPLE_ID` | Numeric App Store Connect app id (used for build number bump) |

Never put real values in git. The workflow writes an ephemeral
`config/secrets.ci.json` on the build machine, passes
`--dart-define-from-file`, then deletes the file. Logs print key **names**
only.

## Phone / panel steps (do these in Codemagic + Apple)

1. **Add the GitHub app in Codemagic**  
   Applications → Add application → `seheriimoo/akbulut` → Flutter.

2. **Scan `codemagic.yaml`**  
   Select branch `nocta/v1` → Check for configuration file.  
   Confirm workflow **iOS TestFlight Internal** appears.

3. **App Store Connect API key → Codemagic**  
   ASC → Users and Access → Integrations → App Store Connect API → create key  
   (App Manager). Download `.p8` once.  
   Codemagic → Team integrations → Developer Portal → Add key.  
   **Reference name must be exactly:** `Nocta ASC`  
   (or change `integrations.app_store_connect` in `codemagic.yaml` to match).

4. **iOS code signing identities**  
   Codemagic → Team settings → Code signing identities:  
   - Distribution certificate (upload `.p12` or Generate with the ASC key)  
   - App Store provisioning profile for `com.seher.slowave` (Fetch or upload)  
   Workflow uses `distribution_type: app_store` + that bundle id.

5. **Variable group `nocta_testflight`**  
   Application → Environment variables → create group **`nocta_testflight`**  
   (name must match `environment.groups` in yaml). Add:

   - `OPENAI_API_KEY` — Secure  
   - `REVENUECAT_API_KEY` — Secure (`appl_…`)  
   - `APP_STORE_APPLE_ID` — plain (numeric)  
   - optional: `SENTRY_DSN` — Secure  

   Attach the group to this application.

6. **App Store Connect app + Internal group**  
   - iOS app record for `com.seher.slowave` exists  
   - Internal Testing group named **`Internal Testers`**  
     (or rename `beta_groups` in yaml to your group name)

7. **Start a build (manual only)**  
   Start new build → branch **`nocta/v1`** → workflow  
   **iOS TestFlight Internal** → Start.  
   There is no push/PR auto-trigger for this workflow.

8. **Install from TestFlight**  
   After processing, open TestFlight on device → Internal → install.  
   Smoke: consent → chat (`selam` / load) → audio path.

## What this workflow does / does not do

Does:

- Sign App Store IPA with Internal Testing Only export option  
- Inject dart-defines from Codemagic secrets  
- Upload to App Store Connect / TestFlight  
- `submit_to_testflight: true`

Does **not**:

- Submit for App Store review / production release  
- Run on every git push (manual start only)  
- Print secret values in logs
