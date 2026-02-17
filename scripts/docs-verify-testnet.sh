#!/usr/bin/env bash
# docs-verify-testnet.sh — Testnet curl verification suite
# Requires: BRALE_CLIENT_ID and BRALE_CLIENT_SECRET env vars
# Run: BRALE_CLIENT_ID=xxx BRALE_CLIENT_SECRET=yyy bash scripts/docs-verify-testnet.sh
set -euo pipefail

BASE="https://api.brale.xyz"
AUTH="https://auth.brale.xyz"
PASS=0
FAIL=0
TOTAL=0

red()   { printf '\033[0;31mFAIL\033[0m %s\n' "$1"; }
green() { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }

# Check required env vars
if [ -z "${BRALE_CLIENT_ID:-}" ] || [ -z "${BRALE_CLIENT_SECRET:-}" ]; then
  echo "Error: Set BRALE_CLIENT_ID and BRALE_CLIENT_SECRET environment variables"
  exit 1
fi

echo "=== Brale Testnet Verification Suite ==="
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Base: $BASE"
echo ""

# --------------------------------------------------------------------------
# Helper: run test and check HTTP status
# --------------------------------------------------------------------------
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
    green "[$ts] $label — HTTP $code (expected $expected_code)"
    PASS=$((PASS + 1))
  else
    red "[$ts] $label — HTTP $code (expected $expected_code)"
    FAIL=$((FAIL + 1))
  fi
}

# --------------------------------------------------------------------------
# 1. Authenticate
# --------------------------------------------------------------------------
echo "--- Authenticating ---"
AUTH_RESP=$(curl -s -w "\n%{http_code}" -X POST "$AUTH/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$BRALE_CLIENT_ID:$BRALE_CLIENT_SECRET" \
  -d "grant_type=client_credentials")
AUTH_CODE=$(echo "$AUTH_RESP" | tail -1)
AUTH_BODY=$(echo "$AUTH_RESP" | sed '$d')

if [ "$AUTH_CODE" != "200" ]; then
  red "Authentication failed with HTTP $AUTH_CODE"
  echo "$AUTH_BODY"
  exit 1
fi

TOKEN=$(echo "$AUTH_BODY" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
green "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Auth — HTTP 200, token acquired"
PASS=$((PASS + 1))
TOTAL=$((TOTAL + 1))

# --------------------------------------------------------------------------
# 2. Discover account
# --------------------------------------------------------------------------
echo ""
echo "--- Discovering Account ---"
ACCT_RESP=$(curl -s "$BASE/accounts" -H "Authorization: Bearer $TOKEN")
ACCT=$(echo "$ACCT_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['accounts'][0]['id'])")
echo "  Account: $ACCT"

# --------------------------------------------------------------------------
# 3. GET endpoints (read-only)
# --------------------------------------------------------------------------
echo ""
echo "--- Read-Only Endpoint Tests ---"

run_test "GET /accounts" "200" GET "$BASE/accounts"
run_test "GET /accounts/{id}" "200" GET "$BASE/accounts/$ACCT"
run_test "GET /accounts/{id}/addresses" "200" GET "$BASE/accounts/$ACCT/addresses"
run_test "GET /accounts/{id}/transfers" "200" GET "$BASE/accounts/$ACCT/transfers"
run_test "GET /accounts/{id}/automations" "200" GET "$BASE/accounts/$ACCT/automations"
run_test "GET /accounts/{id}/financial-institutions" "200" GET "$BASE/accounts/$ACCT/financial-institutions"

# Discover first address for balance test
ADDR=$(echo "$ACCT_RESP" | python3 -c "
import sys, json, subprocess
resp = subprocess.run(['curl', '-s', '$BASE/accounts/$ACCT/addresses', '-H', 'Authorization: Bearer $TOKEN'], capture_output=True, text=True)
addrs = json.loads(resp.stdout)['addresses']
internal = [a for a in addrs if a['type'] == 'internal' and 'solana' in a.get('transfer_types', [])]
print(internal[0]['id'] if internal else addrs[0]['id'])
" 2>/dev/null || echo "")

if [ -n "$ADDR" ]; then
  run_test "GET /addresses/{id}" "200" GET "$BASE/accounts/$ACCT/addresses/$ADDR"
  run_test "GET /balance (solana/SBC)" "200" GET "$BASE/accounts/$ACCT/addresses/$ADDR/balance?transfer_type=solana&value_type=SBC"
fi

# --------------------------------------------------------------------------
# 4. Error shape tests
# --------------------------------------------------------------------------
echo ""
echo "--- Error Shape Tests ---"

run_test "404 — bad account" "404" GET "$BASE/accounts/NONEXISTENT_ACCOUNT_ID"
run_test "404 — bad transfer" "404" GET "$BASE/accounts/$ACCT/transfers/NONEXISTENT_TRANSFER"
run_test "403 — tokens/mints (scope)" "403" GET "$BASE/accounts/$ACCT/tokens/mints"

run_test "400 — missing Idempotency-Key" "400" POST "$BASE/accounts/$ACCT/transfers" \
  -H "Content-Type: application/json" \
  -d '{"amount":{"value":"1","currency":"USD"}}'

run_test "422 — empty POST body" "422" POST "$BASE/accounts/$ACCT/transfers" \
  -H "Content-Type: application/json" \
  -H "Idempotency-Key: verify-$(date +%s)" \
  -d '{}'

run_test "422 — bad pagination param" "422" GET "$BASE/accounts/$ACCT/addresses?size=2"

# --------------------------------------------------------------------------
# 5. Case sensitivity tests
# --------------------------------------------------------------------------
echo ""
echo "--- Case Sensitivity Tests ---"

if [ -n "$ADDR" ]; then
  run_test "Balance (Solana capitalized)" "200" GET "$BASE/accounts/$ACCT/addresses/$ADDR/balance?transfer_type=Solana&value_type=SBC"
  run_test "Balance (sbc lowercase)" "200" GET "$BASE/accounts/$ACCT/addresses/$ADDR/balance?transfer_type=solana&value_type=sbc"
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "PASS: $PASS / $TOTAL"
echo "FAIL: $FAIL / $TOTAL"

if [ $FAIL -gt 0 ]; then
  red "Testnet verification: $FAIL failures"
  exit 1
else
  green "All testnet tests passed"
  exit 0
fi
