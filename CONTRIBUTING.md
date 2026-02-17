# Contributing to Brale Docs

Thanks for helping improve Brale's developer documentation.

## How to contribute

1. Fork this repo
2. Create a branch (`git checkout -b fix/my-change`)
3. Make your changes
4. Preview locally with `mintlify dev` (requires Node.js v22)
5. Open a pull request against `main`

## Style guide

- **Clear and concise**: Write for developers who are building against the API right now.
- **Runnable examples**: Every curl example should be copy/paste ready with placeholder variables like `${ACCESS_TOKEN}` and `${ACCOUNT_ID}`.
- **Correct terminology**: Use `value_type` and `transfer_type` exactly (snake_case, never camelCase). These are core Brale primitives — do not rename, paraphrase, or invert them.
- **No marketing**: State what the API does, not why it's great.
- **Link, don't repeat**: If another page covers a concept, link to it.

## No sensitive information

Do not include in any commit:

- API keys, client secrets, or bearer tokens
- Real account IDs, addresses, or transaction IDs
- Internal URLs, Slack links, or Notion pages
- Test credentials or environment-specific configuration

Use placeholder values (e.g., `${ACCOUNT_ID}`, `ory_at_...`) in all examples.

## Reporting issues

- **Documentation bugs**: [Open an issue](../../issues) describing what's wrong and where.
- **Security concerns**: Email [security@brale.xyz](mailto:security@brale.xyz). Do not open a public issue for security vulnerabilities.

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
