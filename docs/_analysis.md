# Brale Docs — Repo Analysis

> Generated: 2026-02-16  
> Source: https://github.com/Brale-xyz/docs (87 commits, `main` branch)

---

## 1. What This Repo Is

This repository **is** the production documentation site for Brale's stablecoin issuance and orchestration API. It is a Mintlify-powered doc site (MDX + `docs.json` config) — there is no application code, SDK, or CLI here. The actual API lives at `api.brale.xyz`; an OpenAPI 3.0.3 spec (`brale-openapi.yaml`) is bundled in-repo and also served live from `https://api.brale.xyz/openapi`. The docs are deployed automatically via Mintlify's GitHub integration.

---

## 2. Who It's For (Personas)

| Persona | Goal | Entry point |
|---------|------|-------------|
| **Platform developer** | Integrate Brale API for stablecoin on/off-ramps, payouts, swaps | Quick Start → Transfers → Guides |
| **Stablecoin issuer** | Launch a branded, fiat-backed stablecoin on 14+ chains | Stablecoin Issuance guide → Dashboard |
| **Tokenization developer** | Issue non-fiat-backed tokens (points, local currency) using Brale infra | Tokenization guide → Mint/Burn endpoints |
| **Fintech product manager** | Evaluate Brale's coverage, rails, and compliance posture | Company Overview → Coverage → Reserves |
| **Ops / compliance engineer** | Set up production accounts, KYB flows, reconciliation | Accounts → Troubleshooting → Managed Accounts |

---

## 3. What Problems It Solves

- **Stablecoin issuance**: Create branded stablecoins backed by Brale-managed reserves (USD, MXN), natively issued on 14+ chains.
- **Fiat on-ramp**: Convert USD → stablecoin via wire, ACH debit, or automated virtual accounts (Automations).
- **Fiat off-ramp**: Convert stablecoin → USD via wire, ACH credit, same-day ACH, or RTP.
- **Cross-chain / cross-token swaps**: 1:1 swaps between stablecoins and/or chains with no slippage.
- **Custodial wallets**: Managed wallets for end-customers with per-chain address auto-provisioning.
- **Payouts**: Send stablecoins or fiat to external wallets and bank accounts programmatically.
- **Plaid integration**: Bank account linking for ACH debit flows.
- **Tokenization**: Mint/burn/transfer self-attested tokens where Brale handles custody and on-chain execution but not reserves.

---

## 4. Glossary of Key Concepts

| Term | Definition | Where documented |
|------|-----------|-----------------|
| **Account** (`account_id`) | A KYB'd business entity. All resources are scoped to an account. IDs are KSUIDs (26-char, time-sortable). | `key-concepts/accounts.mdx` |
| **Address** (`address_id`) | Universal source/destination primitive — represents both on-chain wallets and off-chain bank accounts. `type=internal` = Brale-custodied; `type=external` = counterparty. | `key-concepts/addresses.mdx` |
| **Transfer** | Movement of value between addresses. Always has `source` + `destination`, each with `value_type` + `transfer_type` + optional `address_id`. | `key-concepts/transfers.mdx` |
| **Automation** (`automation_id`) | Virtual bank account that auto-mints stablecoins when funds arrive. Provides unique routing/account numbers. | `key-concepts/automations.mdx` |
| **Financial Institution** (legacy) | Deprecated predecessor to off-chain Addresses. Existing integrations still work. | `key-concepts/financial-institutions.mdx` |
| **`value_type`** | Token/fiat identifier (case-sensitive). Examples: `SBC`, `USDC`, `USD`, `MXNe`. | `coverage/value-types.mdx` |
| **`transfer_type`** | Payment rail or chain identifier. Examples: `wire`, `ach_credit`, `base`, `solana`, `canton`. | `coverage/transfer-types.mdx` |
| **KSUID** | K-Sortable Unique Identifier — 26 alphanumeric characters, time-sortable. Used for all resource IDs. | `api-reference/brale-openapi.yaml` (schema) |
| **Idempotency-Key** | UUID header required on all POST (create) requests. Prevents duplicate operations on retry. | `key-concepts/idempotency.mdx` |
| **KYB** | Know Your Business — compliance onboarding required before API access. | `key-concepts/accounts.mdx` |
| **Testnet** | Non-production environment. Uses testnet chains (Sepolia, Solana Devnet, etc.). Fiat legs are skipped. | `overview/sandbox-and-testnet.mdx` |
| **Brand** | Optional ACH-only object to control which business name appears on bank statements. | `key-concepts/transfers.mdx`, `guides/2nd-and-3rd-party-transfers.mdx` |
| **IO (Brale IO)** | Consumer-facing web app for individual stablecoin purchases at `brale.io`. | `io/introduction.mdx` |
| **Commons** | Open-source repo with shared resources: Commons Stablecoin Format (CSF), token lists, OpenAPI spec. | `documentation/commons-repo.mdx` |

---

## 5. High-Level Architecture (User-Facing)

```
┌──────────────────────────────────────────────────────────┐
│                     Your Application                      │
│  (Platform, Fintech, Wallet, Marketplace)                │
└───────────────────────┬──────────────────────────────────┘
                        │ HTTPS (OAuth2 Bearer)
                        ▼
┌──────────────────────────────────────────────────────────┐
│                  api.brale.xyz (REST)                     │
│                                                          │
│  ┌──────────┐  ┌───────────┐  ┌──────────┐  ┌────────┐ │
│  │ Accounts │  │ Addresses │  │Transfers │  │Automate│ │
│  │  (KYB)   │  │ int / ext │  │ on/off/  │  │ virtual│ │
│  │          │  │           │  │ swap/pay │  │  accts │ │
│  └──────────┘  └───────────┘  └──────────┘  └────────┘ │
│                                                          │
│  ┌──────────────────────────────────────────────────┐   │
│  │              Plaid (bank linking)                 │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
         │                    │                    │
         ▼                    ▼                    ▼
  ┌─────────────┐   ┌──────────────┐    ┌──────────────────┐
  │ Fiat Rails  │   │  Blockchains │    │ data.brale.xyz   │
  │ Wire, ACH,  │   │  EVM, Solana │    │ (public metadata │
  │ RTP         │   │  Stellar,    │    │  & price feeds)  │
  │             │   │  Canton, XRP │    │                  │
  └─────────────┘   └──────────────┘    └──────────────────┘
```

**Auth flow**: `auth.brale.xyz/oauth2/token` → Bearer token (~60 min TTL) → All `api.brale.xyz` calls.

**Core loop**: Authenticate → Get `account_id` → Get `address_id` (internal) → POST Transfer → Poll status.

---

## 6. Current Doc Site Structure (as defined in `docs.json`)

| Tab | Content |
|-----|---------|
| **Information** | Introduction, Troubleshooting, API Design (Primitives, Structure), Platform (Company, Issuance, Orchestration, Interoperability, Tokenization, Reserves), Coverage (Transfer Types, Value Types) |
| **Tools** | Commons (CSF, Add Stablecoin, Commons Repo), Calculators, IO (Introduction, URL Navigation) |
| **API Docs** | Overview (Introduction, Quick Start, Testnet), Key Concepts (Overview, Auth, Transfers, Accounts, Addresses, Automations, FIs, Idempotency) |
| **Guides** | How-to (Get Account ID, Get Address IDs, Create Managed Account, Get Balance, Add External Destination, Untitled Page), Workflows (Onramp, Offramp, Swap, Issuance, Payouts, 2nd/3rd Party, Managed Accounts, Canton, Tokenization) |
| **API Reference** | Brale Introduction + 17 OpenAPI-powered endpoint pages |

---

## 7. Issues Found

### 7.1 Leftover Mintlify Template Content (should be removed)

| File | Problem |
|------|---------|
| `api-reference/openapi.json` | **Plant Store API** — Mintlify starter kit leftover, not Brale content |
| `api-reference/endpoint/create.mdx` | Plant Store "Create Plant" endpoint |
| `api-reference/endpoint/get.mdx` | Plant Store "Get Plants" endpoint |
| `api-reference/endpoint/delete.mdx` | Plant Store "Delete Plant" endpoint |
| `api-reference/endpoint/webhook.mdx` | Plant Store "New Plant" webhook |
| `api-reference/introduction.mdx` | References "Plant Store Endpoints" |
| `essentials/` folder (6 files) | Generic Mintlify essentials (not in nav, but cluttering repo) |
| `snippets/snippet-intro.mdx` | Generic DRY principle snippet (not Brale-specific) |

### 7.2 Stub / Empty Pages (in nav, no content)

| File | Title | Issue |
|------|-------|-------|
| `documentation/platform/interoperability.mdx` | "Interoperability" | Body is literally `sdf` (placeholder). Has `hidden: true` but exists in nav config. |
| `guides/how-to/create-a-managed-account.mdx` | "Create A Managed Account" | Title only, no content body |
| `guides/how-to/untitled-page.mdx` | "Create a Custodial Wallet" | Title only, no content body. Listed in nav as `untitled-page` |

### 7.3 Duplicate Content

| Item | Files | Notes |
|------|-------|-------|
| Transfer Types coverage | `coverage/transfer-types.mdx` vs `docs/coverage/transfer-types.mdx` | The `docs/` version has **more chains** (Cosmos/IBC, Coreum, Ethereum Classic, Vechain, Xion) — unclear which is canonical |
| Quick Start | `overview/quick-start.mdx` (in nav) vs `quickstart.mdx` (root, not in nav) | Root version is prose-style; `overview/` version uses `<Steps>` component. Both contain overlapping content. |
| Calculators | `documentation/calculators.mdx` vs `tools/calculators/stablecoin-calculators.mdx` | Identical calculator cards; `tools/` version is in nav |

### 7.4 Incorrect / Inconsistent Code Examples

| File | Problem | Impact |
|------|---------|--------|
| `guides/stablecoin-payouts.mdx` (USDC Payout example) | Uses **camelCase** (`addressId`, `valueType`, `transferType`) instead of snake_case | **Will fail against the API** — API uses `address_id`, `value_type`, `transfer_type` |
| `guides/stablecoin-payouts.mdx` (USDC Payout) | URL path is `/transfer` (singular) instead of `/transfers` | **Wrong endpoint path** |
| `guides/stablecoin-to-stablecoin-swap.mdx` (2nd example) | Uses camelCase (`sourceAddress`, `destinationAddress`, `addressId`, `valueType`, `transferType`) | **Will fail against the API** |
| `guides/stablecoin-to-fiat-offramp.mdx` | Missing comma after `transfer_types` array in JSON | **Invalid JSON** — will fail if copy-pasted |
| Various guides | Inconsistent capitalization of `transfer_type` values: `Polygon`, `Solana`, `Canton` vs `polygon`, `solana`, `canton` | API is case-sensitive per OpenAPI; lowercase is canonical |
| `key-concepts/transfers.mdx` (ACH Debit section) | Example labeled "USD to Stablecoin (ACH Debit)" but the JSON body shows a **stablecoin-to-wire offramp** (source is SBC/polygon, destination is USD/wire) | **Misleading** — example doesn't match section title |

### 7.5 IO URL Navigation — Inverted Descriptions

In `io/url-navigation.mdx`:
- Says `transfer_type` is "the stablecoin you wish to fund"
- Says `value_type` is "the chain you want to execute the transfer on"

**This is backwards.** In the Brale API, `transfer_type` = chain/rail and `value_type` = token/currency. The example URL (`?transfer_type=usdglo&value_type=polygon`) confirms the inversion — `usdglo` is a value_type and `polygon` is a transfer_type.

### 7.6 Broken / Incorrect Links

| Source | Link | Problem |
|--------|------|---------|
| `index.mdx` | `/coverage/stablecoins-and-blockchains` | **404** — page doesn't exist; should be `/coverage/transfer-types` or `/coverage/value-types` |
| `guides/managed-accounts.mdx` | `/api/get-address-balance`, `/api/list-addresses`, `/api/create-transfer`, `/api/create-account` | **Wrong paths** — should be `/api-reference/brale/get-address-balance` etc. |
| `guides/how-to/add-external-destination.mdx` | `/docs/coverage/transfer-types` | Points to secondary copy, not the canonical `coverage/transfer-types` |
| `documentation/platform/stablecoin-issuance.mdx` | `/docs/coverage/transfer-types` | Same issue |

### 7.7 Missing Documentation

| Gap | Severity | Notes |
|-----|----------|-------|
| **Webhooks / Events** | High | Plaid re-auth webhook is mentioned in Addresses but there's no dedicated webhooks page. No documentation of transfer status change callbacks. |
| **Rate limits** | High | No mention anywhere. Developers need this for production. |
| **Error code reference** | High | Errors are scattered across pages. No consolidated error reference. |
| **PATCH /addresses endpoint** | Medium | Documented in `addresses.mdx` but **not in the OpenAPI spec** |
| **Tokenization endpoints** | Medium | `POST /tokens/mints`, `POST /tokens/burns`, `POST /tokens/transfers`, `GET /tokens/transactions` — documented in guide but **not in OpenAPI** |
| **`data.brale.xyz` API** | **Done** | Public API verified working with 8 endpoints. Dedicated reference page created at `documentation/data-api.mdx`. |
| **Update link token endpoint** | Medium | `POST /addresses/{address_id}/update-link-token` — documented in Addresses but not in OpenAPI |
| **SDK / client library** | Low | No official SDK exists. Could document code generation from OpenAPI. |
| **`failed` transfer status** | Low | Says "Manual intervention may be required" with no guidance on what to do |
| **MXN (Mexican Peso) flows** | Low | `MXNe` value_type exists, SPEI is mentioned nowhere despite MXN support |

### 7.8 OpenAPI Spec Gaps

The bundled `brale-openapi.yaml` (v2.3.1) is missing:
- `PATCH /accounts/{account_id}/addresses/{address_id}` (update address transfer_types)
- `POST /accounts/{account_id}/addresses/{address_id}/update-link-token` (Plaid re-auth)
- `GET /accounts/{account_id}/addresses/{address_id}` (get single address)
- All tokenization endpoints (`/tokens/mints`, `/tokens/burns`, `/tokens/transfers`, `/tokens/transactions`)
- `GET /tokens` endpoint (referenced but not specified)
- Transfer `failed` status is missing from the Transfer schema enum (only `pending`, `processing`, `complete`, `canceled`)

---

## 8. Proposed Docs Information Architecture

Below is a recommended restructuring organized around **user journeys** rather than internal architecture:

```
docs.json navigation (proposed)
├── Get Started
│   ├── What is Brale?                    (overview/introduction.mdx — rewrite)
│   ├── Quick Start: Your First Transfer  (overview/quick-start.mdx)
│   ├── Testnet & Sandbox                 (overview/sandbox-and-testnet.mdx)
│   └── Authentication                    (key-concepts/authentication.mdx)
│
├── Core Concepts
│   ├── API Concepts Overview             (key-concepts/api-concepts-overview.mdx)
│   ├── Accounts                          (key-concepts/accounts.mdx)
│   ├── Addresses                         (key-concepts/addresses.mdx)
│   ├── Transfers                         (key-concepts/transfers.mdx)
│   ├── Automations                       (key-concepts/automations.mdx)
│   ├── Idempotency                       (key-concepts/idempotency.mdx)
│   └── Coverage
│       ├── Transfer Types                (coverage/transfer-types.mdx)
│       └── Value Types                   (coverage/value-types.mdx)
│
├── Guides
│   ├── How-To
│   │   ├── Get Your Account ID           (guides/how-to/get-your-account-id.mdx)
│   │   ├── Get Your Address IDs          (guides/how-to/get-your-address-ids.mdx)
│   │   ├── Add External Destination      (guides/how-to/add-external-destination.mdx)
│   │   ├── Get a Balance                 (guides/how-to/get-a-balance.mdx)
│   │   └── Create a Managed Account      (NEW — fill stub)
│   │
│   ├── Workflows
│   │   ├── Fiat → Stablecoin (Onramp)    (guides/fiat-to-stablecoin-onramp.mdx)
│   │   ├── Stablecoin → Fiat (Offramp)   (guides/stablecoin-to-fiat-offramp.mdx)
│   │   ├── Stablecoin Swap               (guides/stablecoin-to-stablecoin-swap.mdx)
│   │   ├── Stablecoin Payouts            (guides/stablecoin-payouts.mdx)
│   │   ├── 2nd & 3rd Party Transfers     (guides/2nd-and-3rd-party-transfers.mdx)
│   │   ├── Managed Accounts (Custody)    (guides/managed-accounts.mdx)
│   │   └── Canton Token Standard         (guides/canton-token-standard.mdx)
│   │
│   └── Advanced
│       ├── Stablecoin Issuance           (guides/stablecoin-issuance.mdx)
│       └── Tokenization                  (guides/tokenization.mdx)
│
├── API Reference                         (OpenAPI-powered, 17 endpoints)
│   ├── Introduction                      (api-reference/brale-introduction.mdx)
│   ├── Accounts (3 endpoints)
│   ├── Addresses (3 endpoints)
│   ├── Transfers (3 endpoints)
│   ├── Automations (3 endpoints)
│   ├── Plaid (2 endpoints)
│   └── Financial Institutions (3, deprecated)
│
├── Platform
│   ├── Company Overview                  (documentation/platform/company-overview.mdx)
│   ├── Stablecoin Issuance               (documentation/platform/stablecoin-issuance.mdx)
│   ├── Stablecoin Orchestration          (documentation/platform/stablecoin-orchestration.mdx)
│   ├── Tokenization                      (documentation/platform/tokenization.mdx)
│   └── Reserves                          (documentation/platform/reserves.mdx)
│
├── Tools
│   ├── Commons & CSF                     (documentation/commons-stablecoin-format.mdx)
│   ├── Calculators                       (tools/calculators/stablecoin-calculators.mdx)
│   ├── Brale IO                          (io/introduction.mdx)
│   └── AI Tool Setup (Cursor, Claude, Windsurf)
│
└── Troubleshooting & Reference
    ├── Troubleshooting                   (documentation/troubleshooting.mdx)
    ├── Error Reference                   (NEW — consolidate scattered errors)
    └── API Design (Primitives, Structure)
```

### Files to DELETE

| File | Reason |
|------|--------|
| `api-reference/openapi.json` | Plant Store (Mintlify starter leftover) |
| `api-reference/endpoint/create.mdx` | Plant Store |
| `api-reference/endpoint/get.mdx` | Plant Store |
| `api-reference/endpoint/delete.mdx` | Plant Store |
| `api-reference/endpoint/webhook.mdx` | Plant Store |
| `api-reference/introduction.mdx` | Plant Store reference |
| `essentials/settings.mdx` | Mintlify starter template |
| `essentials/markdown.mdx` | Mintlify starter template |
| `essentials/code.mdx` | Mintlify starter template |
| `essentials/navigation.mdx` | Mintlify starter template |
| `essentials/images.mdx` | Mintlify starter template |
| `essentials/reusable-snippets.mdx` | Mintlify starter template |
| `quickstart.mdx` (root) | Duplicate of `overview/quick-start.mdx` |
| `documentation/calculators.mdx` | Duplicate of `tools/calculators/stablecoin-calculators.mdx` |
| `docs/coverage/transfer-types.mdx` | Merge unique content into `coverage/transfer-types.mdx`, then delete |
| `guides/how-to/untitled-page.mdx` | Empty stub with bad name |
| `documentation/platform/interoperability.mdx` | Body is `sdf` (placeholder); has `hidden: true` |

---

## 9. Priority Fixes (Before New Content)

### P0 — Blocks users / causes failures

1. **Fix camelCase code examples** in `guides/stablecoin-payouts.mdx` and `guides/stablecoin-to-stablecoin-swap.mdx` — these will fail if copy-pasted.
2. **Fix invalid JSON** in `guides/stablecoin-to-fiat-offramp.mdx` (missing comma).
3. **Fix wrong endpoint path** in `guides/stablecoin-payouts.mdx` (`/transfer` → `/transfers`).
4. **Fix misleading example** in `key-concepts/transfers.mdx` ACH Debit section (example body is an offramp, not an ACH debit onramp).
5. **Fix broken link** on `index.mdx` homepage (`/coverage/stablecoins-and-blockchains` → valid path).

### P1 — Confusing / misleading

6. **Fix inverted IO param descriptions** in `io/url-navigation.mdx`.
7. **Fix broken links** in `guides/managed-accounts.mdx` (wrong API reference paths).
8. **Normalize `transfer_type` casing** across all guides — use lowercase consistently.
9. **Remove Mintlify template files** (Plant Store, essentials).
10. **Merge duplicate transfer-types coverage** pages.

### P2 — Missing content

11. **Fill stub pages** (`create-a-managed-account.mdx`) or remove from nav.
12. **Create consolidated error reference page**.
13. **Document rate limits** (even if the answer is "contact support").
14. **Add PATCH /addresses and tokenization endpoints to OpenAPI spec**.
15. **Create webhooks documentation page**.

---

## 10. What's Working Well

- **Quick Start** (`overview/quick-start.mdx`) is genuinely good — copy-paste `curl` commands, real IDs, clear progression.
- **Key Concepts** section is thorough and well-organized (Transfers, Addresses, Accounts, Automations, Idempotency).
- **OpenAPI spec** (`brale-openapi.yaml`) is well-structured with examples and covers core CRUD flows.
- **Coverage pages** (value types, transfer types) are canonical and well-sourced from Commons JSON.
- **Troubleshooting page** is practical and covers the real errors developers hit.
- **Plaid integration docs** in Addresses are detailed end-to-end.
- **Canton Token Standard** guide is impressively detailed for an advanced use case.
- **AI tool setup pages** (Cursor, Claude Code, Windsurf) show good developer empathy.
- **docs.json** references the live OpenAPI at `https://api.brale.xyz/openapi`, ensuring endpoint pages stay current.
