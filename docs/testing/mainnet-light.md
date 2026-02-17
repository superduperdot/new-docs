# Mainnet Verification: Light Tier

## Purpose

The **Light** tier validates that the Brale production API is reachable, returns correct response shapes, and matches documented schemas — **without moving any value**.

This is the first of three planned verification tiers:

| Tier | Methods | Value Movement | Risk | Script |
|------|---------|---------------|------|--------|
| **Light** (this tier) | GET only | None | Zero | `scripts/verify-mainnet-light.sh` |
| Medium (future) | GET + safe POST | Address creation only | Low | `scripts/verify-mainnet-medium.sh` |
| Full (future) | All methods | Minimal transfers ($1) | Med | `scripts/verify-mainnet-full.sh` |

## What Light Tier Checks

1. **OpenAPI spec availability** — fetches and stores the production OpenAPI from both `api.brale.xyz` and `data.brale.xyz`
2. **Authentication** — validates OAuth2 client credentials flow against production auth
3. **Read-only endpoints** — hits every major GET endpoint:
   - `GET /accounts`
   - `GET /accounts/{id}/addresses`
   - `GET /accounts/{id}/transfers`
   - `GET /accounts/{id}/automations`
   - `GET /accounts/{id}/financial-institutions`
   - `GET /accounts/{id}/addresses/{id}/balance`
4. **Data API** — validates the public `data.brale.xyz` endpoints (`/tokens`, `/tokens/{symbol}`)
5. **Negative tests** — confirms error shapes:
   - 404 for bogus resource ID
   - 401 for missing authentication
6. **Schema drift detection** — compares mainnet OpenAPI paths against documented endpoints and flags any new/undocumented paths

## What Light Tier Does NOT Check

- No `POST`, `PATCH`, or `DELETE` requests
- No transfer creation (no value movement)
- No address creation
- No automation creation
- No tokenization operations (mint/burn)
- No webhook delivery
- No Plaid integration
- No fiat rails (wire, ACH, RTP)

## Safety Guardrails

The script requires three explicit environment variables before it will execute:

```bash
BRALE_ENV=mainnet           # Must be exactly "mainnet"
MAINNET_CONFIRM=true        # Explicit acknowledgement
BRALE_CLIENT_ID=...         # Mainnet credentials
BRALE_CLIENT_SECRET=...     # Mainnet credentials
```

If any are missing or incorrect, the script aborts before making any network call.

## How to Run

```bash
BRALE_ENV=mainnet \
MAINNET_CONFIRM=true \
BRALE_CLIENT_ID="${YOUR_MAINNET_CLIENT_ID}" \
BRALE_CLIENT_SECRET="${YOUR_MAINNET_CLIENT_SECRET}" \
bash scripts/verify-mainnet-light.sh
```

## Output

- Console: PASS/FAIL per endpoint with timestamps
- `artifacts/mainnet-light-run.json` — structured JSON with all results
- `artifacts/openapi-mainnet-api.json` — production API OpenAPI spec
- `artifacts/openapi-mainnet-data.yaml` — production Data API OpenAPI spec

## Relationship to Medium and Full Tiers

The **Medium** tier (future) adds safe non-destructive writes:
- Create an external address (onchain only — no bank accounts)
- Validate `Idempotency-Key` behavior
- Confirm PATCH on addresses

The **Full** tier (future) adds minimal value movement:
- Create a $1 cross-chain swap
- Create a $1 payout to an external address
- Verify transfer status transitions
- Requires dedicated test account with funded balances

Each tier builds on the previous one. Run Light first. Only escalate when Light passes clean.
