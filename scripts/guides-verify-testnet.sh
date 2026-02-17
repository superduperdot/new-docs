#!/usr/bin/env bash
# guides-verify-testnet.sh — Testnet verification for all guides
# Requires: BRALE_CLIENT_ID and BRALE_CLIENT_SECRET env vars
# Usage: BRALE_CLIENT_ID=xxx BRALE_CLIENT_SECRET=yyy bash scripts/guides-verify-testnet.sh
set -euo pipefail

BASE="https://api.brale.xyz"
AUTH="https://auth.brale.xyz"
PASS=0
FAIL=0
SKIP=0
TOTAL=0
ARTIFACTS_DIR="artifacts"
mkdir -p "$ARTIFACTS_DIR"

red()    { printf '\033[0;31mFAIL\033[0m %s\n' "$1"; }
green()  { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }
yellow() { printf '\033[0;33mSKIP\033[0m %s\n' "$1"; }

if [ -z "${BRALE_CLIENT_ID:-}" ] || [ -z "${BRALE_CLIENT_SECRET:-}" ]; then
  echo "Error: Set BRALE_CLIENT_ID and BRALE_CLIENT_SECRET environment variables"
  exit 1
fi

echo "=== Brale Guides Testnet Verification ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

run_test() {
  local label="$1"
  local expected_code="$2"
  local method="$3"
  local url="$4"
  shift 4
  TOTAL=$((TOTAL + 1))
  local ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -X "$method" "$url" \
    -H "Authorization: Bearer $TOKEN" "$@" 2>&1)
  if [ "$code" = "$expected_code" ]; then
    green "[$ts] $label — HTTP $code"
    PASS=$((PASS + 1))
  else
    red "[$ts] $label — HTTP $code (expected $expected_code)"
    FAIL=$((FAIL + 1))
  fi
}

skip_test() {
  local label="$1"
  local reason="$2"
  TOTAL=$((TOTAL + 1))
  SKIP=$((SKIP + 1))
  yellow "$(date -u +%Y-%m-%dT%H:%M:%SZ) $label — $reason"
}

# --------------------------------------------------------------------------
# Authenticate
# --------------------------------------------------------------------------
echo "--- Authenticating ---"
AUTH_RESP=$(curl -s -X POST "$AUTH/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$BRALE_CLIENT_ID:$BRALE_CLIENT_SECRET" \
  -d "grant_type=client_credentials")
TOKEN=$(echo "$AUTH_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
PASS=$((PASS + 1)); TOTAL=$((TOTAL + 1))
green "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Auth — token acquired"

# Discover resources
ACCT=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE/accounts" | python3 -c "import sys,json; print(json.load(sys.stdin)['accounts'][0]['id'])")
echo "  Account: $ACCT"

SOLANA_INT=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE/accounts/$ACCT/addresses" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for a in data['addresses']:
    if a['type'] == 'internal' and a['status'] == 'active' and 'solana' in a.get('transfer_types', []):
        print(a['id']); break
")
echo "  Solana internal: $SOLANA_INT"

AUTOMATION_ID=$(curl -s -H "Authorization: Bearer $TOKEN" "$BASE/accounts/$ACCT/automations" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data['automations']: print(data['automations'][0]['id'])
else: print('')
")
echo "  Automation: $AUTOMATION_ID"
echo ""

# --------------------------------------------------------------------------
# Guide: get-your-account-id
# --------------------------------------------------------------------------
echo "--- Guide: get-your-account-id ---"
run_test "GET /accounts" "200" GET "$BASE/accounts"

# --------------------------------------------------------------------------
# Guide: get-your-address-ids
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: get-your-address-ids ---"
run_test "GET /accounts/{id}/addresses" "200" GET "$BASE/accounts/$ACCT/addresses"

# --------------------------------------------------------------------------
# Guide: get-a-balance
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: get-a-balance ---"
run_test "GET /balance (solana/SBC)" "200" GET "$BASE/accounts/$ACCT/addresses/$SOLANA_INT/balance?transfer_type=solana&value_type=SBC"

# --------------------------------------------------------------------------
# Guide: add-external-destination
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: add-external-destination ---"
run_test "POST /addresses/external (onchain)" "201" POST "$BASE/accounts/$ACCT/addresses/external" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: guides-verify-ext-$(date +%s)" \
  -d '{"name":"Guide Test Wallet","address":"9xKXtg2CW87d97TXJSDpbD5jBkheTqA83TZRuJosgAsU","transfer_types":["solana"]}'

# --------------------------------------------------------------------------
# Guide: stablecoin-to-stablecoin-swap
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: stablecoin-to-stablecoin-swap ---"
skip_test "POST /transfers (cross-chain swap)" "Requires funded testnet chain — mainnet chains return 403 on testnet"
run_test "Transfer API validates request shape (422 on empty)" "422" POST "$BASE/accounts/$ACCT/transfers" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: guides-verify-swap-$(date +%s)" \
  -d '{}'

# --------------------------------------------------------------------------
# Guide: stablecoin-payouts
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: stablecoin-payouts ---"
skip_test "POST /transfers (onchain payout)" "Requires funded testnet chain balance"
run_test "Transfer API validates missing Idempotency-Key" "400" POST "$BASE/accounts/$ACCT/transfers" \
  -H "Content-Type: application/json" \
  -d '{"amount":{"value":"1","currency":"USD"}}'

# --------------------------------------------------------------------------
# Guide: fiat-to-stablecoin-onramp
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: fiat-to-stablecoin-onramp ---"
run_test "GET /automations (list)" "200" GET "$BASE/accounts/$ACCT/automations"
if [ -n "$AUTOMATION_ID" ]; then
  run_test "GET /automations/{id} (with funding_instructions)" "200" GET "$BASE/accounts/$ACCT/automations/$AUTOMATION_ID"
fi
skip_test "POST /transfers (wire onramp)" "MAINNET-ONLY: requires real wire deposit"
skip_test "POST /transfers (ACH debit onramp)" "MAINNET-ONLY: requires Plaid + real bank"

# --------------------------------------------------------------------------
# Guide: stablecoin-to-fiat-offramp
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: stablecoin-to-fiat-offramp ---"
run_test "GET /financial-institutions" "200" GET "$BASE/accounts/$ACCT/financial-institutions"
skip_test "POST /transfers (wire offramp)" "MAINNET-ONLY: requires real bank account"
skip_test "POST /transfers (ACH credit offramp)" "MAINNET-ONLY: requires real bank account"

# --------------------------------------------------------------------------
# Guide: 2nd-and-3rd-party-transfers
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: 2nd-and-3rd-party-transfers ---"
skip_test "POST /transfers (branded ACH)" "MAINNET-ONLY: ACH rails required"

# --------------------------------------------------------------------------
# Guide: tokenization
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: tokenization ---"
run_test "GET /tokens/mints (expect 403 — scope restricted)" "403" GET "$BASE/accounts/$ACCT/tokens/mints"

# --------------------------------------------------------------------------
# Guide: managed-accounts
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: managed-accounts ---"
run_test "GET /accounts (managed account list)" "200" GET "$BASE/accounts"

# --------------------------------------------------------------------------
# Guide: stablecoin-issuance
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: stablecoin-issuance ---"
skip_test "Stablecoin issuance" "Dashboard-only flow — not API-testable"

# --------------------------------------------------------------------------
# Guide: canton-token-standard
# --------------------------------------------------------------------------
echo ""
echo "--- Guide: canton-token-standard ---"
skip_test "Canton transfer acceptance" "Requires Canton Ledger API access — not Brale API"

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / $TOTAL"
echo "FAIL: $FAIL / $TOTAL"
echo "SKIP: $SKIP / $TOTAL"

# Write JSON artifact
python3 -c "
import json
print(json.dumps({
  'date': '$(date -u +%Y-%m-%dT%H:%M:%SZ)',
  'account': '$ACCT',
  'pass': $PASS,
  'fail': $FAIL,
  'skip': $SKIP,
  'total': $TOTAL
}, indent=2))
" > "$ARTIFACTS_DIR/guides-testnet-run.json"
echo "Artifact: $ARTIFACTS_DIR/guides-testnet-run.json"

if [ $FAIL -gt 0 ]; then
  red "Guides verification: $FAIL failures"
  exit 1
else
  green "All testable guides passed ($SKIP skipped — mainnet-only or scope-restricted)"
  exit 0
fi
