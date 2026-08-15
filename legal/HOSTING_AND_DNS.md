# Nocta V1 — Legal site hosting (GitHub Pages default URL)

Static legal pages live in `legal/site/` and are published at:

- `https://seheriimoo.github.io/akbulut/privacy/`
- `https://seheriimoo.github.io/akbulut/terms/`

## Hosting solution (V1)

**GitHub Pages project site** for `seheriimoo/akbulut`.

Why: static HTML only; already on GitHub; HTTPS by default; **no custom domain required** for App Store Privacy/Terms URLs.

V1 does **not** buy or bind a custom domain. `nocta.app` recovery is deferred. Do **not** add a `CNAME` file or enter a custom domain in Pages settings.

| Role | Who |
|---|---|
| Site files + workflow (no CNAME) | **REPOSITORY ACTION** (done in repo) |
| Enable Pages + run deploy workflow | **OWNER ACTION** |
| Custom domain / GoDaddy DNS | **Not used for V1** |

This repo does **not** deploy by itself until Pages is enabled and the workflow runs.

## A. OWNER — enable GitHub Pages (no custom domain)

1. Open `https://github.com/seheriimoo/akbulut` → **Settings** → **Pages**.
2. Under Build and deployment, choose **GitHub Actions**.
3. Leave **Custom domain** empty. If `nocta.app` (or any other domain) is already listed, **remove it** and save.
4. Run workflow **Deploy legal site** (Actions → **Deploy legal site** → **Run workflow**), or push a change under `legal/site/` on a watched branch.
5. Wait for the workflow to succeed. The environment URL should be under `https://seheriimoo.github.io/akbulut/`.

## B. OWNER — do not configure DNS

No GoDaddy, apex A records, or www CNAME are required for V1.

## C. Email (separate; deferred)

| Address | Status |
|---|---|
| privacy@nocta.app | Intended — mailbox setup deferred with `nocta.app` recovery |
| support@nocta.app | Intended — mailbox setup deferred with `nocta.app` recovery |

These addresses remain in the legal copy. They are not required to publish the GitHub Pages URLs.

## D. Verify before App Store Connect

1. Incognito browser: `https://seheriimoo.github.io/akbulut/privacy/` and `https://seheriimoo.github.io/akbulut/terms/` load over HTTPS.
2. Then paste the Privacy Policy URL into App Store Connect; use Apple Standard EULA.

See `config/LEGAL_PUBLISHING_CHECKLIST.md` for the owner checklist.
