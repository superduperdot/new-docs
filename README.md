# Brale API Documentation

Developer documentation for the [Brale](https://brale.xyz) stablecoin issuance and orchestration platform.

**Live docs**: [brale.mintlify.app](https://brale.mintlify.app) · **API base**: `https://api.brale.xyz` · **Auth**: `https://auth.brale.xyz`

---

## What Brale does

Brale is infrastructure for stablecoin issuance and movement. The API lets you:

- **Issue** your own branded stablecoin across supported chains
- **Onramp** fiat to stablecoin (USD → USDC, SBC, etc.)
- **Offramp** stablecoin to fiat (stablecoin → USD via ACH or wire)
- **Swap** between stablecoins or chains
- **Send payouts** to external wallets or bank accounts
- **Manage accounts** for your end customers (KYB, custody, compliance)

## Quick links

| Resource | URL |
|----------|-----|
| Live documentation | [brale.mintlify.app](https://brale.mintlify.app) |
| Dashboard & API keys | [app.brale.xyz](https://app.brale.xyz) |
| API status | [status.brale.xyz](https://status.brale.xyz) |
| OpenAPI spec | [api.brale.xyz/openapi](https://api.brale.xyz/openapi) |
| Stablecoin Data API | [data.brale.xyz](https://data.brale.xyz) |

## Repo structure

```
├── api-reference/       # API intro + auto-generated endpoint pages (33 endpoints)
│   └── brale/           # One MDX file per endpoint, powered by OpenAPI
├── guides/              # Step-by-step workflows (onramp, offramp, swap, payout, tokenization)
├── key-concepts/        # Core objects: accounts, addresses, transfers, automations, FIs
├── overview/            # Quick start, sandbox/testnet setup
├── coverage/            # Supported transfer_types, value_types, and chains
├── documentation/       # Platform overview, API design, Data API reference
└── docs.json            # Mintlify site configuration and navigation
```

## API reference architecture

Endpoint pages are auto-generated from the production OpenAPI spec:

```json
"openapi": "https://api.brale.xyz/openapi"
```

Each file in `api-reference/brale/` is a thin MDX stub with an `openapi:` frontmatter directive. Mintlify expands it into a full interactive playground with request builder, response viewer, and schema details. There are 33 endpoint pages covering all 26 production API paths.

## Key conventions

Anyone contributing to these docs should know:

- **`value_type` and `transfer_type`** are sacred Brale primitives. Always `snake_case`. Never camelCase, never renamed, never inverted. `value_type` = what moves. `transfer_type` = how it moves.
- **Accept header**: Do NOT send `Accept: application/json` — it triggers HTTP 500 via the CDN layer. Omit the header entirely or use `Accept: */*`.
- **Environment**: Testnet and mainnet share the same base URL (`api.brale.xyz`). Your API credentials determine the environment, not the URL.
- **Idempotency**: All `POST` and `PATCH` requests require an `Idempotency-Key` header.
- **IDs**: All resource IDs are KSUIDs (26-character, alphanumeric, time-sortable).

## Deploying

Pushes to `main` auto-deploy to the live Mintlify site via the [Mintlify GitHub app](https://dashboard.mintlify.com). No build step, no CI — merge and it's live.

## Contributing

1. Create a branch off `main`
2. Make your changes
3. Preview locally with `mintlify dev` (requires Node.js v22)
4. Open a PR

If you're documenting new API behavior, test against the live API first. Do not invent example payloads.

## Support

- **Implementation help**: Reach out via [app.brale.xyz](https://app.brale.xyz) to set up a shared Slack or Telegram channel
- **API issues**: Email [support@brale.xyz](mailto:support@brale.xyz)
- **Documentation bugs**: Open an issue in this repo

## License

This project is licensed under the [MIT License](LICENSE).
