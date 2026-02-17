# Brale API Documentation

Source for the [Brale](https://brale.xyz) public developer documentation.

**Live docs**: [docs.brale.xyz](https://docs.brale.xyz)

---

## What Brale does

Brale is infrastructure for stablecoin issuance and movement. The API lets you:

- **Issue** your own branded stablecoin across supported chains
- **Onramp** fiat to stablecoin (USD → USDC, SBC, etc.)
- **Offramp** stablecoin to fiat via ACH or wire
- **Swap** between stablecoins or chains
- **Send payouts** to external wallets or bank accounts
- **Manage accounts** for end customers with built-in KYB and compliance

## Quick links

| Resource | URL |
|----------|-----|
| Live documentation | [docs.brale.xyz](https://docs.brale.xyz) |
| Dashboard & API keys | [app.brale.xyz](https://app.brale.xyz) |
| API status | [status.brale.xyz](https://status.brale.xyz) |
| OpenAPI spec | [api.brale.xyz/openapi](https://api.brale.xyz/openapi) |
| Stablecoin Data API | [data.brale.xyz](https://data.brale.xyz) |

## Repo structure

```
├── api-reference/       # API intro + endpoint pages (auto-generated from OpenAPI)
│   └── brale/           # One MDX file per endpoint
├── guides/              # Step-by-step workflows (onramp, offramp, swap, payout, tokenization)
├── key-concepts/        # Core objects: accounts, addresses, transfers, automations, FIs
├── overview/            # Quick start, sandbox/testnet setup
├── coverage/            # Supported transfer_types, value_types, and chains
├── documentation/       # Platform overview, API design, Data API reference
└── docs.json            # Mintlify site configuration and navigation
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Short version: fork, branch, make your changes, preview locally, open a PR.

### Local preview

Requires Node.js v22 (LTS):

```bash
npm i -g mintlify
mintlify dev
```

Preview at `http://localhost:3000`.

## Deploying

Pushes to `main` auto-deploy to the live docs site via the Mintlify GitHub integration. No build step required.

## Security

This repo should never contain API keys, secrets, tokens, or internal credentials. If you find sensitive information in this repo, please report it immediately to [security@brale.xyz](mailto:security@brale.xyz).

## Support

- **Implementation help**: [app.brale.xyz](https://app.brale.xyz) — request a shared Slack or Telegram channel
- **API issues**: [support@brale.xyz](mailto:support@brale.xyz)
- **Documentation bugs**: [Open an issue](../../issues)

## License

[MIT](LICENSE)
