# Brale API Documentation

Developer documentation for the [Brale](https://brale.xyz) stablecoin issuance and orchestration platform.

**Live site**: [brale.mintlify.app](https://brale.mintlify.app)

## What's in this repo

| Directory | Contents |
|-----------|----------|
| `api-reference/` | API introduction and auto-generated endpoint pages (from OpenAPI) |
| `guides/` | Step-by-step workflows: onramps, offramps, swaps, payouts, tokenization |
| `key-concepts/` | Core objects: accounts, addresses, transfers, automations, FIs |
| `overview/` | Quick start, sandbox/testnet setup |
| `coverage/` | Supported transfer types, value types, and chains |
| `documentation/` | Platform overview, API design, Data API |
| `scripts/` | Verification scripts (testnet, mainnet-light, static checks) |
| `docs/` | Internal verification reports and coverage tracking |
| `artifacts/` | OpenAPI snapshots and test run logs |

## Local development

Requires Node.js v22 (LTS). If you use `nvm`:

```bash
nvm use 22
```

Install the Mintlify CLI and start the dev server:

```bash
npm i -g mintlify
mintlify dev
```

Preview at `http://localhost:3000` (or 3001 if 3000 is in use).

## API reference

Endpoint pages are auto-generated from the production OpenAPI spec at `https://api.brale.xyz/openapi`. The spec is referenced in `docs.json`:

```json
"openapi": "https://api.brale.xyz/openapi"
```

Each endpoint page in `api-reference/brale/` is a thin MDX file with an `openapi:` frontmatter directive that Mintlify expands into a full interactive playground.

## Verification

This repo includes scripts to verify documentation accuracy against the live APIs:

```bash
# Static docs checks (semantic contract, JSON validity, link integrity)
bash scripts/docs-verify.sh

# Testnet endpoint verification (requires BRALE_CLIENT_ID/SECRET)
bash scripts/guides-verify-testnet.sh

# Mainnet read-only verification (requires mainnet credentials)
BRALE_ENV=mainnet MAINNET_CONFIRM=true \
  BRALE_CLIENT_ID=xxx BRALE_CLIENT_SECRET=yyy \
  bash scripts/verify-mainnet-light.sh
```

Results are logged to `artifacts/` and summarized in `docs/_verification.md`.

## Key conventions

- **Semantic contract**: `value_type` and `transfer_type` are sacred Brale primitives. Always snake_case, never renamed or re-cased.
- **Accept header**: Do NOT send `Accept: application/json` to `api.brale.xyz` — it causes HTTP 500. Omit the header or use `Accept: */*`.
- **Environment**: The base URL is the same for testnet and mainnet. Your credentials determine which environment you access.
- **Idempotency**: All POST and PATCH requests require an `Idempotency-Key` header.

## Deploying

Pushes to `main` auto-deploy to the live Mintlify site via the Mintlify GitHub app.

## License

[MIT](LICENSE)
