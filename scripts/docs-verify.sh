#!/usr/bin/env bash
# docs-verify.sh — Semantic drift guard + JSON validation + internal link check
# Run from repo root: bash scripts/docs-verify.sh
set -euo pipefail

FAIL=0
WARN=0
PASS=0
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

red()    { printf '\033[0;31mFAIL\033[0m %s\n' "$1"; }
yellow() { printf '\033[0;33mWARN\033[0m %s\n' "$1"; }
green()  { printf '\033[0;32mPASS\033[0m %s\n' "$1"; }

echo "=== Brale Docs Verification ==="
echo "Repo: $REPO_ROOT"
echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo ""

# --------------------------------------------------------------------------
# 1. Semantic drift guard — ban camelCase variants
# --------------------------------------------------------------------------
echo "--- 1. Semantic Drift: camelCase ban ---"

for pattern in 'valueType' 'transferType'; do
  hits=$(grep -rn "$pattern" "$REPO_ROOT"/*.mdx "$REPO_ROOT"/**/*.mdx 2>/dev/null | grep -v 'node_modules' | grep -v '.cursor' | grep -v '_verification.md' || true)
  if [ -n "$hits" ]; then
    red "Found banned camelCase '$pattern':"
    echo "$hits"
    FAIL=$((FAIL + 1))
  else
    green "No camelCase '$pattern' found"
    PASS=$((PASS + 1))
  fi
done

# --------------------------------------------------------------------------
# 2. Semantic drift guard — ban singular /transfer endpoint path
# --------------------------------------------------------------------------
echo ""
echo "--- 2. Semantic Drift: singular /transfer ban ---"

hits=$(grep -rn '\/transfer"' "$REPO_ROOT"/*.mdx "$REPO_ROOT"/**/*.mdx 2>/dev/null \
  | grep -v '/transfers' \
  | grep -v 'node_modules' \
  | grep -v '.cursor' \
  | grep -v '_verification.md' || true)
if [ -n "$hits" ]; then
  red "Found singular '/transfer' (should be '/transfers'):"
  echo "$hits"
  FAIL=$((FAIL + 1))
else
  green "No singular '/transfer' endpoint paths found"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 3. Semantic drift guard — ban capitalized transfer_type enum values in JSON
# --------------------------------------------------------------------------
echo ""
echo "--- 3. Semantic Drift: capitalized transfer_type in JSON ---"

hits=$(grep -rn '"transfer_type":\s*"[A-Z]' "$REPO_ROOT"/*.mdx "$REPO_ROOT"/**/*.mdx 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v '.cursor' \
  | grep -v '_verification.md' || true)
if [ -n "$hits" ]; then
  red "Found capitalized transfer_type values in JSON (should be lowercase):"
  echo "$hits"
  FAIL=$((FAIL + 1))
else
  green "No capitalized transfer_type values in JSON"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 4. Semantic drift guard — ban hyphenated transfer_type values
# --------------------------------------------------------------------------
echo ""
echo "--- 4. Semantic Drift: hyphenated transfer_type values ---"

hits=$(grep -rn '"transfer_type":\s*"[a-z]*-[a-z]' "$REPO_ROOT"/*.mdx "$REPO_ROOT"/**/*.mdx 2>/dev/null \
  | grep -v 'node_modules' \
  | grep -v '.cursor' \
  | grep -v '_verification.md' || true)
if [ -n "$hits" ]; then
  red "Found hyphenated transfer_type values (should use underscores):"
  echo "$hits"
  FAIL=$((FAIL + 1))
else
  green "No hyphenated transfer_type values"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 5. JSON snippet validation (lightweight)
# --------------------------------------------------------------------------
echo ""
echo "--- 5. JSON Syntax Validation ---"

json_fail=0
# Use python to extract and validate JSON blocks from all mdx files
json_fail=$(python3 -c "
import re, json, sys, glob, os
root = '$REPO_ROOT'
fails = 0
for f in glob.glob(os.path.join(root, '**/*.mdx'), recursive=True):
    if 'node_modules' in f or '.cursor' in f:
        continue
    with open(f) as fh:
        content = fh.read()
    blocks = re.findall(r'\`\`\`json[^\n]*\n(.*?)\`\`\`', content, re.DOTALL)
    for block in blocks:
        if '...' in block or '\${' in block:
            continue
        cleaned = re.sub(r'//.*', '', block)
        cleaned = re.sub(r',(\s*[}\]])', r'\1', cleaned)
        try:
            json.loads(cleaned)
        except json.JSONDecodeError:
            rel = os.path.relpath(f, root)
            snippet = block.strip()[:60].replace(chr(10), ' ')
            print(f'  FAIL: {rel}: {snippet}...', file=sys.stderr)
            fails += 1
print(fails)
" 2>&1)

if [ "$json_fail" != "0" ] && [ -n "$json_fail" ]; then
  echo "$json_fail" | grep -v '^[0-9]*$' || true
  count=$(echo "$json_fail" | tail -1)
  if [ "$count" != "0" ]; then
    yellow "JSON validation: $count blocks could not be parsed (may contain partial snippets)"
    WARN=$((WARN + 1))
  else
    green "All JSON blocks valid"
    PASS=$((PASS + 1))
  fi
else
  green "All JSON blocks valid"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 6. Guide completeness — every guide must have a Verification section
# --------------------------------------------------------------------------
echo ""
echo "--- 6. Guide Completeness: Verification sections ---"

guide_pass=0
guide_fail=0
for f in $(find "$REPO_ROOT/guides" -name '*.mdx' -not -path '*/node_modules/*'); do
  basename_f=$(basename "$f")
  # Skip empty stub pages
  content_len=$(wc -c < "$f" | tr -d ' ')
  if [ "$content_len" -lt 100 ]; then
    continue
  fi
  if grep -q '## Verification' "$f" 2>/dev/null; then
    guide_pass=$((guide_pass + 1))
  else
    yellow "Missing '## Verification' section in guides/$basename_f"
    guide_fail=$((guide_fail + 1))
  fi
done

if [ $guide_fail -gt 0 ]; then
  WARN=$((WARN + guide_fail))
  echo "  $guide_fail guides missing Verification section, $guide_pass have it"
else
  green "All guides have Verification sections ($guide_pass checked)"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 7. Guide completeness — every transfer example must have both value_type and transfer_type
# --------------------------------------------------------------------------
echo ""
echo "--- 7. Transfer Examples: value_type + transfer_type completeness ---"

transfer_fail=0
transfer_fail=$(python3 -c "
import re, json, sys, glob, os
root = '$REPO_ROOT'
fails = 0
for f in glob.glob(os.path.join(root, '**/*.mdx'), recursive=True):
    if 'node_modules' in f or '.cursor' in f:
        continue
    with open(f) as fh:
        content = fh.read()
    blocks = re.findall(r'\x60\x60\x60json[^\n]*\n(.*?)\x60\x60\x60', content, re.DOTALL)
    for block in blocks:
        # Skip blocks that use shell variable substitution (not literal JSON)
        if '\${' in block:
            continue
        cleaned = re.sub(r'//.*', '', block)
        # Check if this looks like a transfer request (has source or destination with address_id)
        if 'address_id' in block and ('\"source\"' in block or '\"destination\"' in block):
            # Each source/destination should have both value_type and transfer_type
            for section in ['source', 'destination']:
                # Find the section in the block using a pattern that handles multiline
                pattern = r'\"' + section + r'\"\s*:\s*\{([^}]+)\}'
                match = re.search(pattern, block, re.DOTALL)
                if match:
                    inner = match.group(1)
                    has_vt = 'value_type' in inner
                    has_tt = 'transfer_type' in inner
                    if not has_vt or not has_tt:
                        rel = os.path.relpath(f, root)
                        missing = []
                        if not has_vt: missing.append('value_type')
                        if not has_tt: missing.append('transfer_type')
                        print(f'  WARN: {rel}: {section} missing {\" and \".join(missing)}', file=sys.stderr)
                        fails += 1
print(fails)
" 2>&1)

if [ "$transfer_fail" != "0" ] && [ -n "$transfer_fail" ]; then
  echo "$transfer_fail" | grep -v '^[0-9]*$' || true
  count=$(echo "$transfer_fail" | tail -1)
  if [ "$count" != "0" ]; then
    yellow "Transfer examples: $count sections missing value_type or transfer_type"
    WARN=$((WARN + 1))
  else
    green "All transfer examples include both value_type and transfer_type"
    PASS=$((PASS + 1))
  fi
else
  green "All transfer examples include both value_type and transfer_type"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# 8. Internal link check — verify href targets exist as files
# --------------------------------------------------------------------------
echo ""
echo "--- 8. Internal Link Check ---"

link_fail=0
link_pass=0

for f in $(find "$REPO_ROOT" -name '*.mdx' -not -path '*/node_modules/*' -not -path '*/.cursor/*' -not -path '*/docs/*'); do
  # Extract href="/..." links
  links=$(grep -oE 'href="(/[^"#]*)"' "$f" 2>/dev/null | sed 's/href="//;s/"//' || true)
  for link in $links; do
    # Skip external links and anchors
    if echo "$link" | grep -q '^http'; then continue; fi
    if [ "$link" = "/" ]; then continue; fi
    
    # Check if target file exists (with or without .mdx extension)
    target="$REPO_ROOT${link}"
    if [ -f "${target}.mdx" ] || [ -f "${target}" ] || [ -d "${target}" ] || [ -f "${target}/index.mdx" ]; then
      link_pass=$((link_pass + 1))
    else
      yellow "Broken link in $(basename "$f"): $link"
      link_fail=$((link_fail + 1))
    fi
  done
done

if [ $link_fail -gt 0 ]; then
  WARN=$((WARN + link_fail))
  echo "  $link_fail broken links, $link_pass valid links"
else
  green "All internal links valid ($link_pass checked)"
  PASS=$((PASS + 1))
fi

# --------------------------------------------------------------------------
# Summary
# --------------------------------------------------------------------------
echo ""
echo "=== Summary ==="
echo "PASS: $PASS"
echo "WARN: $WARN"
echo "FAIL: $FAIL"

if [ $FAIL -gt 0 ]; then
  echo ""
  red "Verification failed with $FAIL errors"
  exit 1
else
  green "All checks passed"
  exit 0
fi
