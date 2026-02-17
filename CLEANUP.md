# Cleanup Log

Date: 2026-02-17

## Files removed

| Path | Reason |
|------|--------|
| `scripts/` | Internal QA tooling (testnet/mainnet verification scripts, playwright automation, QA reports, screenshots). Not for public distribution. |
| `artifacts/` | Test run outputs containing account-specific data and OpenAPI snapshots from internal verification. |
| `docs/` | Internal verification ledger, coverage reports, test plans, and drift analysis. |
| `screenshots/` | QA review screenshots from internal browser testing. |
| `documentation-review-report.json` | Internal QA output. |
| `api-reference/endpoint/` | Mintlify starter kit boilerplate endpoints (not Brale API). |
| `api-reference/openapi.json` | Stale local copy of OpenAPI spec. Live spec is fetched from `api.brale.xyz/openapi`. |
| `api-reference/brale-openapi.yaml` | Stale local copy of OpenAPI spec. |
| `api-reference/introduction.mdx` | Mintlify starter kit boilerplate (replaced by `brale-introduction.mdx`). |
| `essentials/` | Mintlify starter kit boilerplate pages (code, images, markdown, navigation, snippets, settings). |
| `quickstart.mdx` | Mintlify starter kit boilerplate. |
| `development.mdx` | Mintlify starter kit boilerplate. |

## Files modified

| Path | Change |
|------|--------|
| `README.md` | Rewritten as user-focused public repo README. Removed references to internal testing, verification scripts, and production probing. |
| `.gitignore` | Updated to exclude scripts, artifacts, docs (internal), screenshots, env files, and QA reports. |
| `api-reference/brale-introduction.mdx` | Removed internal infrastructure reference ("CDN layer") from Accept header warning. |
| `guides/canton-token-standard.mdx` | Simplified Accept header note to remove internal finding language. |

## Files added

| Path | Purpose |
|------|---------|
| `CONTRIBUTING.md` | Public contribution guidelines, style expectations, and no-secrets policy. |
| `CLEANUP.md` | This file. |
