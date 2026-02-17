# Mainnet Verification Test Plan

> Purpose: Set the table for future mainnet verification so docs can reach full production parity.
> No mainnet calls should be made until each row's preconditions and safe-test method are reviewed.
> Generated: 2026-02-17

---

## Test Matrix

| # | Area | Endpoint(s) | Why Mainnet Required | Preconditions | Safe Test Method | Expected Result | Cleanup | Owner / Credentials | Risk |
|---|------|-------------|---------------------|---------------|-----------------|-----------------|---------|-------------------|------|
| 1 | **Auth** | `POST auth.brale.xyz/oauth2/token` | Confirm mainnet token issuance differs from testnet | Mainnet client_id + client_secret | Standard client_credentials grant | 200 + `ory_at_` token, `expires_in: 3599` | None | Mainnet API key | Low |
| 2 | **Accounts (list)** | `GET /accounts` | Verify mainnet account shape, pagination | Valid mainnet token | Read-only GET | 200 + `{ "accounts": [...] }` with `id`, `name`, `status`, `created`, `updated` | None | Mainnet API key | Low |
| 3 | **Accounts (create)** | `POST /accounts` | Verify KYB flow + required fields on mainnet | Mainnet token + KYB data (EIN, business address, individuals) | Create test account with minimal real data; use Idempotency-Key | 201 + account object; verify status transitions | May need to archive test account | Mainnet API key + compliance | Med |
| 4 | **Addresses (list)** | `GET /accounts/{id}/addresses` | Verify internal address auto-creation on mainnet (which chains?) | Mainnet account in `complete` status | Read-only GET | 200 + addresses with `type: internal` for all supported mainnet chains | None | Mainnet API key | Low |
| 5 | **Addresses (create external)** | `POST /accounts/{id}/addresses` | Verify external address registration + transfer_types enum on mainnet | Mainnet account + real wallet address | Create external blockchain address with Idempotency-Key | 201 + address with correct `transfer_types` | Can archive address | Mainnet API key | Low |
| 6 | **Address balance** | `GET /addresses/{id}/balance?transfer_type=X&value_type=Y` | Confirm balance query works; verify `currency` field (always USD?) | Internal address with non-zero balance | Read-only GET with valid transfer_type/value_type pair | 200 + `{ address, balance, transfer_type, value_type }` | None | Mainnet API key | Low |
| 7 | **Fiat onramp (wire)** | `POST /accounts/{id}/transfers` | Verify wire_instructions are returned; confirm source shape | Mainnet account + internal address on target chain | Create wire onramp with minimal amount ($1); use Idempotency-Key | 201 + transfer with `wire_instructions` object; status=`pending` | Transfer will remain `pending` until wire received; no actual money moves | Mainnet API key + funded account | Med |
| 8 | **Fiat onramp (ACH debit)** | `POST /accounts/{id}/transfers` | Verify ACH debit flow; confirm Plaid-linked address required | Mainnet account + Plaid-linked FI address | Create ACH debit with minimal amount ($1); use Idempotency-Key | 201 + transfer; status transitions `pending` → `processing` → `complete` | Real money moves; use dedicated test bank account | Mainnet API key + Plaid FI | **High** |
| 9 | **Fiat offramp (ACH credit)** | `POST /accounts/{id}/transfers` | Verify ACH credit payout; confirm `brand` field | Mainnet account + stablecoin balance + external FI address | Create ACH credit payout with minimal amount; include `brand` | 201 + transfer; verify `brand` appears in response | Real money moves; use dedicated test bank account | Mainnet API key + balance | **High** |
| 10 | **Fiat offramp (wire)** | `POST /accounts/{id}/transfers` | Verify wire offramp flow | Mainnet account + stablecoin balance + external FI address | Create wire offramp with minimal amount | 201 + transfer; confirm no wire_instructions on offramp | Real money moves | Mainnet API key + balance | **High** |
| 11 | **Fiat offramp (RTP)** | `POST /accounts/{id}/transfers` | Verify RTP payout timing; confirm rtp_credit eligibility | Mainnet account + RTP-eligible FI address | Create RTP payout with minimal amount | 201 + transfer; near-instant completion | Real money moves | Mainnet API key + RTP address | **High** |
| 12 | **Swap (stablecoin)** | `POST /accounts/{id}/transfers` | Verify cross-token swap (e.g., USDC→SBC) | Mainnet account + balance in source token | Create swap with minimal amount | 201 + transfer with both source/destination populated | Tokens swap but value preserved | Mainnet API key + balance | Med |
| 13 | **Swap (cross-chain)** | `POST /accounts/{id}/transfers` | Verify cross-chain swap (e.g., SBC/polygon→SBC/solana) | Mainnet account + balance on source chain | Create cross-chain swap with minimal amount | 201 + transfer | Tokens move chains but value preserved | Mainnet API key + balance | Med |
| 14 | **On-chain payout** | `POST /accounts/{id}/transfers` | Verify payout to external wallet | Mainnet account + balance + external address | Create payout with minimal amount | 201 + transfer; `destination.transaction_id` populated on completion | Tokens sent to external wallet | Mainnet API key + balance | Med |
| 15 | **Automations (create)** | `POST /accounts/{id}/automations` | Verify automation creation + funding_instructions | Mainnet account | Create automation with Idempotency-Key; target internal address | 201 + automation; status transitions `pending` → `active` with `funding_instructions` | May need to archive automation | Mainnet API key | Med |
| 16 | **Automations (deposit test)** | Wire/ACH to automation coordinates | Verify end-to-end: deposit → auto-mint → destination address | Active automation + funding coordinates | Send minimal wire to automation coordinates | Transfer created automatically; stablecoins appear at destination | Real money moves | Mainnet API key + banking | **High** |
| 17 | **Financial Institutions (create)** | `POST /accounts/{id}/financial-institutions` | Verify manual FI creation with bank details | Mainnet account | Create FI with test bank details; use Idempotency-Key | 201 + FI object; verify `routingNumber` casing, `transfer_types` | Can delete FI | Mainnet API key | Low |
| 18 | **Financial Institutions (Plaid)** | `POST .../plaid/link_token` + register | Verify Plaid integration end-to-end | Mainnet account + Plaid sandbox keys | Use Plaid sandbox mode to link test bank | Link token + successful FI registration | FI created from Plaid | Mainnet API key + Plaid | Med |
| 19 | **FI status** | `GET .../financial-institutions/{id}/status` | Verify status endpoint + `needs_update` flag | Mainnet FI | Read-only GET | 200 + `{ status, last_updated, financial_institution_id, needs_update }` | None | Mainnet API key | Low |
| 20 | **FI update-link-token** | `POST .../financial-institutions/{id}/update-link-token` | Verify update flow for stale FIs | Mainnet FI with `needs_update: true` | Create update link token | 201 + link token for re-auth | None | Mainnet API key | Low |
| 21 | **PATCH address** | `PATCH /accounts/{id}/addresses/{id}` | Verify address update + Idempotency-Key requirement | Mainnet account + address | PATCH with name change; include Idempotency-Key | 200 + updated address | Revert name if needed | Mainnet API key | Low |
| 22 | **Address update-link-token** | `POST .../addresses/{id}/update-link-token` | Verify address re-auth flow | Mainnet address needing update | Create update link token | 201 + link token | None | Mainnet API key | Low |
| 23 | **Tokenization (mint)** | `POST /accounts/{id}/tokens/mints` | Verify mint flow + required scopes | Mainnet token with `mints:write` scope | Mint minimal amount to custodial address | 201 + mint object; `source: null` in resulting transfer | Tokens minted | Mainnet API key + mints:write | Med |
| 24 | **Tokenization (burn)** | `POST /accounts/{id}/tokens/burns` | Verify burn flow + required scopes | Mainnet token with `redemptions:write` scope + balance | Burn minimal amount from custodial address | 201 + burn object | Tokens destroyed | Mainnet API key + redemptions:write | Med |
| 25 | **Tokenization (transfer)** | `POST /accounts/{id}/tokens/transfers` | Verify token transfer flow | Mainnet token with appropriate scopes + balance | Transfer minimal amount between addresses | 201 + transfer object | Tokens moved | Mainnet API key + token scopes | Med |
| 26 | **Pagination** | All list endpoints | Verify if/when pagination becomes controllable | Large dataset (>25 items) | Test query params: `size`, `after`, `before`, `page[size]`, `page[next]` | Determine which (if any) params are accepted | None | Mainnet API key | Low |
| 27 | **Content-Type** | All endpoints | Confirm `application/json` vs `application/vnd.api+json` on mainnet | Any valid request | Check `Content-Type` response header | Expect `application/json` (matching testnet) | None | Mainnet API key | Low |
| 28 | **Error shape consistency** | `GET /transfers/{bad_id}` vs `GET /accounts/{bad_id}` | Verify if two error formats persist on mainnet | Any valid token | Request nonexistent resources on different endpoints | Document which endpoints use which error format | None | Mainnet API key | Low |
| 29 | **Rate limits** | All endpoints under load | Verify rate limit behavior + headers | Valid token | Send burst of requests; check for 429 responses and rate-limit headers | Document limits, retry-after headers | None | Mainnet API key | Low |
| 30 | **Webhook/callback** | Transfer completion events | Verify if webhooks/callbacks exist | Transfer in progress + callback URL | Create transfer with callback_url if supported | Callback received on completion | None | Mainnet API key + public endpoint | Med |

---

## Priority Order

**Phase 1 — Safe read-only (Low risk)**
Rows: 1, 2, 4, 6, 19, 26, 27, 28, 29

**Phase 2 — Non-destructive writes (Med risk)**
Rows: 3, 5, 7, 12, 13, 14, 15, 17, 20, 21, 22, 23, 24, 25

**Phase 3 — Real money movement (High risk)**
Rows: 8, 9, 10, 11, 16, 18, 30

---

## Precondition Checklist

Before executing any mainnet tests:

- [ ] Mainnet API credentials obtained (client_id + client_secret)
- [ ] Mainnet account exists and is in `complete` status
- [ ] Internal custodial addresses have non-zero balance for swap/payout tests
- [ ] External FI address registered for fiat offramp tests
- [ ] Plaid sandbox keys available for FI integration tests
- [ ] Tokenization scopes (`mints:write`, `redemptions:write`, `tokens:read`) granted
- [ ] Dedicated test bank account for ACH/wire tests (minimal balances)
- [ ] Callback/webhook endpoint deployed for event testing
- [ ] Idempotency-Key tracking system in place to prevent accidental duplicates

---

## Phase 4: Guide-Specific Mainnet Gaps (Added 2026-02-17)

These rows cover guide workflows that could not be verified on testnet. Each maps to a specific guide.

| # | Guide | Gap | Endpoint | Why Mainnet Required | Safe Test Method | Expected Result | Risk |
|---|-------|-----|----------|---------------------|-----------------|-----------------|------|
| 31 | fiat-to-stablecoin-onramp | Wire onramp end-to-end | POST /transfers (wire source) | Requires real wire deposit to virtual account | Create transfer, verify `wire_instructions`, send $1 wire | Transfer transitions pending→processing→complete | Med |
| 32 | fiat-to-stablecoin-onramp | ACH debit onramp | POST /transfers (ach_debit source) | Requires Plaid-linked bank + real ACH | Create Plaid link, initiate $1 ACH debit | Transfer completes, stablecoins minted | Med |
| 33 | stablecoin-to-fiat-offramp | Wire offramp | POST /transfers (wire destination) | Requires real bank account to receive funds | Send $1 from custodial to bank via wire | USD received in bank account | High |
| 34 | stablecoin-to-fiat-offramp | ACH credit offramp | POST /transfers (ach_credit destination) | Requires real bank account | Send $1 via ach_credit | ACH credit completes | Med |
| 35 | stablecoin-to-fiat-offramp | RTP credit offramp | POST /transfers (rtp_credit destination) | Requires RTP-enabled bank | Send $1 via rtp_credit | RTP settles in seconds | Med |
| 36 | 2nd-and-3rd-party-transfers | Branded ACH (2nd party) | POST /transfers with brand.account_id | ACH rails required | Create branded transfer ($1) | Receiver sees custom business name | Med |
| 37 | 2nd-and-3rd-party-transfers | Branded ACH (3rd party) | POST /transfers with brand.account_id | ACH rails required | Create 3rd-party branded transfer ($1) | Receiver sees customer's business name | Med |
| 38 | stablecoin-to-stablecoin-swap | Cross-chain swap (funded) | POST /transfers (solana→base) | Testnet chains have $0 balance | Fund testnet chains via tokenization OR run on mainnet | Transfer completes, burn on source + mint on dest | Med |
| 39 | stablecoin-payouts | Onchain payout (funded) | POST /transfers (internal→external) | Testnet chains have $0 balance | Fund testnet chains via tokenization OR run on mainnet | Transfer completes, on-chain tx visible | Med |
| 40 | tokenization | Mint tokens | POST /tokens/mints | Requires mints:write scope | Mint 1 unit to custodial address | Token balance increases | Low |
| 41 | tokenization | Burn tokens | POST /tokens/burns | Requires redemptions:write scope | Burn 1 unit from custodial address | Token balance decreases | Low |

### Testnet Transfer Limitation Discovery

On testnet, `POST /transfers` returns **403 "Network not supported"** for mainnet chain names (`solana`, `base`, `polygon`). Testnet chain names (`solana_devnet`, `base_sepolia`, `canton_testnet`) are accepted but most have $0 balance. The only funded testnet chain was `canton_testnet` ($50,003 SBC from prior mints).

**Implication**: To fully test transfer flows on testnet, you need:
1. Tokenization scopes to mint tokens on testnet chains, OR
2. Use mainnet with minimal amounts

### Mitigation

The guide verification harness (`scripts/guides-verify-testnet.sh`) validates:
- API shape correctness (correct error codes for invalid requests)
- Read endpoints (accounts, addresses, balances, automations, FIs)
- Address creation (external onchain addresses)
- Scope restrictions (tokenization returns 403 correctly)

What remains untestable without mainnet or tokenization scopes:
- Transfer creation and completion
- Fiat rail flows (wire, ACH, RTP)
- Branded ACH transfers
