# Nocta V1 — Privacy / Terms publishing checklist (P0-3)

In-app baseline: `lib/compliance/compliance_texts.dart`  
Publish tree: `legal/site/` (`/privacy/`, `/terms/`)  
Hosting guide: `legal/HOSTING_AND_DNS.md`

**Canonical URLs (GitHub Pages project site — no custom domain)**

| Document | URL |
|---|---|
| Privacy Policy | `https://seheriimoo.github.io/akbulut/privacy/` |
| Terms of Service | `https://seheriimoo.github.io/akbulut/terms/` |

## Locked decisions

- Operator: Seher Akbulut (individual; no company)
- Age: 18+ (contractual; not App Store age rating)
- Governing law: Republic of Türkiye + mandatory consumer rights preserved
- EULA: Apple Standard EULA
- Hosting: GitHub Pages default `github.io` URL for `seheriimoo/akbulut`
- Custom domain: **not used for V1** (`nocta.app` recovery deferred)
- Intended emails: privacy@nocta.app / support@nocta.app (mailbox setup deferred)
- Postal address: not published (no residential address)

## Owner checklist (do in order)

### A. Enable GitHub Pages (GitHub Actions)
- [ ] Repo → Settings → Pages → Source: **GitHub Actions**
- [ ] Custom domain field is **empty** (remove `nocta.app` if present)
- [ ] Details: `legal/HOSTING_AND_DNS.md`

### B. Deploy the legal site
- [ ] Actions → **Deploy legal site** → Run workflow
- [ ] Confirm the run succeeds
- [ ] Confirm deploy includes `legal/site/privacy/index.html` and `legal/site/terms/index.html`

### C. Verify both URLs over HTTPS
- [ ] Incognito: `https://seheriimoo.github.io/akbulut/privacy/` loads
- [ ] Incognito: `https://seheriimoo.github.io/akbulut/terms/` loads
- [ ] Certificate valid; no placeholder/draft banners
- [ ] In-page Privacy ↔ Terms links stay under `/akbulut/`

### D. Enter Privacy Policy URL in App Store Connect
- [ ] App Information → Privacy Policy URL = `https://seheriimoo.github.io/akbulut/privacy/`

### E. Confirm Apple Standard EULA
- [ ] App Store Connect → use **Apple’s Standard EULA** (no custom EULA)
- [ ] Terms URL available as `https://seheriimoo.github.io/akbulut/terms/` where ASC asks for license/terms link

### F. Later — paywall Guideline 3.1.2
- [ ] Wire Privacy + Terms links on the subscription paywall (future P0; not this task)
- [ ] Use `ComplianceTexts.privacyPolicyUrl` / `termsOfServiceUrl`

### G. Deferred — custom domain + mailboxes
- [ ] `nocta.app` recovery / purchase is **not** a V1 hosting blocker
- [ ] privacy@nocta.app / support@nocta.app mailbox setup remains deferred

## Still not claimed by this repo

- Live HTTPS until A–C are done in GitHub
- Mailboxes until G is done
- Exact third-party retention periods (pages correctly say “under their own policies”)
