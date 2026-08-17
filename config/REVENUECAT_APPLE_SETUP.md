# RevenueCat + App Store IAP setup (P0-1)

Manual Apple / RevenueCat checklist. App code already expects these exact
identifiers. This file never contains real secrets.

## Canonical identifiers (must match)

| Layer | Identifier |
|---|---|
| iOS bundle id | `com.seher.slowave` |
| RevenueCat entitlement | `nocta_premium` |
| RevenueCat offering (Current) | `default` |
| ASC product — monthly | `nocta_premium_monthly` |
| ASC product — yearly | `nocta_premium_yearly` |

Defined in code: `lib/billing/billing_catalog.dart`.

Premium session access when entitlement active:
- Duration: **45 minutes** (`PremiumProductAccess.premiumSessionLength`)
- Free (no entitlement): **30 minutes**

## A. App Store Connect (ordered)

1. Confirm the iOS app record uses bundle id **`com.seher.slowave`**.
2. Apple Developer → Identifiers → App ID `com.seher.slowave` → enable
   **In-App Purchase**.
3. Xcode → open `ios/Runner.xcworkspace` → Runner target →
   **Signing & Capabilities** → confirm **In-App Purchase** capability is
   present.
   - Note: `Runner/Runner.entitlements` may remain an empty plist for IAP-only;
     IAP does not require inventing extra entitlement keys in that file.
4. App Store Connect → Nocta app → **Subscriptions**:
   - Create a **Subscription Group** (e.g. “Nocta Premium”).
   - Create auto-renewable subscription **`nocta_premium_monthly`**:
     - Duration: 1 month
     - Reference name: Nocta Premium Monthly
     - Localization (at least `en_US`): display name + description
     - Price: choose tier (StoreKit local sample uses $9.99)
     - Availability: all countries you intend to sell
   - Create auto-renewable subscription **`nocta_premium_yearly`**:
     - Duration: 1 year
     - Reference name: Nocta Premium Yearly
     - Localization (at least `en_US`)
     - Price: choose tier (StoreKit local sample uses $59.99)
     - Availability: same as monthly
5. For each product, complete any required **review information**
   (screenshot / review notes) so status can leave Missing Metadata.
6. Wait until both products are **Ready to Submit** (or at least available for
   Sandbox). Paid Apps Agreement / banking / tax must be active for sandbox
   purchases to work.
7. Create a **Sandbox Apple ID** (Users and Access → Sandbox) for device tests.

## B. RevenueCat (ordered)

1. Create/select the iOS app with bundle id **`com.seher.slowave`**.
2. Connect App Store Connect to RevenueCat (ASC API key / In-App Purchase key
   as RevenueCat currently requires for your project).
3. Add products:
   - `nocta_premium_monthly`
   - `nocta_premium_yearly`
4. Create entitlement **`nocta_premium`** and attach **both** products.
5. Create/use offering identifier **`default`**:
   - Attach monthly package → product `nocta_premium_monthly`
   - Attach yearly package → product `nocta_premium_yearly`
   - Mark offering **Current**
6. Project settings → API keys → copy the **Apple public SDK key**
   (`appl_…` only — not the secret API key).
7. Put that key into local secrets (never commit):
   - `config/secrets.local.json` → `"REVENUECAT_API_KEY": "appl_…"`
   - Placeholder `REPLACE_WITH_…` and non-`appl_` values are treated as
     **unconfigured** by `AppConfig`.

## C. Local / release key injection

```bash
# One-time
cp config/secrets.example.json config/secrets.local.json
# Edit secrets.local.json — set real appl_ key. Do not commit this file.

# Run / test with injection
flutter run --dart-define-from-file=config/secrets.local.json

# Release IPA
flutter build ipa --dart-define-from-file=config/secrets.local.json
```

CI must inject the same JSON from a secret store. Never embed keys in assets
or source.

Optional StoreKit Configuration (simulator / local Xcode):

1. Open `ios/Runner.xcworkspace`.
2. Product → Scheme → Edit Scheme → Run → Options.
3. StoreKit Configuration should be `Runner/NoctaProducts.storekit`
   (wired in the shared `Runner` scheme for local runs).

## D. Sandbox verification procedure

On a real iPhone (preferred) or simulator with StoreKit config:

1. Sign out of production App Store / use Sandbox Apple ID when prompted.
2. Launch:
   ```bash
   flutter run --dart-define-from-file=config/secrets.local.json
   ```
3. **Free path:** complete Consent → Chat → handoff without purchasing.
   Confirm free (limited) session length / free bed (~30m).
4. Trigger paywall from live night path (non-premium at audio boundary).
5. Confirm packages load with store prices for monthly + yearly
   (not “Purchases are not configured” / empty offerings).
6. Purchase **monthly** or **yearly** with Sandbox Apple ID.
7. Confirm purchase returns to chat/audio path with premium access:
   entitlement `nocta_premium` → **45-minute** premium session.
8. Force-quit and relaunch the app (same Apple ID / anonymous RC user as
   restored by Apple). Confirm premium still active without re-buying.
9. Fresh install or “Restore purchases” on paywall → premium restored.
10. Cancel mid-sheet once → remain free; no premium unlock.

## Done when

- [ ] ASC products exist with the IDs above
- [ ] RevenueCat entitlement + current offering `default` configured
- [ ] `appl_` key in secrets (not placeholder; not committed)
- [ ] Device/sandbox build loads offerings and can purchase/restore premium
- [ ] Free remains free without purchase; premium unlocks 45m session
