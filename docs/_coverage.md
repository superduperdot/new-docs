# API Coverage Report

Generated: 2026-02-17
Source: Production OpenAPI at `https://api.brale.xyz/openapi` (67,300 bytes)

## Summary

| Metric | Count |
|--------|-------|
| Total paths in production OpenAPI | 26 (unique) |
| Total operations (method + path) | 33 |
| Documented in guides/key-concepts | 10 paths |
| Previously undocumented | 16 paths |
| Now documented (reference level) | 26 paths |

## Full Path Coverage

| # | Path | Methods | Scope(s) | Doc Status |
|---|------|---------|----------|------------|
| 1 | `/accounts` | GET, POST | `accounts:read`, `accounts:write` | Documented (guides, key-concepts) |
| 2 | `/accounts/{account_id}` | GET | `accounts:read` | **NEW** — added to reference |
| 3 | `/accounts/{account_id}/addresses` | GET | `addresses:read` | Documented (guides, key-concepts) |
| 4 | `/accounts/{account_id}/addresses/external` | POST | `addresses:write` | Documented (guides) |
| 5 | `/accounts/{account_id}/addresses/{address_id}` | GET, PATCH | `addresses:read`, `addresses:write` | **NEW** — added to reference |
| 6 | `/accounts/{account_id}/addresses/{address_id}/balance` | GET | `addresses:read` | Documented (guides) |
| 7 | `/accounts/{account_id}/addresses/{address_id}/update-link-token` | POST | `financial-institutions:read` | **NEW** — added to reference |
| 8 | `/accounts/{account_id}/automations` | GET, POST | `automations:read`, `automations:write` | Documented (guides, key-concepts) |
| 9 | `/accounts/{account_id}/automations/{automation_id}` | GET | `automations:read` | **NEW** — added to reference |
| 10 | `/accounts/{account_id}/financial-institutions` | GET | `financial-institutions:read` | Documented (key-concepts) |
| 11 | `/accounts/{account_id}/financial-institutions/external` | POST | `financial-institutions:write` | **NEW** — added to reference |
| 12 | `/accounts/{account_id}/financial-institutions/plaid/link_token` | POST | `financial-institutions:write` | **NEW** — added to reference |
| 13 | `/accounts/{account_id}/financial-institutions/register-account` | POST | `financial-institutions:write` | **NEW** — added to reference |
| 14 | `/accounts/{account_id}/financial-institutions/{fi_id}` | GET | `financial-institutions:read` | **NEW** — added to reference |
| 15 | `/accounts/{account_id}/financial-institutions/{fi_id}/status` | GET | `financial-institutions:read` | **NEW** — added to reference |
| 16 | `/accounts/{account_id}/financial-institutions/{fi_id}/update-link-token` | POST | `financial-institutions:read` | **NEW** — added to reference |
| 17 | `/accounts/{account_id}/plaid/link_token` | POST | `financial-institutions:write` | **NEW** — added to reference |
| 18 | `/accounts/{account_id}/plaid/register-account` | POST | `financial-institutions:write` | **NEW** — added to reference |
| 19 | `/accounts/{account_id}/tokens/burns` | GET, POST | `self_attested_tokens:read`, `self_attested_tokens:burn` | Documented (guides/tokenization) |
| 20 | `/accounts/{account_id}/tokens/burns/{burn_id}` | GET | `self_attested_tokens:read` | **NEW** — added to reference |
| 21 | `/accounts/{account_id}/tokens/mints` | GET, POST | `self_attested_tokens:read`, `self_attested_tokens:mint` | Documented (guides/tokenization) |
| 22 | `/accounts/{account_id}/tokens/mints/{mint_id}` | GET | `self_attested_tokens:read` | **NEW** — added to reference |
| 23 | `/accounts/{account_id}/tokens/transfers` | GET, POST | `self_attested_tokens:read`, `self_attested_tokens:transfer` | **NEW** — added to reference |
| 24 | `/accounts/{account_id}/tokens/transfers/{transfer_id}` | GET | `self_attested_tokens:read` | **NEW** — added to reference |
| 25 | `/accounts/{account_id}/transfers` | GET, POST | `transfers:read`, `transfers:write` | Documented (guides, key-concepts) |
| 26 | `/accounts/{account_id}/transfers/{transfer_id}` | GET | `transfers:read` | **NEW** — added to reference |

## OAuth2 Scopes (from production OpenAPI)

| Scope | Description |
|-------|-------------|
| `accounts:read` | Read account details |
| `accounts:write` | Create managed accounts |
| `addresses:read` | Read address details |
| `addresses:write` | Create/update addresses |
| `automations:read` | Read automation details |
| `automations:write` | Create automations |
| `financial-institutions:read` | Read financial institution details |
| `financial-institutions:write` | Create/manage financial institutions and Plaid links |
| `transfers:read` | Read transfer/order details |
| `transfers:write` | Create transfers |
| `self_attested_tokens:read` | Read token details (tokenization accounts) |
| `self_attested_tokens:mint` | Mint attested tokens (tokenization accounts) |
| `self_attested_tokens:burn` | Burn attested tokens (tokenization accounts) |
| `self_attested_tokens:transfer` | Transfer attested tokens (tokenization accounts) |
| `mints:write` | Mint more of a specific token on chain |
| `redemptions:write` | Redeem/burn a particular token on a specific chain |
| `orders:read` | Read order details |
| `tokens:read` | Read token details |
