#!/usr/bin/env bash
# verify-mainnet-light.sh — Mainnet LIGHT verification (read-only, no value movement)
#
# Safety tier: LIGHT
#   - Only GET requests and OAuth token retrieval
#   - No POST, PATCH, DELETE
#   - No value movement of any kind
#   - No tokenization endpoints (requires separate account type)
#
# Requirements:
#   BRALE_ENV=mainnet
#   MAINNET_CONFIRM=true
#   BRALE_CLIENT_ID=<mainnet client_id>
#   BRALE_CLIENT_SECRET=<mainnet client_secret>
#
# Usage:
#   BRALE_ENV=mainnet MAINNET_CONFIRM=true \
#   BRALE_CLIENT_ID=xxx BRALE_CLIENT_SECRET=yyy \
#   bash scripts/verify-mainnet-light.sh
set -euo pipefail

# =========================================================================
# Safety gates
# =========================================================================
if [ "${BRALE_ENV:-}" != "mainnet" ]; then
  echo "ABORT: BRALE_ENV must be 'mainnet'. Got: '${BRALE_ENV:-<unset>}'"
  exit 1
fi
if [ "${MAINNET_CONFIRM:-}" != "true" ]; then
  echo "ABORT: MAINNET_CONFIRM must be 'true'."
  exit 1
fi
if [ -z "${BRALE_CLIENT_ID:-}" ] || [ -z "${BRALE_CLIENT_SECRET:-}" ]; then
  echo "ABORT: BRALE_CLIENT_ID and BRALE_CLIENT_SECRET must be set."
  exit 1
fi

BASE="https://api.brale.xyz"
AUTH="https://auth.brale.xyz"
DATA="https://data.brale.xyz"
ARTIFACTS_DIR="artifacts"
mkdir -p "$ARTIFACTS_DIR"

PASS=0; FAIL=0; TOTAL=0
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DELAY=1  # seconds between requests to avoid Cloudflare rate limiting

red()    { printf '\033[0;31mFAIL\033[0m %s\n' "$1"; }
green()  { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }
yellow() { printf '\033[0;33mINFO\033[0m %s\n' "$1"; }

echo "================================================================"
echo "  MAINNET LIGHT VERIFICATION"
echo "  Safety tier: READ-ONLY (GET only, no value movement)"
echo "  Timestamp:   $TIMESTAMP"
echo "================================================================"
echo ""

# Accumulate results in a temp file
RF=$(mktemp)
echo '[]' > "$RF"

add_result() {
  local label="$1" url="$2" exp="$3" got="$4" ctype="$5" sz="$6" st="$7" snip="$8"
  python3 << PYEOF
import json
with open("$RF") as f: r = json.load(f)
r.append({"timestamp":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","label":"$label",
  "url":"$url","method":"GET","expected":$exp,"actual":$got,
  "content_type":"$ctype","size":$sz,"status":"$st",
  "snippet":"""$snip"""[:300]})
with open("$RF","w") as f: json.dump(r, f)
PYEOF
}

# =========================================================================
# Helper: single GET test with pacing
# =========================================================================
run_get() {
  local label="$1" url="$2" expected="$3" use_auth="${4:-yes}"
  TOTAL=$((TOTAL + 1))
  sleep "$DELAY"

  local tmp; tmp=$(mktemp)
  local auth_flag=""
  if [ "$use_auth" = "yes" ]; then
    auth_flag="-H"
  fi

  local code
  if [ "$use_auth" = "yes" ]; then
    code=$(curl -s --http1.1 -o "$tmp" -w "%{http_code}" \
      -H "Authorization: Bearer $TOKEN" \
      "$url" 2>&1)
  else
    code=$(curl -s --http1.1 -o "$tmp" -w "%{http_code}" \
      "$url" 2>&1)
  fi

  local sz; sz=$(wc -c < "$tmp" | tr -d ' ')
  local ctype="application/json"

  # Build redacted snippet
  local snip
  snip=$(python3 -c "
import json, re, sys
try:
    with open('$tmp') as f: d = json.load(f)
    s = json.dumps(d, indent=2)
    if len(s)>300: s=s[:300]+'…'
    s = re.sub(r'ory_at_[A-Za-z0-9._-]+','ory_at_***',s)
    s = re.sub(r'\"account_number\":\s*\"[^\"]+\"','\"account_number\":\"***\"',s)
    print(s)
except:
    with open('$tmp') as f: print(f.read()[:200] or '(empty)')
" 2>&1)
  rm -f "$tmp"

  local ts; ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  if [ "$code" = "$expected" ]; then
    green "[$ts] $label — HTTP $code (${sz}b)"
    PASS=$((PASS + 1))
    add_result "$label" "$url" "$expected" "$code" "$ctype" "$sz" "PASS" "$snip"
  else
    red "[$ts] $label — HTTP $code (expected $expected, ${sz}b)"
    FAIL=$((FAIL + 1))
    add_result "$label" "$url" "$expected" "$code" "$ctype" "$sz" "FAIL" "$snip"
  fi
}

# =========================================================================
# A) Fetch OpenAPI specs
# =========================================================================
echo "--- A. Fetch OpenAPI specs ---"

yellow "Fetching api.brale.xyz OpenAPI..."
API_CODE=$(curl -s --http1.1 -o "$ARTIFACTS_DIR/openapi-mainnet-api.json" -w "%{http_code}" "$BASE/openapi")
TOTAL=$((TOTAL + 1))
if [ "$API_CODE" = "200" ]; then
  green "api.brale.xyz OpenAPI — HTTP $API_CODE ($(wc -c < "$ARTIFACTS_DIR/openapi-mainnet-api.json" | tr -d ' ')b)"
  PASS=$((PASS + 1))
else
  red "api.brale.xyz OpenAPI — HTTP $API_CODE"
  FAIL=$((FAIL + 1))
fi

sleep "$DELAY"

yellow "Fetching data.brale.xyz OpenAPI..."
DATA_CODE=$(curl -s --http1.1 -o "$ARTIFACTS_DIR/openapi-mainnet-data.yaml" -w "%{http_code}" "$DATA/openapi.yaml")
TOTAL=$((TOTAL + 1))
if [ "$DATA_CODE" = "200" ]; then
  green "data.brale.xyz OpenAPI — HTTP $DATA_CODE ($(wc -c < "$ARTIFACTS_DIR/openapi-mainnet-data.yaml" | tr -d ' ')b)"
  PASS=$((PASS + 1))
else
  red "data.brale.xyz OpenAPI — HTTP $DATA_CODE"
  FAIL=$((FAIL + 1))
fi

# =========================================================================
# Authenticate
# =========================================================================
echo ""
echo "--- Authentication ---"
sleep "$DELAY"

AUTH_RESP=$(curl -s --http1.1 -X POST "$AUTH/oauth2/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -u "$BRALE_CLIENT_ID:$BRALE_CLIENT_SECRET" \
  -d "grant_type=client_credentials")

TOKEN=$(echo "$AUTH_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])" 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  red "Authentication failed"
  exit 1
fi
TOTAL=$((TOTAL + 1)); PASS=$((PASS + 1))
green "Auth — token acquired (${TOKEN:0:15}...)"

sleep "$DELAY"
ACCT=$(curl -s --http1.1 -H "Authorization: Bearer $TOKEN" "$BASE/accounts" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['accounts'][0]['id'])")
echo "  Account: $ACCT"
echo ""

# =========================================================================
# B) Read-only endpoint checks (first-party, internal custodial only)
# =========================================================================
echo "--- B. Read-only endpoints (first-party only) ---"

run_get "GET /accounts" "$BASE/accounts" 200
run_get "GET /accounts/{id}/addresses" "$BASE/accounts/$ACCT/addresses" 200
run_get "GET /accounts/{id}/transfers" "$BASE/accounts/$ACCT/transfers" 200
run_get "GET /accounts/{id}/automations" "$BASE/accounts/$ACCT/automations" 200
run_get "GET /accounts/{id}/financial-institutions" "$BASE/accounts/$ACCT/financial-institutions" 200

# Balance on first internal custodial address
FIRST_INT=$(curl -s --http1.1 -H "Authorization: Bearer $TOKEN" "$BASE/accounts/$ACCT/addresses" \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for a in data['addresses']:
    if a['type'] == 'internal' and a['status'] == 'active':
        tts = a.get('transfer_types', [])
        if tts:
            print(a['id'] + '|' + tts[0])
            break
" 2>/dev/null || true)

if [ -n "$FIRST_INT" ]; then
  ADDR_ID=$(echo "$FIRST_INT" | cut -d'|' -f1)
  CHAIN=$(echo "$FIRST_INT" | cut -d'|' -f2)
  run_get "GET /balance ($CHAIN/SBC, internal custodial)" \
    "$BASE/accounts/$ACCT/addresses/$ADDR_ID/balance?transfer_type=$CHAIN&value_type=SBC" 200
fi

# =========================================================================
# Data API (public)
# =========================================================================
echo ""
echo "--- Data API (public, no auth) ---"

run_get "GET data.brale.xyz /list" "$DATA/list" 200 "no"
run_get "GET data.brale.xyz /price/SBC" "$DATA/price/SBC" 200 "no"
run_get "GET data.brale.xyz /data/SBC" "$DATA/data/SBC" 200 "no"

# =========================================================================
# C) Negative tests
# =========================================================================
echo ""
echo "--- C. Negative tests ---"

run_get "GET /accounts/{bogus}/addresses → 404" \
  "$BASE/accounts/BOGUS_NONEXISTENT_12345/addresses" 404
run_get "GET /accounts (no auth) → 401" "$BASE/accounts" 401 "no"

# =========================================================================
# D) Schema drift
# =========================================================================
echo ""
echo "--- D. Schema drift check ---"
python3 << 'PYEOF'
import json
try:
    with open("artifacts/openapi-mainnet-api.json") as f:
        spec = json.load(f)
    paths = sorted(spec.get("paths", {}).keys())
    documented = {
        "/accounts",
        "/accounts/{account_id}/addresses",
        "/accounts/{account_id}/addresses/external",
        "/accounts/{account_id}/transfers",
        "/accounts/{account_id}/automations",
        "/accounts/{account_id}/financial-institutions",
        "/accounts/{account_id}/addresses/{address_id}/balance",
        "/accounts/{account_id}/tokens/mints",
        "/accounts/{account_id}/tokens/burns",
        "/accounts/{account_id}/tokens/transactions",
        "/accounts/{account_id}/tokens/transfers",
    }
    undoc = [p for p in paths if p not in documented]
    if undoc:
        print(f"Undocumented mainnet paths ({len(undoc)}):")
        for p in undoc:
            methods = list(spec["paths"][p].keys())
            print(f"  {p}  [{' '.join(m.upper() for m in methods)}]")
    else:
        print("All mainnet paths are documented")
    print(f"Total paths in spec: {len(paths)}")
except Exception as e:
    print(f"Parse error: {e}")
PYEOF

# =========================================================================
# Write artifact
# =========================================================================
echo ""
echo "--- Writing artifact ---"
python3 - "$RF" << PYEOF
import json, sys
with open(sys.argv[1]) as f: results = json.load(f)
out = {"run_timestamp":"$TIMESTAMP","environment":"mainnet","safety_tier":"light",
  "account_id":"$ACCT","total":$TOTAL,"pass":$PASS,"fail":$FAIL,"results":results}
with open("$ARTIFACTS_DIR/mainnet-light-run.json","w") as f:
    json.dump(out, f, indent=2)
print("Written: $ARTIFACTS_DIR/mainnet-light-run.json")
PYEOF
rm -f "$RF"

# =========================================================================
# Summary
# =========================================================================
echo ""
echo "================================================================"
echo "  MAINNET LIGHT — PASS: $PASS / $TOTAL  |  FAIL: $FAIL / $TOTAL"
echo "================================================================"
[ $FAIL -gt 0 ] && { red "$FAIL failures"; exit 1; } || { green "All read-only checks passed"; exit 0; }
