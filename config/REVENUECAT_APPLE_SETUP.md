# RevenueCat + App Store IAP setup (Critical Ship #1)

This is the manual Apple / RevenueCat checklist that cannot be completed from
the Flutter repo alone. App code already expects these exact identifiers.

## Canonical identifiers (must match)

| Layer | Identifier |
|---|---|
| iOS bundle id | `com.seher.slowave` |
| RevenueCat entitlement | `nocta_premium` |
| RevenueCat offering (Current) | `default` |
| ASC product — monthly | `nocta_premium_monthly` |
| ASC product — yearly | `nocta_premium_yearly` |

Defined in code: `lib/billing/billing_catalog.dart`.

## A. Apple Developer / App Store Connect

1. Open the App ID for `com.seher.slowave`.
2. Enable **In-App Purchase** capability.
3. In Xcode → Runner → Signing & Capabilities, confirm **In-App Purchase** is present (entitlements file is wired: `Runner/Runner.entitlements`).
4. In App Store Connect → your Nocta app → **Subscriptions**:
   - Create subscription group (e.g. “Nocta Premium”).
   - Create auto-renewable products:
     - `nocta_premium_monthly` (1 month)
     - `nocta_premium_yearly` (1 year)
   - Add localization, pricing, review screenshot/notes as required.
5. Wait until products are **Ready to Submit** / available for the sandbox.

## B. RevenueCat dashboard

1. Create/select the iOS app with bundle id `com.seher.slowave`.
2. Connect App Store Connect API key / shared secret as RevenueCat requires.
3. Add products `nocta_premium_monthly` and `nocta_premium_yearly`.
4. Create entitlement **`nocta_premium`** and attach both products.
5. Create/use offering **`default`**, attach both packages, mark offering **Current**.
6. Copy the **Apple public SDK key** (`appl_…`) into local secrets:
   - `config/secrets.local.json` → `REVENUECAT_API_KEY`
   - Never commit the real key.
7. Placeholder values (`REPLACE_WITH_…`) are treated as **unconfigured** by the app.

## C. Local / TestFlight verification

```bash
# Device / simulator with secrets injected
flutter run --dart-define-from-file=config/secrets.local.json
```

Optional StoreKit local config (Xcode):

1. Open `ios/Runner.xcworkspace`.
2. Product → Scheme → Edit Scheme → Run → Options.
3. Set StoreKit Configuration to `Runner/NoctaProducts.storekit`.

Then:

1. Open paywall from the live night path.
2. Confirm packages load with real store prices (not “not configured”).
3. Sandbox purchase → entitlement `nocta_premium` active.
4. Restore purchases on a fresh install / second device path.

## D. Build injection

```bash
flutter build ipa --dart-define-from-file=config/secrets.local.json
```

CI must inject the same JSON from a secret store. Do not embed keys in assets.

## Done when

- [ ] ASC products exist with the IDs above
- [ ] RevenueCat entitlement + current offering configured
- [ ] `appl_` key in secrets (not placeholder)
- [ ] Device build loads offerings and can purchase/restore premium
