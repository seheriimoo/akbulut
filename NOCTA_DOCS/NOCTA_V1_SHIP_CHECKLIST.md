# Nocta V1 Ship Checklist (TestFlight)

## Status

Operational Ship Checklist — Not Architecture

Effective Date: 2026-08-07

Conversation Architecture is frozen for V1 and is **out of scope** for this checklist.

This document lists only remaining **product shipping work** required to reach TestFlight with minimum viable scope.

No redesign.
No new features.
No Conversation Intelligence work.

---

## Live product path (ship this only)

```
Welcome → Consent (if needed) → AI Chat → Paywall (if non-premium) → Player → Night Complete
```

Everything else is quarantine/cleanup unless it blocks review.

---

## 1. Critical blockers

Must be done before any external TestFlight build is worth distributing.

### 1.1 Production RevenueCat Apple API key + store products
- **Why it matters:** Without a real Apple RC key and configured products/entitlement (`nocta_premium`), paywall shows unconfigured state and premium cannot be purchased/restored.
- **Estimated effort:** 0.5–1 day (dashboard + secrets + one purchase sanity check on device)
- **Dependency:** App Store Connect IAP products created; RevenueCat app linked to Apple
- **Repo readiness (2026-08-07):** Catalog IDs, entitlements wiring, StoreKit config, placeholder-key rejection, and setup doc are in-repo. See `config/REVENUECAT_APPLE_SETUP.md`. **Still blocked on Apple/RC dashboard + real `appl_` key.**
- **Status:** Code-ready / **not complete** until manual Apple + RevenueCat steps finish

### 1.2 Publish live Privacy Policy + Terms URLs
- **Why it matters:** App Store Connect and App Review require working public legal URLs. Current `nocta.app/privacy` and `nocta.app/terms` are not shippable placeholders.
- **Estimated effort:** 0.5–1 day (host pages matching in-app baseline text)
- **Dependency:** Domain/hosting access; copy already exists in `compliance_texts.dart`

### 1.3 App Store Connect app record + TestFlight build pipeline
- **Why it matters:** Cannot distribute TestFlight without ASC app, signing, and a reproducible `flutter build ipa` with `--dart-define-from-file`.
- **Estimated effort:** 0.5–1 day (ExportOptions or Xcode archive doc + first upload)
- **Dependency:** Apple Developer certs/profiles; items 1.1–1.2 for a reviewable binary

### 1.4 Freeze navigation to the live path only
- **Why it matters:** Orphan routes (Choice, DirectSleep, intake/Somnia, stub Player, sleep plan) can bypass billing or confuse testers if reached.
- **Estimated effort:** 0.5 day (unregister/hide dead routes; keep Begin → Consent → Chat)
- **Dependency:** None

### 1.5 Align product identity to “Nocta”
- **Why it matters:** `MaterialApp(title: 'SleepWave')`, package `slowave`, and leftover “Somnia” branding create review/tester confusion and support mismatch.
- **Estimated effort:** 0.25–0.5 day (titles/strings on live path only)
- **Dependency:** None (bundle id can stay `com.seher.slowave` for V1 if ASC already uses it)

---

## 2. High priority

Required for a credible paid TestFlight and App Review survival.

### 2.1 Paywall App Store subscription disclosures (Guideline 3.1.2)
- **Why it matters:** Auto-renewing subscriptions need clear title, length, price, auto-renew terms, and Privacy/Terms links near purchase.
- **Estimated effort:** 0.5 day
- **Dependency:** 1.1 (real offerings/prices); 1.2 (legal URLs)

### 2.2 Production Sentry DSN
- **Why it matters:** Without DSN, TestFlight crashes are invisible; you cannot triage blocker crashes from testers.
- **Estimated effort:** 0.25 day
- **Dependency:** Sentry project created; secret injected via dart-define file

### 2.3 Open/hosted legal links from Consent + Paywall (not copy-only)
- **Why it matters:** Reviewers and users must reach Privacy/Terms easily; copy-link-only is weak for store review.
- **Estimated effort:** 0.25–0.5 day (`url_launcher` or SFSafariView)
- **Dependency:** 1.2

### 2.4 Align free vs premium session length + messaging
- **Why it matters:** Free length is inconsistent (≈20m entitlement vs 30m asset/older copy). Testers will report “wrong length.”
- **Estimated effort:** 0.5 day (pick one free duration; match asset + paywall + player copy)
- **Dependency:** 1.1 product marketing decision (no new feature—consistency only)

### 2.5 Surface Player audio load failures in UI
- **Why it matters:** Silent `debugPrint` failures leave users stuck on Start Session with no explanation.
- **Estimated effort:** 0.25–0.5 day
- **Dependency:** None

### 2.6 End-to-end device smoke on TestFlight candidate
- **Why it matters:** Confirms Consent → Chat → Paywall/Restore → Player → Night Complete works on a real device with production defines.
- **Estimated effort:** 0.5 day
- **Dependency:** 1.1–1.5, 2.1–2.5

---

## 3. Medium priority

Do before wider TestFlight, after first internal build if needed.

### 3.1 Quarantine abandoned screens and backup Dart files from ship confusion
- **Why it matters:** Stub paywalls, duplicate Player, intake/Somnia, and `*_backup*` files raise merge/import risk and waste review time.
- **Estimated effort:** 0.5–1 day (move/delete unused; do not redesign)
- **Dependency:** 1.4

### 3.2 Confirm App Store privacy nutrition labels match PrivacyInfo + policy
- **Why it matters:** Mismatch (chat content, purchases, crash data) causes review delay.
- **Estimated effort:** 0.25–0.5 day
- **Dependency:** 1.2; existing `PrivacyInfo.xcprivacy`

### 3.3 Restore-purchases verification on a second device/Apple ID path
- **Why it matters:** Anonymous RC users must reliably restore; otherwise paying testers lose premium.
- **Estimated effort:** 0.25–0.5 day
- **Dependency:** 1.1

### 3.4 Background audio sanity check (lock screen / app backgrounded)
- **Why it matters:** Core sleep handoff fails if audio stops when screen locks.
- **Estimated effort:** 0.25 day
- **Dependency:** Working Player path (2.5)

### 3.5 Version / build number discipline for TestFlight uploads
- **Why it matters:** ASC rejects reuse of build numbers; `1.0.0+1` will need increments per upload.
- **Estimated effort:** 0.1 day per upload (document the bump)
- **Dependency:** 1.3

---

## 4. Polish

Nice for tester trust; not required for first internal TestFlight.

### 4.1 Remove artificial 2s delay before paywall/player transition
- **Why it matters:** Feels laggy; not a blocker.
- **Estimated effort:** 0.1 day
- **Dependency:** None

### 4.2 Replace template README / pubspec description
- **Why it matters:** Hygiene for the team; not user-facing.
- **Estimated effort:** 0.1 day
- **Dependency:** None

### 4.3 Portrait lock (optional)
- **Why it matters:** Sleep UX usually portrait-only; landscape may look unfinished.
- **Estimated effort:** 0.1–0.25 day
- **Dependency:** None

### 4.4 Contact email deliverability (`support@nocta.app` / `privacy@nocta.app`)
- **Why it matters:** Reviewers/testers may email; bouncing addresses look unready.
- **Estimated effort:** 0.25 day
- **Dependency:** Domain email setup (often with 1.2)

### 4.5 Android identity cleanup (only if you might side-load)
- **Why it matters:** `com.example.slowave` is not store-ready; irrelevant if iOS-only TestFlight.
- **Estimated effort:** 0.25 day
- **Dependency:** Explicit Android plan (otherwise skip for V1 TestFlight)

---

## Explicitly out of scope for this TestFlight push

- Conversation Intelligence / Golden Nights / Human Gold Lab
- New features (accounts, notifications, mic, social, analytics suites)
- HCOS / Blueprint / Constitution changes
- Full CI/CD automation (manual IPA upload is enough for first TestFlight)
- Perfect brand redesign beyond identity alignment on the live path

---

## Minimum path to first TestFlight (ordered)

1. ASC app + signing + build recipe (**1.3**)
2. Live Privacy/Terms (**1.2**)
3. RevenueCat Apple key + products (**1.1**)
4. Freeze live navigation + Nocta naming on path (**1.4**, **1.5**)
5. Paywall subscription legal footer (**2.1**)
6. Sentry DSN (**2.2**)
7. Legal link open from Consent/Paywall (**2.3**)
8. Free/premium length consistency (**2.4**)
9. Player error UI (**2.5**)
10. Device smoke (**2.6**)
11. Upload to TestFlight Internal Testing

**Estimated minimum calendar time:** ~3–5 focused days if Apple/RC/legal hosting access is already available.

---

## Definition of done (TestFlight-ready)

- [ ] Internal TestFlight build installs on a real iPhone
- [ ] Consent gate works; Privacy/Terms open to live pages
- [ ] Chat → audio handoff works
- [ ] Non-premium hits real paywall with real products
- [ ] Purchase or Restore grants premium session length/asset
- [ ] Player plays bed audio; failure shows UI error
- [ ] Night Complete reachable
- [ ] Sentry receives a test event from the build
- [ ] No dead route from Begin bypasses billing

When the above is checked, TestFlight can start. Wider external testing should also clear Medium items 3.1–3.4.
