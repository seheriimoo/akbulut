# Nocta V1 — Hosted legal pages

## Publish tree (production static site)

```
legal/site/
  .nojekyll
  index.html
  privacy/index.html    → https://seheriimoo.github.io/akbulut/privacy/
  terms/index.html      → https://seheriimoo.github.io/akbulut/terms/
```

V1 hosting: **GitHub Pages project site** (default `github.io` URL, **no custom domain**, **no CNAME**).

Workflow: `.github/workflows/deploy-legal-site.yml`  
Owner steps: `legal/HOSTING_AND_DNS.md`  
Owner checklist: `config/LEGAL_PUBLISHING_CHECKLIST.md`

`legal/privacy.html` and `legal/terms.html` mirror the site pages for easy preview in-repo.

Internal nav/asset links use the `/akbulut/` project-site prefix.

## Locked owner inputs

| Field | Value |
|---|---|
| Operator | Seher Akbulut (individual) |
| Age | 18+ |
| Governing law | Republic of Türkiye |
| EULA | Apple Standard EULA |
| Public Privacy URL | https://seheriimoo.github.io/akbulut/privacy/ |
| Public Terms URL | https://seheriimoo.github.io/akbulut/terms/ |
| Contacts | privacy@nocta.app / support@nocta.app (create mailboxes separately; deferred) |
| Address | Not published |
| Custom domain | Not used for V1 (`nocta.app` recovery deferred) |

## Do not invent

Company, postal address, exclusive venue, third-party retention periods, DNS/MX values, or a custom domain for V1.
