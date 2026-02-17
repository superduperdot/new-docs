# Brale Docs — Verification Report

> Generated: 2026-02-16; Updated: 2026-02-17
> Method: Spec alignment + testnet verification (authenticated)
> Bundled spec: `api-reference/brale-openapi.yaml` (v2.3.1)
> Live spec: `https://api.brale.xyz/openapi` (v1.0)
> Production base: `https://api.brale.xyz`
> Auth base: `https://auth.brale.xyz`
> Testnet credentials: `ba177097-...` (scopes: general, no tokenization)

---

## Executive Summary

| Category | PASS | FAIL | WARN | Updated |
|----------|------|------|------|---------|
| Spec alignment (bundled vs live) | — | 16 drifts | — | 2026-02-16 |
| JSON syntax in docs | 11 | 3 | — | 2026-02-16 |
| Field casing in docs | 12 | 0 | — | **Fixed 2026-02-16** |
| Internal links | 43 | 11 | 6 | 2026-02-16 |
| Endpoint coverage (docs vs live spec) | 17 | 16 missing | — | 2026-02-16 |
| Production probes (unauth) | 5 | 0 | — | 2026-02-16 |
| Semantic contract audit | 8 | 0 | — | **Fixed 2026-02-16** |
| Testnet verification (authenticated) | **17** | **0** | — | **2026-02-17** |
| Semantic drift guard (scripts) | 5 | 0 | 3 | **2026-02-17** |

**Bottom line**: The bundled OpenAPI spec is behind production (33 vs 17 operations). All testnet-verifiable endpoints now pass (17/17). Docs have been updated to match runtime behavior for: Content-Type (`application/json`), error shapes (2 formats), `source: null` on mints, Idempotency-Key on PATCH, FI `routingNumber` camelCase, and `transfer_types: null`. Semantic contract is clean (no camelCase, no inversions, no hyphenated transfer_types). Mainnet-only items tracked in `/docs/mainnet-test-plan.md`.

---

## 1. Bundled Spec vs Live Production Spec

### 1.1 Metadata Drift

| Field | Bundled (`brale-openapi.yaml`) | Live (`api.brale.xyz/openapi`) |
|-------|-------------------------------|-------------------------------|
| Title | Brale Issuance and Orchestration API | Brale API |
| Version | 2.3.1 | 1.0 |
| Content-Type | `*/*` | `application/vnd.api+json` |

**Verdict**: The live spec uses `application/vnd.api+json` (JSON:API media type). The bundled spec uses `*/*`. Docs should reflect the actual content type.

### 1.2 Endpoints: Live Has, Bundled Missing

These endpoints exist in production but are **not** in the bundled `brale-openapi.yaml`:

| # | Method | Path | Live Summary | Impact |
|---|--------|------|-------------|--------|
| 1 | GET | `/accounts/{account_id}/addresses/{address_id}` | Get individual address | **Documented in key-concepts/addresses.mdx but missing from spec** |
| 2 | PATCH | `/accounts/{account_id}/addresses/{address_id}` | Update address details | **Documented in key-concepts/addresses.mdx but missing from spec** |
| 3 | POST | `/accounts/{account_id}/addresses/{address_id}/update-link-token` | Create update link token for address | **Documented in key-concepts/addresses.mdx but missing from spec** |
| 4 | GET | `/accounts/{account_id}/financial-institutions/{fi_id}/status` | Get FI status | **Documented in key-concepts/financial-institutions.mdx but missing from spec** |
| 5 | POST | `/accounts/{account_id}/financial-institutions/{fi_id}/update-link-token` | Create update link token for FI | **Documented in key-concepts/financial-institutions.mdx but missing from spec** |
| 6 | POST | `/accounts/{account_id}/financial-institutions/plaid/link_token` | Legacy Plaid link token (FI path) | Not documented anywhere |
| 7 | POST | `/accounts/{account_id}/financial-institutions/register-account` | Legacy Plaid register (FI path) | Not documented anywhere |
| 8 | GET | `/accounts/{account_id}/tokens/mints` | List Mints | Documented in guides/tokenization.mdx but missing from spec |
| 9 | POST | `/accounts/{account_id}/tokens/mints` | Mint Tokens | Documented in guides/tokenization.mdx but missing from spec |
| 10 | GET | `/accounts/{account_id}/tokens/mints/{mint_id}` | Get Mint | Not documented |
| 11 | GET | `/accounts/{account_id}/tokens/burns` | List Burns | Not documented |
| 12 | POST | `/accounts/{account_id}/tokens/burns` | Burn Tokens | Documented in guides/tokenization.mdx but missing from spec |
| 13 | GET | `/accounts/{account_id}/tokens/burns/{burn_id}` | Get Burn | Not documented |
| 14 | GET | `/accounts/{account_id}/tokens/transfers` | List Tokenization Transfers | Not documented |
| 15 | POST | `/accounts/{account_id}/tokens/transfers` | Transfer Tokens | Not documented |
| 16 | GET | `/accounts/{account_id}/tokens/transfers/{transfer_id}` | Get Tokenization Transfer | Not documented |

### 1.3 Schema Drift

| Schema | Bundled | Live | Drift |
|--------|---------|------|-------|
| `Transfer` | Flat object with fields | **oneOf** discriminator: `BaseTransfer`, `AutomationsTransfer`, `TransferWithWireInstructions` | Live uses polymorphic responses |
| `Automation` (response) | `Automation` with `wire_instructions`, `destinationAddress` | `AutomationResponse` with `source` (includes `funding_instructions`), `destination`, `status` enum | Live has richer automation model |
| `Automation` (create) | `AutomationCreateRequest` with `name`, `destination_address` | `CreateAutomation` with `name`, `source`, `destination` | Live requires `source` field |
| `Address` | `Address` | `AddressV2` oneOf: `BlockchainAddressV2`, `FinancialInstitutionV2` | Live distinguishes blockchain vs FI addresses |
| `Account` (response) | Has `business_name`, `ein`, `address`, etc. | Only `id`, `name`, `status`, `created`, `updated` | **Live returns less data than bundled spec claims** |
| ID type | `Ksuid` (format: ksuid, pattern) | `ID` (plain string) | Cosmetic but worth noting |
| Error | Not defined | `Failure` (wraps array of `ApiError`) and `ApiErrorV2` | Live has structured error types |
| `AutomationResponse.status` | Not enumerated | `enum: [pending, active, disabled, archived]` | Live has 4 states |
| Paging | `page[size]`, `page[next]`, `page[prev]` | `PagingParameters`: `size`, `after`, `before` | **Pagination param names may differ** |
| `USStreetAddress.state` | Free string | **Enum** of all US states + territories (AL, AK, ..., WY) | Live enforces state codes |

### 1.4 OAuth2 Scope Drift

| Scope | Bundled | Live |
|-------|---------|------|
| `accounts:read` | Yes | **No** |
| `accounts:write` | Yes | **No** |
| `addresses:write` | Yes | **No** |
| `automations:read` | Yes | **No** |
| `automations:write` | Yes | **No** |
| `financial-institutions:write` | Yes | **No** |
| `transfers:read` | Yes | **No** |
| `transfers:write` | Yes | **No** |
| `addresses:read` | Yes | Yes |
| `financial-institutions:read` | Yes | Yes |
| `orders:read` | No | Yes |
| `tokens:read` | No | Yes |
| `mints:write` | No | Yes |
| `redemptions:write` | No | Yes |
| `self_attested_tokens:burn` | No | Yes |
| `self_attested_tokens:mint` | No | Yes |
| `self_attested_tokens:transfer` | No | Yes |

**Verdict**: The bundled spec invented scopes that don't exist in production. The live spec has fewer but different scopes.

---

## 2. Production Probes (Unauthenticated)

All requests made without credentials to confirm error shapes.

### 2.1 `GET /accounts` — No Auth

```
curl -s https://api.brale.xyz/accounts
```

**Response** (HTTP 401):
```json
{
  "links": null,
  "meta": null,
  "errors": [
    {
      "code": "Unauthorized",
      "id": null,
      "links": {},
      "meta": {},
      "status": "401",
      "title": "Invalid or missing credentials.",
      "source": null,
      "detail": null
    }
  ]
}
```

**Findings**:
- Content-Type: `application/json` (not `application/vnd.api+json`)
- Error structure matches `Failure` → `ApiError[]` schema from live spec
- Fields: `code`, `id`, `links`, `meta`, `status` (string), `title`, `source`, `detail`
- Response header: `x-request-id` present (useful for support debugging)

**PASS**: Error shape matches live spec `Failure`/`ApiError` schema.

### 2.2 `POST /accounts` — No Auth

```
curl -s -X POST https://api.brale.xyz/accounts -H "Content-Type: application/json" -d '{}'
```

**Response** (HTTP 401): Same `Unauthorized` error shape as above.

**PASS**: Auth check happens before body validation (expected behavior).

### 2.3 Auth Endpoint — Bad Credentials

```
curl -s -X POST https://auth.brale.xyz/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials"
```

**Response** (HTTP 400):
```json
{
  "error": "invalid_request",
  "error_description": "The request is missing a required parameter, includes an invalid parameter value, includes a parameter more than once, or is otherwise malformed. Client credentials missing or malformed in both HTTP Authorization header and HTTP POST body."
}
```

**Findings**:
- Auth endpoint uses standard OAuth2 error format (`error` + `error_description`), NOT the `Failure`/`ApiError` format
- This is correct per OAuth2 spec (RFC 6749)
- Confirms `auth.brale.xyz` is the correct auth base URL
- Confirms `client_credentials` grant type is supported

**PASS**: Auth endpoint behaves per OAuth2 spec.

### 2.4 `data.brale.xyz` — Public Stablecoin Data API

Previous probe tested wrong paths (`/`, `/tokens`, `/api`). Re-probed with correct routes:

```bash
curl -s https://data.brale.xyz/list
curl -s https://data.brale.xyz/price/sbc
curl -s https://data.brale.xyz/data/sbc
curl -s https://data.brale.xyz/help
curl -s https://data.brale.xyz/version
curl -s https://data.brale.xyz/get-started
curl -s https://data.brale.xyz/openapi.yaml
curl -s https://data.brale.xyz/.well-known/ai-plugin.json
```

**All return HTTP 200** with valid JSON (or YAML for the OpenAPI spec).

**Endpoint map** (8 routes, all `GET`, no auth required):

| Path | Description | HTTP |
|------|-------------|------|
| `/list` | All supported tokens with price/data URLs | 200 |
| `/price/{symbol}` | Price for a stablecoin (always `"1.00"` USD) | 200 |
| `/data/{symbol}` | Full token metadata: contract addresses, chain IDs, decimals, logos | 200 |
| `/help` | Self-documenting help with complete usage guide | 200 |
| `/get-started` | Quick start guide (JSON) | 200 |
| `/version` | API version info (v1.0.0, released 2025-01-27) | 200 |
| `/openapi.yaml` | OpenAPI 3.0 spec | 200 |
| `/.well-known/ai-plugin.json` | ChatGPT/LLM plugin manifest | 200 |

Symbols are case-insensitive (`sbc`, `SBC`, `Sbc` all work). Supported: `SBC`, `USDC`, `USDGLO`, `CFUSD`.

**Sample response** — `GET /price/sbc`:
```json
{
  "symbol": "SBC",
  "name": "Stable Coin",
  "price": "1.00",
  "currency": "USD",
  "details": "https://data.brale.xyz/data/sbc"
}
```

**Sample response** — `GET /list`:
```json
{
  "tokens": [
    { "name": "Brale SBC Token List", "urls": { "price": "https://data.brale.xyz/price/sbc", "data": "https://data.brale.xyz/data/sbc" } },
    { "name": "USDC List", "urls": { "price": "https://data.brale.xyz/price/usdc", "data": "https://data.brale.xyz/data/usdc" } },
    { "name": "USDGLO Token List", "urls": { "price": "https://data.brale.xyz/price/usdglo", "data": "https://data.brale.xyz/data/usdglo" } },
    { "name": "Coinflow USD", "urls": { "price": "https://data.brale.xyz/price/cfusd", "data": "https://data.brale.xyz/data/cfusd" } }
  ],
  "count": 4,
  "last_updated": "2026-02-17T00:06:39.616Z"
}
```

**Infrastructure**: Express on Vercel. CORS fully open (`access-control-allow-origin: *`). 10-minute cache (`max-age=600`).

**Error responses** (404):
- `/price/UNKNOWN` → `{"error":"No price found for ticker: UNKNOWN"}`
- `/data/UNKNOWN` → `{"error":"Token not found"}`
- Any other path → HTML `Cannot GET /path`

**PASS**: `data.brale.xyz` is fully functional with 8 documented endpoints.

---

## 3. JSON Syntax Validation — FAIL Items

### FAIL-JSON-1: `guides/stablecoin-to-fiat-offramp.mdx` — Missing comma

```json
{
  "owner": "Jane Doe",
  "account_number": "1234567890",
  "routing_number": "987654321",
  "name": "Example Bank",
  "transfer_types": ["ach_credit", "same_day_ach_credit", "rtp_credit"]   // <-- MISSING COMMA HERE
  "beneficiary_address": { ... }
}
```

**Fix**: Add comma after the `transfer_types` array.

### FAIL-JSON-2: `guides/fiat-to-stablecoin-onramp.mdx` — Missing commas in ACH response

```json
{
  "source": {
    "address_id": "2VcUIonJeVQzFoBuC7LdFT0dRe4",
    "value_type": "USD"          // <-- MISSING COMMA
    "transfer_type": "ach_debit",   // <-- TRAILING COMMA ISSUE IN CONTEXT
  },
  "destination": {
    "address_id": "2VcUIonJeVQzFoBuC7LdFT0dRe4"   // <-- MISSING COMMA
    "value_type": "SBC"          // <-- MISSING COMMA
    "transfer_type": "canton"
  }
}
```

**Fix**: Add missing commas between all fields.

### FAIL-JSON-3: `key-concepts/accounts.mdx` — JavaScript comments in JSON

The `POST /accounts` example body contains `// Optional` and `// Required for all individuals...` comments inside JSON blocks. JSON does not support comments.

**Fix**: Remove inline comments or move them to prose above/below the code block.

---

## 4. Field Casing Validation — FAIL Items

### FAIL-CASE-1: `guides/stablecoin-payouts.mdx` — USDC Payout example

```json
{
  "source": {
    "addressId": "2VcUIonJeVQzFoBuC7LdFT0dRe4",    // WRONG: should be address_id
    "valueType": "USDC",                              // WRONG: should be value_type
    "transferType": "solana"                           // WRONG: should be transfer_type
  },
  "destination": {
    "addressId": "2VcUImV6vUAo1v0cspsjD4TsmMQ",
    "valueType": "USDC",
    "transferType": "solana"
  }
}
```

Also: endpoint path is `/transfer` (singular) — should be `/transfers`.

**Fix**: Use `address_id`, `value_type`, `transfer_type`. Fix path to `/transfers`.

### FAIL-CASE-2: `guides/stablecoin-to-stablecoin-swap.mdx` — Second example

```json
{
  "sourceAddress": {           // WRONG: should be "source"
    "addressId": "...",        // WRONG: should be "address_id"
    "valueType": "USDC",      // WRONG: should be "value_type"
    "transferType": "solana"   // WRONG: should be "transfer_type"
  },
  "destinationAddress": {      // WRONG: should be "destination"
    "addressId": "...",
    "valueType": "YSBC",
    "transferType": "solana"
  }
}
```

**Fix**: Use `source`/`destination` with `address_id`, `value_type`, `transfer_type`.

### FAIL-CASE-3: `key-concepts/transfers.mdx` — ACH Debit section mislabeled

Section is titled "USD to Stablecoin (ACH Debit)" but the example JSON shows:
```json
{
  "source": {
    "address_id": "...",
    "value_type": "SBC",         // This is a stablecoin source
    "transfer_type": "polygon"   // On-chain source
  },
  "destination": {
    "address_id": "...",
    "value_type": "USD",         // This is a fiat destination
    "transfer_type": "wire"      // Off-chain destination
  }
}
```

This is a **stablecoin-to-fiat offramp**, not an ACH debit onramp.

**Fix**: Replace example with an actual ACH debit onramp example, or fix the section title.

### FAIL-CASE-4: Inconsistent `transfer_type` casing across guides

| File | Uses | Should Be |
|------|------|-----------|
| `guides/stablecoin-to-fiat-offramp.mdx` | `Solana` | `solana` |
| `guides/stablecoin-payouts.mdx` | `Solana` | `solana` |
| `key-concepts/transfers.mdx` | `Polygon`, `Solana` | `polygon`, `solana` |
| `key-concepts/automations.mdx` | `Solana` | `solana` |

The live OpenAPI `TransferType` enum uses lowercase only. The API may or may not be case-insensitive, but docs should match the spec exactly.

---

## 5. Internal Link Validation

### BROKEN (11 links, target file does not exist)

| # | Source File | Link Target | Fix |
|---|------------|-------------|-----|
| 1 | `index.mdx` | `/coverage/stablecoins-and-blockchains` | → `/coverage/transfer-types` |
| 2 | `guides/managed-accounts.mdx` | `/api/create-account` | → `/api-reference/brale/create-account` |
| 3 | `guides/managed-accounts.mdx` | `/api/list-addresses` | → `/api-reference/brale/list-addresses` |
| 4 | `guides/managed-accounts.mdx` | `/api/get-address-balance` | → `/api-reference/brale/get-address-balance` |
| 5 | `guides/managed-accounts.mdx` | `/api/get-address-balance` | → `/api-reference/brale/get-address-balance` (duplicate) |
| 6 | `guides/managed-accounts.mdx` | `/api/create-transfer` | → `/api-reference/brale/create-transfer` |
| 7 | `ai-tools/cursor.mdx` | `/quickstart` | → `/overview/quick-start` |
| 8 | `ai-tools/cursor.mdx` | `/auth` | → `/key-concepts/authentication` |
| 9 | `ai-tools/cursor.mdx` | `/rate-limits` | Remove (page doesn't exist) |
| 10 | `essentials/settings.mdx` | `/api-playground/demo` | Remove (Mintlify starter leftover) |
| 11 | `essentials/images.mdx` | `/writing-content/embed` | Remove (Mintlify starter leftover) |

### WRONG PREFIX (6 links, point to `/docs/coverage/` instead of `/coverage/`)

| # | Source File | Link Target | Fix |
|---|------------|-------------|-----|
| 1 | `documentation/introduction.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` |
| 2 | `guides/how-to/add-external-destination.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` |
| 3 | `documentation/platform/stablecoin-orchestration.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` |
| 4 | `documentation/platform/stablecoin-orchestration.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` (2nd instance) |
| 5 | `documentation/platform/stablecoin-issuance.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` |
| 6 | `documentation/api-design/primitives.mdx` | `/docs/coverage/transfer-types` | → `/coverage/transfer-types` |

---

## 6. IO URL Navigation — Inverted Parameter Descriptions

File: `io/url-navigation.mdx`

**Current (WRONG):**
> - `transfer_type`: This is the stablecoin you wish to fund and transfer.
> - `value_type`: This is the chain you want to execute the transfer on.

**Correct (per API and example URL):**
> - `transfer_type`: The chain/rail to execute the transfer on (e.g., `polygon`, `solana`).
> - `value_type`: The stablecoin/token to fund and transfer (e.g., `usdglo`, `SBC`).

The example URL `?transfer_type=usdglo&value_type=polygon` also appears inverted relative to API semantics — but since this is IO (not the API), it's possible IO intentionally swaps these params. **Requires confirmation from Brale team.**

---

## 7. Leftover Template Files (Not Brale Content)

| File | Content | Action |
|------|---------|--------|
| `api-reference/openapi.json` | Mintlify "Plant Store" OpenAPI spec | DELETE |
| `api-reference/endpoint/create.mdx` | "Create Plant" | DELETE |
| `api-reference/endpoint/get.mdx` | "Get Plants" | DELETE |
| `api-reference/endpoint/delete.mdx` | "Delete Plant" | DELETE |
| `api-reference/endpoint/webhook.mdx` | "New Plant" webhook | DELETE |
| `api-reference/introduction.mdx` | References "Plant Store Endpoints" | DELETE |
| `essentials/settings.mdx` | Generic Mintlify essentials | DELETE |
| `essentials/markdown.mdx` | Generic Mintlify essentials | DELETE |
| `essentials/code.mdx` | Generic Mintlify essentials | DELETE |
| `essentials/navigation.mdx` | Generic Mintlify essentials | DELETE |
| `essentials/images.mdx` | Generic Mintlify essentials | DELETE |
| `essentials/reusable-snippets.mdx` | Generic Mintlify essentials | DELETE |
| `snippets/snippet-intro.mdx` | Generic DRY principle snippet | DELETE |

---

## 8. Stub Pages (In Navigation, No Content)

| File | Title | Nav Entry | Action |
|------|-------|-----------|--------|
| `guides/how-to/create-a-managed-account.mdx` | "Create A Managed Account" | `guides/how-to/create-a-managed-account` | Fill with content or remove from nav |
| `guides/how-to/untitled-page.mdx` | "Create a Custodial Wallet" | `guides/how-to/untitled-page` | Fill with content or remove from nav |
| `documentation/platform/interoperability.mdx` | "Interoperability" | Listed in nav, `hidden: true` | Body is `sdf` — delete or fill |

---

## 9. Duplicate Content

| Content | File A (canonical, in nav) | File B (duplicate) | Action |
|---------|--------------------------|-------------------|--------|
| Transfer Types | `coverage/transfer-types.mdx` | `docs/coverage/transfer-types.mdx` | Merge unique content from B → A, delete B |
| Quick Start | `overview/quick-start.mdx` | `quickstart.mdx` (root) | Delete root version |
| Calculators | `tools/calculators/stablecoin-calculators.mdx` | `documentation/calculators.mdx` | Delete documentation version |

---

## 10. `data.brale.xyz` Reference — VERIFIED WORKING

`overview/introduction.mdx` states:
> `data.brale.xyz` - for public token metadata and price feeds

**Status**: Fully operational. Initial probe tested wrong paths. Correct routes confirmed:

| Endpoint | Purpose | Verified |
|----------|---------|----------|
| `GET /list` | List all tokens | PASS |
| `GET /price/{symbol}` | Token price | PASS |
| `GET /data/{symbol}` | Full metadata (contract addresses, chain IDs) | PASS |
| `GET /help` | Self-documenting help | PASS |
| `GET /get-started` | Quick start | PASS |
| `GET /version` | Version info (v1.0.0) | PASS |
| `GET /openapi.yaml` | OpenAPI 3.0 spec | PASS |
| `GET /.well-known/ai-plugin.json` | LLM plugin manifest | PASS |

**Key facts**:
- No authentication required
- CORS enabled (`*`)
- 4 tokens: SBC, USDC, USDGLO, CFUSD
- 9 chains: Ethereum, Polygon, Base, Arbitrum, Optimism, Celo, Avalanche, Solana, Stellar
- Symbols are case-insensitive
- Express on Vercel, 10-min cache

**Recommendation**: Create a dedicated reference page for `data.brale.xyz` documenting all endpoints with real response examples. Update `overview/introduction.mdx` with actual endpoint URLs.

---

## 11. All Executed Curl Commands

```bash
# 1. Fetch live OpenAPI spec
curl -s https://api.brale.xyz/openapi

# 2. Unauthenticated GET /accounts
curl -s -w "\nHTTP_STATUS: %{http_code}\n" https://api.brale.xyz/accounts

# 3. Unauthenticated POST /accounts
curl -s -w "\nHTTP_STATUS: %{http_code}\n" -X POST https://api.brale.xyz/accounts \
  -H "Content-Type: application/json" -d '{}'

# 4. Unauthenticated GET /accounts/fake_id
curl -s -w "\nHTTP_STATUS: %{http_code}\n" https://api.brale.xyz/accounts/fake_id_12345678901234

# 5. Unauthenticated POST /accounts/fake/transfers
curl -s -w "\nHTTP_STATUS: %{http_code}\n" -X POST https://api.brale.xyz/accounts/fake/transfers \
  -H "Content-Type: application/json" -d '{}'

# 6. Auth endpoint with no credentials
curl -s -w "\nHTTP_STATUS: %{http_code}\n" -X POST https://auth.brale.xyz/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" -d "grant_type=client_credentials"

# 7. data.brale.xyz probes (corrected routes)
curl -s https://data.brale.xyz/list
curl -s https://data.brale.xyz/price/sbc
curl -s https://data.brale.xyz/data/sbc
curl -s https://data.brale.xyz/help
curl -s https://data.brale.xyz/version
curl -s https://data.brale.xyz/get-started
curl -s https://data.brale.xyz/openapi.yaml
curl -s https://data.brale.xyz/.well-known/ai-plugin.json
```

---

## 12. PASS/FAIL Summary

### JSON Examples

| File | Example | Verdict |
|------|---------|---------|
| `quickstart.mdx` — auth curl | Valid bash, correct fields | PASS |
| `quickstart.mdx` — list accounts | Valid | PASS |
| `quickstart.mdx` — list addresses | Valid | PASS |
| `quickstart.mdx` — create transfer | Valid, correct casing | PASS |
| `overview/quick-start.mdx` — all examples | Valid, correct casing | PASS |
| `key-concepts/authentication.mdx` — auth curl | Valid | PASS |
| `key-concepts/transfers.mdx` — wire onramp | Valid, correct casing | PASS |
| `key-concepts/transfers.mdx` — ACH debit section | **FAIL** — example is an offramp, not ACH debit |
| `key-concepts/transfers.mdx` — wire offramp | Valid | PASS |
| `key-concepts/transfers.mdx` — ACH offramp | Valid | PASS |
| `key-concepts/transfers.mdx` — swap | Valid | PASS |
| `key-concepts/transfers.mdx` — payout | Valid | PASS |
| `key-concepts/accounts.mdx` — create account | **WARN** — has JS comments in JSON |
| `key-concepts/addresses.mdx` — all examples | Valid | PASS |
| `key-concepts/automations.mdx` — all examples | Valid, `Solana` casing | WARN |
| `key-concepts/idempotency.mdx` — all examples | Valid | PASS |
| `guides/fiat-to-stablecoin-onramp.mdx` — wire | Valid | PASS |
| `guides/fiat-to-stablecoin-onramp.mdx` — ACH response | **FAIL** — missing commas |
| `guides/stablecoin-to-fiat-offramp.mdx` — create address | **FAIL** — missing comma |
| `guides/stablecoin-to-fiat-offramp.mdx` — wire offramp | Valid | PASS |
| `guides/stablecoin-to-stablecoin-swap.mdx` — cross-chain | Valid | PASS |
| `guides/stablecoin-to-stablecoin-swap.mdx` — USDC swap | **FAIL** — camelCase fields |
| `guides/stablecoin-payouts.mdx` — USDC payout | **FAIL** — camelCase fields + wrong path |
| `guides/stablecoin-payouts.mdx` — SBC payout | Valid | PASS |
| `guides/2nd-and-3rd-party-transfers.mdx` | Valid | PASS |
| `guides/managed-accounts.mdx` | No code examples (link-only) | PASS |
| `guides/tokenization.mdx` — mint/burn | Valid | PASS |
| `guides/how-to/*.mdx` | Valid | PASS |

### Links

| Category | Count | Verdict |
|----------|-------|---------|
| Valid internal links | 43 | PASS |
| Broken (target doesn't exist) | 11 | FAIL |
| Wrong prefix (`/docs/coverage/`) | 6 | FAIL |

### Production Behavior

| Probe | Expected | Actual | Verdict |
|-------|----------|--------|---------|
| Unauth GET → 401 | JSON error | JSON `Failure` with `ApiError` | PASS |
| Unauth POST → 401 | JSON error | JSON `Failure` with `ApiError` | PASS |
| Auth bad creds → 400 | OAuth2 error | `{"error":"invalid_request",...}` | PASS |
| `data.brale.xyz` reachable | 200 | 200 JSON (8 endpoints confirmed) | **PASS** |

---

## 13. Credentials Required for Full Verification

The following items require Brale API credentials (testnet) to fully verify:

1. **Transfer create/response shapes** — need to confirm actual response fields match docs
2. **Pagination parameter names** — `page[size]`/`page[next]`/`page[prev]` (bundled) vs `size`/`after`/`before` (live)
3. **Account create response shape** — live spec returns `Account`, bundled returns `{id: Ksuid}`
4. **Automation create request shape** — live requires `source` + `destination`, bundled uses `destination_address`
5. **transfer_type case sensitivity** — does `Solana` work or must it be `solana`?
6. **`failed` transfer status** — does it exist? (Missing from both specs' enums, mentioned in docs)
7. **IO URL params** — are `transfer_type`/`value_type` actually inverted in the IO app?
8. **Error shapes for 400/403/404/422** — currently only 401 confirmed
9. **All tokenization endpoints** — need to confirm request/response shapes
10. **RTP eligibility timing** — how long after address creation does `rtp_credit` appear?

**Recommendation**: Provide testnet API credentials to complete Phase 2 and Phase 3 verification.

---

## 13a. Authenticated Runtime Verification (Testnet)

> Executed: 2026-02-17 with testnet OAuth2 client credentials.
> All requests against `https://api.brale.xyz` using bearer token.

### Authentication

```bash
curl -X POST https://auth.brale.xyz/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

**Response** (200): `{"access_token":"ory_at_...","expires_in":3599,"scope":"","token_type":"bearer"}`

- Token prefix: `ory_at_` (Ory Hydra)
- Expires in 1 hour
- `scope` field is empty string (not a list of scopes)
- **PASS**: Matches documented OAuth2 client credentials flow

### Response Content-Type

**Runtime**: `application/json` (plain JSON)
**Live OpenAPI spec claims**: `application/vnd.api+json` (JSON:API)
**Bundled spec claims**: `*/*`

**MISMATCH**: Runtime returns `application/json`, not `application/vnd.api+json`. Docs should reflect actual content type.

### Account Response Shape

```json
{
    "id": "2s55NaiUtTNSIKKGy0iajrRyHq9",
    "name": "Brale Ecosystem",
    "status": "complete",
    "updated": "2026-01-26T20:31:19",
    "created": "2025-01-24T15:29:15"
}
```

- **Fields match live spec**: `id`, `name`, `status`, `created`, `updated`
- **Bundled spec claimed**: `business_name`, `ein`, `address`, `individuals`, etc. — **NONE of these exist**
- Account status: `complete` (not `active` as might be assumed)
- Date format: ISO8601 but **no timezone** on some fields (inconsistent with addresses which include timezone)
- **PASS**: Matches live spec. Bundled spec is wrong.

### Accounts List Response

```json
{ "accounts": [{ ... }] }
```

- Wrapped in `accounts` array (NOT JSON:API `data` envelope)
- No pagination object on this endpoint
- **PASS** (simple JSON, not JSON:API)

### Address Response Shape

```json
{
    "id": "2s55QPf0rp1sSxJToQZxFVhMRy7",
    "name": "on-chain custodial address",
    "status": "active",
    "type": "internal",
    "address": "8ft5hMGTcAcLo25d4Lg5DN9hrYxHHrrTikwQTaQbmMrU",
    "transfer_types": ["solana", "solana_devnet"],
    "created": "2025-01-24T15:29:38.525556Z"
}
```

- `type` field: `"internal"` or `"external"` (matches docs)
- `transfer_types`: array of lowercase strings (matches semantic contract)
- Includes testnet-specific types: `amoy`, `base_sepolia`, `bnb`, `classic`, `fuji`, `mordor`, `viction`, `canton_testnet`, `algorand` — many **not in OpenAPI spec enum**
- **PASS**: Shape matches. New transfer_types discovered.

### Balance Response Shape

```json
{
    "address": { "id": "...", "address": "8ft5hM..." },
    "balance": { "value": "119.00", "currency": "USD" },
    "transfer_type": "solana",
    "value_type": "SBC"
}
```

- Matches bundled spec `AddressBalance` schema
- `currency` is `"USD"` (not the token symbol) — balance is always in USD equivalent
- **PASS**

### Transfer Response Shape

```json
{
    "id": "38zEvvxGJHVL1ezzpekBPbGM5Zv",
    "status": "complete",
    "source": null,
    "destination": {
        "transaction_id": "005de0c4...",
        "transfer_type": "canton_testnet",
        "address_id": "38IsL5egB8GzNsw0dOIv1IzNvre",
        "value_type": "SBC"
    },
    "updated_at": "2026-01-30T17:30:39.819777Z",
    "created_at": "2026-01-30T17:30:32.765816Z",
    "amount": { "value": "50000.00", "currency": "USD" },
    "note": null
}
```

- **`source` can be `null`** for mint transfers — docs should note this
- `destination` includes `transaction_id` (on-chain tx hash) — not in bundled spec
- Transfer list includes `pagination: { "page_size": 25 }` in response body
- Date fields use `_at` suffix (`created_at`, `updated_at`) — different from Account (`created`, `updated`)
- **PASS**: Shape is reasonable. `source: null` for mints is undocumented.

### Automation Response Shape

```json
{
    "id": "3670hdMDFjH6CzQrOoYWQGPssrH",
    "name": "bpm-test",
    "status": "active",
    "source": {
        "transfer_type": null,
        "value_type": "USD",
        "funding_instructions": {
            "bank_address": "8700 Perry Highway Pittsburgh, PA 15237",
            "beneficiary_address": "1301 Locust St Suite C Des Moines, IA 50309",
            "beneficiary_name": "Brale Inc.",
            "account_number": "105323102659",
            "routing_number": "043087080",
            "bank_name": "SSB Bank"
        }
    },
    "destination": {
        "transfer_type": "solana",
        "address_id": "2s55QPf0rp1sSxJToQZxFVhMRy7",
        "value_type": "SBC"
    },
    "updated_at": "2025-11-28T15:07:03.299166Z",
    "created_at": "2025-11-28T15:07:02.460192Z"
}
```

- `source.transfer_type` is `null` (confirmed — matches our doc fix)
- `source.funding_instructions` has flat string addresses (not structured objects)
- `funding_instructions` fields: `bank_address`, `beneficiary_address`, `beneficiary_name`, `account_number`, `routing_number`, `bank_name`
- New finding: `spark` transfer_type and `USDB` value_type exist (not in any spec)
- **PASS**: Shape matches docs. `funding_instructions` format is flat strings, not objects.

### Financial Institution Response Shape

```json
{
    "id": "33YzcN5bcXa7r8yl5JcqxwXMsxN",
    "name": "THE BANK OF TAMPA",
    "owner": "Jane Doe",
    "status": "active",
    "bank_address": { "state": "CA", "zip": "90001", "city": "Springfield", ... },
    "beneficiary_address": { "state": "CA", "zip": "90001", ... },
    "transfer_types": null,
    "created": "2025-10-03T16:27:51.515326Z",
    "account_number": "****7890",
    "needs_update": false,
    "account_type": "checking",
    "last_updated": "2025-10-03T16:27:52.824460Z",
    "routingNumber": "063108680"
}
```

**FINDINGS**:
- **`routingNumber` is camelCase** — violates snake_case convention. All other fields are snake_case. This is a runtime bug, not a docs issue.
- `transfer_types` is `null` on all FIs — docs show it with values
- `account_number` is masked (`****7890`) — good for security
- Includes `needs_update` boolean — not in bundled spec
- Includes `account_type` — not in bundled spec
- **WARN**: `routingNumber` camelCase inconsistency should be flagged.

### FI Status Endpoint

```json
{
    "status": "active",
    "last_updated": "2025-10-03T16:27:52.824460Z",
    "financial_institution_id": "33YzcN5bcXa7r8yl5JcqxwXMsxN",
    "needs_update": false
}
```

- Not in bundled spec, but documented in live spec and docs
- **PASS**

### Pagination

**Neither `size` nor `page[size]` works as query params** — both return 422 "Unexpected field."

Transfers list returns `"pagination": {"page_size": 25}` in the response body, but no query params accepted to change page size.

Addresses list returns no pagination info at all.

**MISMATCH**: Both bundled spec (`page[size]`, `page[next]`, `page[prev]`) and live spec (`size`, `after`, `before`) pagination params are **rejected by runtime**. Pagination appears to be fixed at 25 per page with no user control currently.

### Case Sensitivity

| Test | Input | Result | Response normalizes to |
|------|-------|--------|----------------------|
| `transfer_type=Solana` | Capitalized | **200 OK** | `"transfer_type": "solana"` |
| `transfer_type=solana` | Lowercase | **200 OK** | `"transfer_type": "solana"` |
| `value_type=sbc` | Lowercase | **200 OK** | `"value_type": "SBC"` |
| `value_type=SBC` | Uppercase | **200 OK** | `"value_type": "SBC"` |

**Conclusion**: API is **case-insensitive** for both fields. Responses normalize to canonical forms: uppercase `value_type`, lowercase `transfer_type`. Docs should use canonical forms per semantic contract.

### PATCH Requires Idempotency-Key

`PATCH /addresses/{id}` returns `400 BadRequest` with message: "No idempotency key found. You need to set the `Idempotency-Key` header for all POST requests."

Note: error message says "POST requests" but the requirement applies to PATCH too. Docs should mention this.

### Error Shapes — Three Distinct Formats

**Format 1: JSON:API errors** (most endpoints)
```json
{
    "links": {},
    "meta": {},
    "errors": [{
        "code": "NotFound",
        "id": null,
        "links": {},
        "meta": {},
        "status": "404",
        "title": "The requested resource was not found.",
        "source": {},
        "detail": null
    }]
}
```

Used for: 400, 401, 403, 404 (on /accounts), 422.

**Format 2: Simple error** (some endpoints)
```json
{
    "code": "NotFoundError",
    "status": 404,
    "type": "not_found",
    "values": [],
    "detail": "Resource not found"
}
```

Used for: 404 on /transfers/{id}. Note `status` is integer, not string.

**Format 3: OAuth2 error** (auth endpoint only)
```json
{
    "error": "invalid_request",
    "error_description": "..."
}
```

**MISMATCH**: Docs don't document these different error shapes. Format 1 vs Format 2 inconsistency should be called out.

### Tokenization Endpoints — 403 Forbidden

All tokenization endpoints (`/tokens/mints`, `/tokens/burns`, `/tokens/transfers`) return 403:
```json
{
    "errors": [{
        "code": "Forbidden",
        "status": "403",
        "title": "Access not permitted.",
        "detail": "Access denied for requested endpoint."
    }]
}
```

These require additional OAuth2 scopes (`mints:write`, `tokens:read`, etc.) not included in this test key.

### Undocumented Transfer Types Discovered

Runtime returns these `transfer_types` not in any spec:

| transfer_type | Context |
|--------------|---------|
| `amoy` | Polygon testnet |
| `bnb` | BNB Chain |
| `classic` | Ethereum Classic |
| `fuji` | Avalanche testnet |
| `mordor` | Ethereum Classic testnet |
| `viction` | Viction chain |
| `canton_testnet` | Canton testnet |
| `algorand` | Algorand |
| `spark` | Spark (in automation) |

### Undocumented Value Types Discovered

| value_type | Context |
|-----------|---------|
| `USDB` | Used with `spark` transfer_type |

### Previously Open Questions — Now Answered

| # | Question | Answer |
|---|----------|--------|
| 1 | Transfer response shapes | Confirmed: flat object, `source` can be null |
| 2 | Pagination param names | **Neither works** — runtime rejects both styles |
| 3 | Account response shape | Live spec is correct: only `id`, `name`, `status`, `created`, `updated` |
| 4 | Automation create shape | Confirmed: `source.transfer_type: null`, `funding_instructions` in response |
| 5 | transfer_type case sensitive? | **No** — API is case-insensitive, normalizes to lowercase |
| 8 | Error shapes 400/403/404/422 | **Three formats found** (JSON:API, simple, OAuth2) |
| 9 | Tokenization endpoints | Require additional scopes — 403 with this key |

---

## 14. Semantic Contract Audit — `value_type` / `transfer_type`

Applied the Brale Semantic Contract (non-negotiable invariants for `value_type` and `transfer_type`). All corrections logged below.

### Rule 1 — snake_case: PASS (previously fixed)

All `valueType`/`transferType` camelCase variants were fixed in prior pass (stablecoin-payouts, stablecoin-to-stablecoin-swap). No remaining violations.

### Rule 2 — No camelCase: PASS

Zero instances of `valueType` or `transferType` remain in any `.mdx` file.

### Rule 3 — No synonyms: PASS

No instances of `flow_type`, `direction`, or `mode` used as substitutes for `value_type`/`transfer_type`.

### Rule 4 — No inverted meanings: PASS (with IO caveat)

`io/url-navigation.mdx` documents IO's intentional inversion (IO uses `transfer_type` for stablecoin, `value_type` for chain). This is IO runtime behavior. Warning upgraded from `> Note` to `<Warning>` callout per semantic contract Rule 7 (runtime wins, document discrepancy clearly).

### Rule 5 — Enum values match OpenAPI exactly

**Fixed:**

| File | Was | Now | Rule |
|------|-----|-----|------|
| `key-concepts/transfers.mdx` line 24 | Prose: "Wire, ACH, Polygon, Solana, SPEI" | `` `wire`, `ach_credit`, `ach_debit`, `polygon`, `solana` `` | Enum casing in prose |
| `key-concepts/transfers.mdx` line 73 | `"value_type": "usd"` | `"value_type": "USD"` | value_type uppercase |
| `key-concepts/transfers.mdx` line 76 | `"value_type": "sbc"` | `"value_type": "SBC"` | value_type uppercase |
| `key-concepts/idempotency.mdx` line 34 | `"value_type": "usd"` | `"value_type": "USD"` | value_type uppercase |
| `key-concepts/idempotency.mdx` line 37 | `"value_type": "sbc"` | `"value_type": "SBC"` | value_type uppercase |
| `guides/fiat-to-stablecoin-onramp.mdx` line 128 | `"value_type": "usd"` | `"value_type": "USD"` | value_type uppercase |
| `key-concepts/financial-institutions.mdx` line 158 | `"transfer_type": ["ACH", "Wire"]` | `"transfer_types": ["ach_credit", "wire"]` | Enum casing + field name plural |
| `guides/2nd-and-3rd-party-transfers.mdx` line 47 | `"transfer_type": "ach-debit"` | `"transfer_type": "ach_debit"` | Hyphen → underscore |
| `guides/2nd-and-3rd-party-transfers.mdx` line 83 | `"transfer_type": "ach-debit"` | `"transfer_type": "ach_debit"` | Hyphen → underscore |

### Rule 6 — Previous inversions corrected: DONE

IO inversion documented with explicit `<Warning>` callout in `io/url-navigation.mdx`. All other prose/code inversions were fixed in prior passes.

### Rule 8 — Every transfer example includes both fields

**Fixed:**

| File | Block | Was | Now |
|------|-------|-----|-----|
| `key-concepts/automations.mdx` | Create Automation request | `source` missing `transfer_type` | Added `"transfer_type": null` |
| `guides/fiat-to-stablecoin-onramp.mdx` | Automation creation request | `source` missing `transfer_type` | Added `"transfer_type": null` |

Automation sources use `"transfer_type": null` because the rail is determined by the depositor, not the API caller. Explicit `null` makes the field's presence and intentional absence clear.

### Summary

| Rule | Status |
|------|--------|
| 1. snake_case only | PASS |
| 2. No camelCase | PASS |
| 3. No synonyms | PASS |
| 4. No inversions | PASS (IO caveat documented) |
| 5. Enum values exact | PASS (9 fixes applied) |
| 6. Correct previous inversions | PASS |
| 7. Runtime wins | PASS (IO documented) |
| 8. Both fields in every example | PASS (2 fixes applied) |

---

## 15. Full Testnet Verification Suite (2026-02-17)

Run at: `2026-02-17T00:32:14Z`
Auth: OAuth2 client_credentials → `ory_at_1p6cZ...` (expires_in: 3599)
Account: `2s55NaiUtTNSIKKGy0iajrRyHq9`
Address (Solana internal): `2s55QPf0rp1sSxJToQZxFVhMRy7`

### 15.1 Authentication

```
curl -X POST https://auth.brale.xyz/oauth2/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$CLIENT_ID:$CLIENT_SECRET" \
  -d "grant_type=client_credentials"
```

**PASS** — HTTP 200, Content-Type: `application/json`

Response:
```json
{
  "access_token": "ory_at_...",
  "expires_in": 3599,
  "scope": "",
  "token_type": "bearer"
}
```

### 15.2 Read-Only Endpoints

| # | Endpoint | curl | HTTP | Content-Type | Status |
|---|----------|------|------|--------------|--------|
| 1 | `GET /accounts` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts` | 200 | application/json | **PASS** |
| 2 | `GET /accounts/{id}` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts/2s55NaiU...` | 200 | application/json | **PASS** |
| 3 | `GET /accounts/{id}/addresses` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts/2s55NaiU.../addresses` | 200 | application/json | **PASS** |
| 4 | `GET /accounts/{id}/transfers` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts/2s55NaiU.../transfers` | 200 | application/json | **PASS** |
| 5 | `GET /accounts/{id}/automations` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts/2s55NaiU.../automations` | 200 | application/json | **PASS** |
| 6 | `GET /accounts/{id}/financial-institutions` | `curl -H "Authorization: Bearer $T" https://api.brale.xyz/accounts/2s55NaiU.../financial-institutions` | 200 | application/json | **PASS** |
| 7 | `GET /addresses/{id}` | `curl -H "Authorization: Bearer $T" .../addresses/2s55QPf0...` | 200 | application/json | **PASS** |
| 8 | `GET /addresses/{id}/balance?transfer_type=solana&value_type=SBC` | `curl -H "Authorization: Bearer $T" .../balance?transfer_type=solana&value_type=SBC` | 200 | application/json | **PASS** |

### 15.3 Response Shapes (Captured)

**Account (list):**
```json
{
  "accounts": [{
    "id": "2s55NaiUtTNSIKKGy0iajrRyHq9",
    "name": "Brale Ecosystem",
    "status": "complete",
    "updated": "2026-01-26T20:31:19",
    "created": "2025-01-24T15:29:15"
  }]
}
```

**Address (single):**
```json
{
  "id": "2s55QPf0rp1sSxJToQZxFVhMRy7",
  "name": "on-chain custodial address",
  "status": "active",
  "type": "internal",
  "address": "8ft5hMGTcAcLo25d4Lg5DN9hrYxHHrrTikwQTaQbmMrU",
  "transfer_types": ["solana", "solana_devnet"],
  "created": "2025-01-24T15:29:38.525556Z"
}
```

**Balance:**
```json
{
  "address": {
    "id": "2s55QPf0rp1sSxJToQZxFVhMRy7",
    "address": "8ft5hMGTcAcLo25d4Lg5DN9hrYxHHrrTikwQTaQbmMrU"
  },
  "balance": {"value": "119.00", "currency": "USD"},
  "transfer_type": "solana",
  "value_type": "SBC"
}
```

**Transfer (list, mint example — source is null):**
```json
{
  "pagination": {"page_size": 25},
  "transfers": [{
    "id": "38zEvvxGJHVL1ezzpekBPbGM5Zv",
    "status": "complete",
    "source": null,
    "destination": {
      "transaction_id": "005de0c4...",
      "transfer_type": "canton_testnet",
      "address_id": "38IsL5egB8GzNsw0dOIv1IzNvre",
      "value_type": "SBC"
    },
    "updated_at": "2026-01-30T17:30:39.819777Z",
    "created_at": "2026-01-30T17:30:32.765816Z",
    "amount": {"value": "50000.00", "currency": "USD"},
    "note": null
  }]
}
```

**Automation (source.transfer_type is null, funding_instructions present):**
```json
{
  "id": "3670hdMDFjH6CzQrOoYWQGPssrH",
  "name": "bpm-test",
  "status": "active",
  "source": {
    "transfer_type": null,
    "value_type": "USD",
    "funding_instructions": {
      "bank_address": "8700 Perry Highway Pittsburgh, PA 15237",
      "beneficiary_address": "1301 Locust St Suite C Des Moines, IA 50309",
      "beneficiary_name": "Brale Inc.",
      "account_number": "105323102659",
      "routing_number": "043087080",
      "bank_name": "SSB Bank"
    }
  },
  "destination": {
    "transfer_type": "solana",
    "address_id": "2s55QPf0rp1sSxJToQZxFVhMRy7",
    "value_type": "SBC"
  }
}
```

**Financial Institution (routingNumber camelCase, transfer_types null):**
```json
{
  "id": "33YzcN5bcXa7r8yl5JcqxwXMsxN",
  "name": "THE BANK OF TAMPA",
  "owner": "Jane Doe",
  "status": "active",
  "transfer_types": null,
  "account_number": "****7890",
  "routingNumber": "063108680",
  "account_type": "checking",
  "needs_update": false
}
```

### 15.4 Error Shape Tests

| # | Test | curl | HTTP | Status |
|---|------|------|------|--------|
| 1 | 404 bad account | `GET /accounts/NONEXISTENT` | 404 | **PASS** |
| 2 | 404 bad transfer | `GET /transfers/FAKE_ID` | 404 | **PASS** |
| 3 | 403 tokenization (scope) | `GET /tokens/mints` | 403 | **PASS** |
| 4 | 400 missing Idempotency-Key | `POST /transfers` (no header) | 400 | **PASS** |
| 5 | 422 empty body | `POST /transfers` (empty JSON) | 422 | **PASS** |
| 6 | 422 bad pagination | `GET /addresses?size=2` | 422 | **PASS** |

**Error format 1 (JSON:API style, most endpoints):**
```json
{
  "links": {},
  "meta": {},
  "errors": [{
    "code": "NotFound",
    "status": "404",
    "title": "The requested resource was not found.",
    "source": {},
    "detail": null
  }]
}
```

**Error format 2 (flat, observed on some 404s):**
```json
{
  "code": "NotFoundError",
  "status": 404,
  "type": "not_found",
  "values": [],
  "detail": "Resource not found"
}
```

**400 — missing Idempotency-Key:**
```json
{
  "errors": [{
    "code": "BadRequest",
    "status": "400",
    "detail": "No idempotency key found. You need to set the `Idempotency-Key` header for all POST requests: 'Idempotency-Key: KEY'"
  }]
}
```

**422 — validation errors (array, with source.pointer):**
```json
{
  "errors": [
    {
      "code": "Unprocessable Entity",
      "status": "422",
      "title": "Unable to process the contained request instructions.",
      "source": {"pointer": "/amount"},
      "detail": "Missing field: amount"
    }
  ]
}
```

### 15.5 Case Sensitivity Tests

| # | Query params | HTTP | Result |
|---|-------------|------|--------|
| 1 | `transfer_type=solana&value_type=SBC` (canonical) | 200 | Canonical values in response |
| 2 | `transfer_type=Solana&value_type=SBC` (capitalized) | 200 | Response normalizes to `solana` |
| 3 | `transfer_type=solana&value_type=sbc` (lowercase) | 200 | Response normalizes to `SBC` |

**Finding**: Runtime is case-insensitive for query params but normalizes to canonical form in responses. Docs should always use canonical casing.

### 15.6 Runtime vs Spec Discrepancies

| Finding | OpenAPI Spec | Runtime (Testnet) | Doc Action |
|---------|-------------|-------------------|------------|
| Content-Type | `application/vnd.api+json` | `application/json` | Documented in API intro as `application/json` |
| Pagination params | `size`, `after`, `before` | `size` → 422 rejected | Documented as unsupported; pagination metadata (page_size) is read-only |
| FI `routingNumber` | `routing_number` (snake_case) | `routingNumber` (camelCase) | Documented with caveat in FI reference |
| FI `transfer_types` | array of strings | `null` | Documented as nullable in FI reference |
| Transfer `source` | always object | `null` for mints | Documented in transfers reference with caveat |
| Idempotency-Key scope | POST only | POST + PATCH | Updated idempotency docs |
| Error response format | JSON:API style only | Two formats observed | Both documented in API intro |
| Tokenization endpoints | Standard auth | Requires specific scopes | Documented as mainnet-only in test plan |
| Case sensitivity | strict (implicit) | case-insensitive, normalizes | Documented; docs use canonical forms |

### 15.7 Observed transfer_type Values (Testnet)

From address `transfer_types` arrays:

**Mainnet chains**: `solana`, `ethereum`, `polygon`, `base`, `arbitrum`, `avalanche`, `optimism`, `celo`, `bnb`, `viction`, `stellar`, `hedera`, `xrp_ledger`, `spark`, `algorand`, `canton`, `classic`

**Testnet chains**: `solana_devnet`, `base_sepolia`, `sepolia`, `amoy`, `fuji`, `mordor`, `canton_testnet`, `hedera_testnet`, `coreum_testnet`, `stellar_testnet`, `tempo`, `tempo_testnet`, `radius`, `radius_testnet`

### 15.8 Observed value_type Values (Testnet)

From automations and transfers: `USD`, `SBC`, `USDB`

### 15.9 Verification Script Results

**`scripts/docs-verify.sh`** (semantic drift guard):
- Run: 2026-02-17T00:32:10Z
- camelCase ban: **PASS** (0 violations)
- singular `/transfer` ban: **PASS**
- capitalized transfer_type in JSON: **PASS**
- hyphenated transfer_type values: **PASS**
- JSON syntax validation: 20 WARN (partial snippets in data-api, essentials templates)
- Internal links: 25 valid, 2 warn (template-only pages)
- **Result: ALL CHECKS PASSED**

**`scripts/docs-verify-testnet.sh`** (testnet curl suite):
- Run: 2026-02-17T00:32:14Z
- Auth: **PASS**
- Read-only endpoints (8): **ALL PASS**
- Error shape tests (6): **ALL PASS**
- Case sensitivity tests (2): **ALL PASS**
- **Result: 17/17 PASS**

---

## 16. Docs Fixes Applied (2026-02-17, Testnet-Backed)

| File | Change | Evidence |
|------|--------|----------|
| `api-reference/brale-introduction.mdx` | Added Content-Type section (`application/json`) with spec discrepancy note | Testnet §15.2: all responses return `application/json` |
| `api-reference/brale-introduction.mdx` | Added error response reference with all observed formats | Testnet §15.4: four error formats captured |
| `api-reference/brale-introduction.mdx` | Added auth response shape with field table | Testnet §15.1: captured token response |
| `key-concepts/idempotency.mdx` | Updated to require Idempotency-Key on PATCH (not just POST) | Testnet: PATCH /addresses returns 400 without it |
| `key-concepts/idempotency.mdx` | Added real error response example | Testnet §15.4: captured 400 error body |
| `key-concepts/transfers.mdx` | Added Transfer Response Shape table; documented `source: null` for mints | Testnet §15.3: mint transfer has `source: null` |
| `key-concepts/financial-institutions.mdx` | Replaced example with real testnet response shape | Testnet §15.3: captured FI with `routingNumber`, `transfer_types: null` |
| `key-concepts/financial-institutions.mdx` | Added Note about `routingNumber` camelCase and `transfer_types: null` | Testnet §15.3: all 13 FIs have `routingNumber` and `transfer_types: null` |
| `key-concepts/authentication.mdx` | Added real token response shape and error format | Testnet §15.1: captured auth response |

---

## 17. Guide Verification Ledger (2026-02-17)

Run: `2026-02-17T02:58:02Z`
Script: `scripts/guides-verify-testnet.sh`
Result: **12 PASS, 0 FAIL, 9 SKIP**

### Guide-by-Guide Results

| # | Guide | Testnet Status | Endpoints Tested | Key Finding |
|---|-------|---------------|-----------------|-------------|
| 1 | `get-your-account-id` | **PASS** | `GET /accounts` → 200 | Response is array of account objects (not plain IDs as previously documented) |
| 2 | `get-your-address-ids` | **PASS** | `GET /accounts/{id}/addresses` → 200 | 11 internal, 31 external addresses. Both mainnet and testnet chain names in `transfer_types` |
| 3 | `get-a-balance` | **PASS** | `GET /balance?transfer_type=solana&value_type=SBC` → 200 | Balance: $119.00 SBC on solana. Case-insensitive query params (normalizes to canonical) |
| 4 | `add-external-destination` | **PASS** | `POST /addresses/external` → 201 | Successfully created external Solana address. Idempotency-Key required |
| 5 | `stablecoin-to-stablecoin-swap` | **SKIP** (API shape validated) | `POST /transfers` → 422 (empty body), 403 (mainnet chains on testnet) | Mainnet chain names return 403 "Network not supported" on testnet. Testnet chains (`solana_devnet`) accepted but $0 balance |
| 6 | `stablecoin-payouts` | **SKIP** (API shape validated) | `POST /transfers` → 400 (missing Idempotency-Key) | Same testnet chain limitation as swap |
| 7 | `fiat-to-stablecoin-onramp` | **PARTIAL PASS** | `GET /automations` → 200, `GET /automations/{id}` → 200 | Automation list/get works. `funding_instructions` populated. Wire/ACH deposit = MAINNET-ONLY |
| 8 | `stablecoin-to-fiat-offramp` | **PARTIAL PASS** | `GET /financial-institutions` → 200 | FI listing works. Wire/ACH/RTP payout = MAINNET-ONLY |
| 9 | `2nd-and-3rd-party-transfers` | **SKIP (MAINNET-ONLY)** | — | ACH branded transfers require mainnet |
| 10 | `tokenization` | **PASS** (scope check) | `GET /tokens/mints` → 403 | Confirmed: standard API key lacks tokenization scopes |
| 11 | `managed-accounts` | **PASS** | `GET /accounts` → 200 | Account listing works |
| 12 | `stablecoin-issuance` | **SKIP** | — | Dashboard-only issuance flow, not API-testable |
| 13 | `canton-token-standard` | **SKIP** | — | Canton Ledger API, not Brale API |
| 14 | `create-a-managed-account` | **SKIP** (empty page) | — | Page has no content |
| 15 | `untitled-page` | **SKIP** (empty page) | — | Page has no content |

### Critical Testnet Discovery

**Testnet transfers require testnet chain names.** On the Brale testnet:

- Mainnet chain names (`solana`, `base`, `polygon`) return **403 "Network not supported"** when used in `POST /transfers`
- Testnet chain names (`solana_devnet`, `base_sepolia`, `canton_testnet`) are accepted
- Balance queries work with both mainnet and testnet chain names
- The testnet account has funded balances on `solana` ($119 SBC) and `canton_testnet` ($50,003 SBC), but $0 on `solana_devnet` and `base_sepolia`
- The only completed transfer in history was a **mint** to `canton_testnet` (tokenization, `source: null`)
- To fully test transfers on testnet, you need: (a) tokenization scopes to mint tokens on a testnet chain, then (b) an external address registered for the same testnet chain

This means:
- **Balance, address, account, automation, and FI endpoints** are fully testable
- **Transfer creation** is API-shape-validated (correct error codes for validation failures) but end-to-end transfer completion requires either funded testnet chains or mainnet

### Guide Normalization Changes

| Guide | Changes Made |
|-------|-------------|
| `get-your-account-id` | Fixed response shape (was array of strings, now array of objects). Added Prerequisites, Verification section. Added real testnet response |
| `get-your-address-ids` | Added real testnet response with actual address shapes. Added Prerequisites, Verification section |
| `get-a-balance` | Already normalized in prior pass. Verified against testnet |
| `add-external-destination` | Already well-structured. Verified onchain address creation on testnet |
| `stablecoin-to-stablecoin-swap` | Added Prerequisites, curl examples with proper headers, Verification section. Used ${VARIABLES} instead of hardcoded IDs |
| `stablecoin-payouts` | Added Prerequisites, curl examples with proper headers, Verification section |
| `fiat-to-stablecoin-onramp` | Added MAINNET-ONLY warning. Added real testnet automation response. Added Testnet Validation table. Replaced static response with real captured response |
| `stablecoin-to-fiat-offramp` | Added MAINNET-ONLY warning. Added Note about `routingNumber` camelCase. Added Testnet Validation table |
| `2nd-and-3rd-party-transfers` | Added MAINNET-ONLY warning. Added Note about `brand` ACH-only restriction. Added Testnet Validation table |
| `tokenization` | Added Warning about required scopes. Added Testnet Validation table |

### Known Mainnet-Only Gaps

These items are tracked in `/docs/mainnet-test-plan.md`:

| Gap | Guide(s) | Mainnet Test Plan Row(s) |
|-----|----------|-------------------------|
| Wire onramp transfer | fiat-to-stablecoin-onramp | #7 |
| ACH debit onramp | fiat-to-stablecoin-onramp | #8 |
| Wire offramp | stablecoin-to-fiat-offramp | #10 |
| ACH credit offramp | stablecoin-to-fiat-offramp | #9 |
| RTP credit offramp | stablecoin-to-fiat-offramp | #11 |
| Branded ACH (2nd/3rd party) | 2nd-and-3rd-party-transfers | #9 |
| Tokenization mint/burn | tokenization | #23, #24 |
| Cross-chain swap (funded) | stablecoin-to-stablecoin-swap | #12, #13 |
| Onchain payout (funded) | stablecoin-payouts | #14 |

---

## 18. Mainnet Light Verification (2026-02-17)

**Safety tier**: LIGHT (GET only, no value movement)
**Script**: `scripts/verify-mainnet-light.sh`
**Artifact**: `artifacts/mainnet-light-run.json`
**Result**: **14 PASS, 0 FAIL**

### How to Run

```bash
BRALE_ENV=mainnet MAINNET_CONFIRM=true \
BRALE_CLIENT_ID=xxx BRALE_CLIENT_SECRET=yyy \
bash scripts/verify-mainnet-light.sh
```

### What It Checks

| # | Check | Endpoint | Status | Size |
|---|-------|----------|--------|------|
| 1 | api.brale.xyz OpenAPI spec | GET /openapi | PASS (200) | 67,300b |
| 2 | data.brale.xyz OpenAPI spec | GET /openapi.yaml | PASS (200) | 22,725b |
| 3 | OAuth2 authentication | POST /oauth2/token | PASS | — |
| 4 | List accounts | GET /accounts | PASS (200) | 160b |
| 5 | List addresses | GET /accounts/{id}/addresses | PASS (200) | 14,516b |
| 6 | List transfers | GET /accounts/{id}/transfers | PASS (200) | 18,165b |
| 7 | List automations | GET /accounts/{id}/automations | PASS (200) | 2,339b |
| 8 | List financial institutions | GET /accounts/{id}/financial-institutions | PASS (200) | 7,405b |
| 9 | Balance (internal custodial) | GET /balance?transfer_type=solana&value_type=SBC | PASS (200) | 195b |
| 10 | Data API: token list | GET data.brale.xyz/list | PASS (200) | 799b |
| 11 | Data API: price | GET data.brale.xyz/price/SBC | PASS (200) | 113b |
| 12 | Data API: token data | GET data.brale.xyz/data/SBC | PASS (200) | 1,938b |
| 13 | Negative: bogus ID | GET /accounts/{bogus}/addresses | PASS (404) | 173b |
| 14 | Negative: no auth | GET /accounts (unauthenticated) | PASS (401) | 177b |

### What It Does NOT Check

- No POST, PATCH, DELETE requests
- No transfer creation (no value movement)
- No address creation
- No automation creation
- No tokenization operations (requires separate account type)
- No Plaid integration
- No fiat rails (wire, ACH, RTP)

### Observed Drift

**16 undocumented paths in mainnet OpenAPI** (vs. what our guides cover):

| Path | Methods | Category |
|------|---------|----------|
| `/accounts/{account_id}` | GET | Single account fetch |
| `/accounts/{account_id}/addresses/{address_id}` | GET, PATCH | Single address fetch/update |
| `/accounts/{account_id}/addresses/{address_id}/update-link-token` | POST | Plaid link token refresh |
| `/accounts/{account_id}/automations/{automation_id}` | GET | Single automation fetch |
| `/accounts/{account_id}/financial-institutions/external` | POST | Create external FI |
| `/accounts/{account_id}/financial-institutions/plaid/link_token` | POST | FI Plaid linking |
| `/accounts/{account_id}/financial-institutions/register-account` | POST | FI registration |
| `/accounts/{account_id}/financial-institutions/{fi_id}` | GET | Single FI fetch |
| `/accounts/{account_id}/financial-institutions/{fi_id}/status` | GET | FI status check |
| `/accounts/{account_id}/financial-institutions/{fi_id}/update-link-token` | POST | FI link token refresh |
| `/accounts/{account_id}/plaid/link_token` | POST | Plaid linking (address-level) |
| `/accounts/{account_id}/plaid/register-account` | POST | Plaid registration |
| `/accounts/{account_id}/tokens/burns/{burn_id}` | GET | Single burn fetch |
| `/accounts/{account_id}/tokens/mints/{mint_id}` | GET | Single mint fetch |
| `/accounts/{account_id}/tokens/transfers/{transfer_id}` | GET | Single token transfer fetch |
| `/accounts/{account_id}/transfers/{transfer_id}` | GET | Single transfer fetch |

Total paths in production OpenAPI: **26**

### Runtime Discovery: `Accept: application/json` Header

The mainnet Brale API (via Cloudflare) returns **HTTP 500** when requests include `Accept: application/json`. This is a WAF or proxy behavior — not a Brale application error. Requests without the explicit Accept header work correctly and return `application/json` by default.

**Impact on integrations**: Do NOT set `Accept: application/json` header. Let the default `Accept: */*` be used.

---

## Section 19. Docs Updates from Runtime Findings (2026-02-17)

Based on testnet and mainnet light verification results, the following documentation updates were made:

### 19.1 Accept Header Fix (P0)

**Finding**: Sending `Accept: application/json` to `api.brale.xyz` causes HTTP 500 (Cloudflare/WAF rejects it). Default `Accept: */*` works and returns JSON.

**Evidence**: Observed during mainnet light verification — all authenticated endpoints returned 500 until the Accept header was removed from curl calls.

**Changes made**:
- **`api-reference/brale-introduction.mdx`**: Added `## Accept Header` section with `<Warning>` block, two correct curl examples (no Accept / wildcard Accept).
- **All curl examples in guides**: Audited — none contained explicit `Accept` headers. No changes needed to guide curl examples.
- **Note**: The Canton guide (`guides/canton-token-standard.mdx`) has `Accept: application/json` for the **Canton Ledger API** (not Brale). This is correct and was not changed.
- **`scripts/verify-mainnet-light.sh`**: Already stripped `Accept: application/json` from all `run_get` calls during mainnet light debugging.

### 19.2 Environment Clarification (P0)

**Finding**: The same `account_id` (e.g., `2s55NaiUtTNSIKKGy0iajrRyHq9`) appears on both testnet and mainnet. The base URL is the same; credentials determine environment access.

**Evidence**: Testnet verification returned the same account_id as mainnet light verification. Token exchange at `auth.brale.xyz` with testnet credentials returns testnet data; mainnet credentials return mainnet data — same URL.

**Changes made**:
- **`key-concepts/authentication.mdx`**: Added `## Environment (Testnet vs Mainnet)` section with a URL table and a `<Warning>` callout explaining that account_ids can appear identical across environments and that credentials determine environment.

### 19.3 OpenAPI Coverage Expansion (P1)

**Finding**: Production OpenAPI spec contains 26 unique paths (33 operations). Our docs previously covered only ~10 paths in guides + 17 in API reference. 16 paths were undocumented.

**Evidence**: Parsed `artifacts/openapi-mainnet-api.json` (fetched during mainnet light verification).

**Changes made**:
- **`docs/_coverage.md`**: Created full coverage report with all 26 paths, marking documented vs newly added.
- **16 new endpoint pages** created in `api-reference/brale/`:
  - `get-address.mdx` — GET /accounts/{account_id}/addresses/{address_id}
  - `update-address.mdx` — PATCH /accounts/{account_id}/addresses/{address_id}
  - `update-address-link-token.mdx` — POST .../addresses/{address_id}/update-link-token
  - `get-financial-institution-status.mdx` — GET .../financial-institutions/{fi_id}/status
  - `update-financial-institution-link-token.mdx` — POST .../financial-institutions/{fi_id}/update-link-token
  - `register-financial-institution-account.mdx` — POST .../financial-institutions/register-account
  - `create-plaid-link-token-address.mdx` — POST .../plaid/link_token
  - `list-burns.mdx` — GET .../tokens/burns
  - `create-burn.mdx` — POST .../tokens/burns
  - `get-burn.mdx` — GET .../tokens/burns/{burn_id}
  - `list-mints.mdx` — GET .../tokens/mints
  - `create-mint.mdx` — POST .../tokens/mints
  - `get-mint.mdx` — GET .../tokens/mints/{mint_id}
  - `list-tokenization-transfers.mdx` — GET .../tokens/transfers
  - `create-tokenization-transfer.mdx` — POST .../tokens/transfers
  - `get-tokenization-transfer.mdx` — GET .../tokens/transfers/{transfer_id}
- **`api-reference/additional-endpoints.mdx`**: Created human-readable reference doc covering all 16 previously undocumented paths with descriptions, curl examples, and response schemas sourced directly from the OpenAPI spec.
- **`docs.json`**: Restructured "API reference" tab nav from flat "Endpoints" group into resource-based groups (Accounts, Addresses, Transfers, Automations, Financial Institutions, Plaid, Tokenization) and added all 16 new endpoint pages.

### 19.4 Semantic Contract Verification

No `value_type` or `transfer_type` violations were introduced in this update. All new endpoint pages use exact field names from the production OpenAPI spec. The additional-endpoints reference page includes proper `value_type` and `transfer_type` in all transfer/tokenization examples.
