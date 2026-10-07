# Codemagic → TestFlight Internal (owner checklist)

Manual-**start** iOS workflow in repo-root `codemagic.yaml`
(`ios-testflight-internal`). No App Store release step.

**Code signing: automatic** (not manual p12/profile upload).  
Codemagic uses the **Nocta ASC** App Store Connect API key plus a one-time
`CERTIFICATE_PRIVATE_KEY` (RSA PEM) to **create or fetch** the Distribution
certificate and App Store provisioning profile during the build.  
No Xcode Mac, no `.p12`, no `.mobileprovision` upload.

Bundle ID: `com.seher.slowave`  
Apple team (Xcode project): `9FR5QMHLSY`  
Flutter pin: `3.41.7` (matches GitHub V1 CI)

## Dart-define / signing variables

Required (Codemagic **Secure** variables in group `nocta_testflight`):

| Variable | Notes |
|---|---|
| `OPENAI_API_KEY` | Live chat in the IPA |
| `REVENUECAT_API_KEY` | Apple public SDK key only (`appl_…`) |
| `CERTIFICATE_PRIVATE_KEY` | 2048-bit RSA PEM (entire file including BEGIN/END lines). Not a .p12. |

Optional Secure:

| Variable | Notes |
|---|---|
| `SENTRY_DSN` | Crash reporting; omit to disable upload |
| `PRIVACY_POLICY_URL` | Defaults in app if omitted |
| `TERMS_OF_SERVICE_URL` | Defaults in app if omitted |

Non-secret (plain):

| Variable | Notes |
|---|---|
| `APP_STORE_APPLE_ID` | Numeric App Store Connect app id (build number bump) |

Never put real values in git. The workflow writes an ephemeral
`config/secrets.ci.json` on the build machine, passes
`--dart-define-from-file`, then deletes the file. Logs print key **names**
only.

### One-time `CERTIFICATE_PRIVATE_KEY` (any machine / cloud shell)

You need this **once** so Codemagic can create the Apple Distribution cert.
It is **not** a provisioning profile and does **not** require Xcode.

```bash
ssh-keygen -t rsa -b 2048 -m PEM -f ios_distribution_private_key -q -N ""
```

Open the file, copy **all** lines (`BEGIN` … `END`), paste into Codemagic as
Secure `CERTIFICATE_PRIVATE_KEY`. Keep a private backup offline; do not commit.

## Correct order (phone / panel)

Codemagic scans `codemagic.yaml` from the **branch you select**. The file is
on the PR branch first; after merge it is on `nocta/v1`. Prefer merging before
the “official” scan/build so Internal builds always come from `nocta/v1`.

1. **Merge PR #8 into `nocta/v1`**  
   So `codemagic.yaml` exists on the release branch you will build.

2. **Add the GitHub app in Codemagic**  
   Applications → Add application → `seheriimoo/akbulut` → Flutter.

3. **Scan `codemagic.yaml` on `nocta/v1`**  
   Select branch **`nocta/v1`** → Check for configuration file.  
   Confirm workflow **iOS TestFlight Internal** appears.  
   (Optional earlier check: scan PR branch `cursor/codemagic-testflight-07dc`
   before merge — not required.)

4. **App Store Connect API key → Codemagic (Nocta ASC)**  
   ASC → Users and Access → Integrations → App Store Connect API → create key  
   (App Manager). Download `.p8` once.  
   Codemagic → Team integrations → Developer Portal → Add key.  
   **Reference name must be exactly:** `Nocta ASC`  
   (must match `integrations.app_store_connect` in yaml).

5. **Variable group `nocta_testflight`**  
   Application → Environment variables → group **`nocta_testflight`**:  
   - `CERTIFICATE_PRIVATE_KEY` — Secure (RSA PEM from step above)  
   - `OPENAI_API_KEY` — Secure  
   - `REVENUECAT_API_KEY` — Secure (`appl_…`)  
   - `APP_STORE_APPLE_ID` — plain (numeric)  
   - optional: `SENTRY_DSN` — Secure  
   Attach the group to this application.  
   **Do not** upload Distribution `.p12` or provisioning profiles for this
   workflow — automatic signing creates them via Nocta ASC + `--create`.

6. **App Store Connect app + Internal group**  
   - iOS app for `com.seher.slowave` exists  
   - Internal Testing group named **`Internal Testers`**  
     (or rename `beta_groups` in yaml to match)

7. **Start a build (manual only)**  
   Start new build → branch **`nocta/v1`** → workflow  
   **iOS TestFlight Internal** → Start.  
   No push/PR auto-trigger.

8. **Install from TestFlight**  
   After processing → TestFlight → Internal → install.  
   Smoke: consent → chat → audio path.

## What this workflow does / does not do

Does:

- Automatic signing: fetch/create cert + App Store profile via ASC API  
- Mark IPA TestFlight Internal Testing Only  
- Inject dart-defines from Codemagic secrets  
- Upload to TestFlight (`submit_to_testflight: true`)

Does **not**:

- Require Mac / Xcode / manual `.p12` / `.mobileprovision`  
- Submit for App Store review / production release  
- Run on every git push  
- Print secret values in logs
