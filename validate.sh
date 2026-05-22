#!/usr/bin/env bash
#
# validate.sh — Pre-push validation for the live ~/.kiro config
#
# Validates the working tree directly. No bundle export, no simulated install
# (this repo is now distributed via direct git clone, so there's no bundle to
# build). Run before every git push to catch:
#
#   1. Invalid JSON in agents/ and settings/
#   2. Agents that fail kiro-cli's schema validation
#   3. Bash syntax errors in import.sh and validate.sh
#   4. Privacy guard regressions: any tracked file matching the
#      personal-* gitignore patterns
#
# This is NOT a CI/CD pipeline — it's a local script you run yourself.
# The only deployment method for projects is still `deploy.sh` (per
# steering rules).
#

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

KIRO="$HOME/.kiro"

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      Kiro Config — Pre-push Validation    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ----------------------------------------------------------------------------
# Step 1: Validate every agent JSON
# ----------------------------------------------------------------------------

echo "Step 1: Validating agent configs..."
PASS=0
FAIL=0
FAIL_LIST=()
for agent_file in "$KIRO/agents"/*.json; do
  [[ ! -f "$agent_file" ]] && continue
  if kiro-cli agent validate --path "$agent_file" >/dev/null 2>&1; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    FAIL_LIST+=("$(basename "$agent_file")")
  fi
done

if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}✓${NC} all $PASS agents validate"
else
  echo -e "  ${RED}✗${NC} $PASS passed, $FAIL failed: ${FAIL_LIST[*]}"
  exit 1
fi

# ----------------------------------------------------------------------------
# Step 2: JSON syntax check on all settings + agents
# ----------------------------------------------------------------------------

echo ""
echo "Step 2: JSON syntax check..."
for f in "$KIRO/settings"/*.json "$KIRO/agents"/*.json; do
  [[ ! -f "$f" ]] && continue
  if ! python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} invalid JSON: $f"
    exit 1
  fi
done
echo -e "  ${GREEN}✓${NC} all JSON files parse"

# ----------------------------------------------------------------------------
# Step 3: Bash syntax check on shell scripts
# ----------------------------------------------------------------------------

echo ""
echo "Step 3: Bash syntax check..."
for sh in "$KIRO/import.sh" "$KIRO/validate.sh"; do
  [[ ! -f "$sh" ]] && continue
  if ! bash -n "$sh" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} bash syntax error: $sh"
    exit 1
  fi
done
echo -e "  ${GREEN}✓${NC} import.sh, validate.sh syntactically valid"

# ----------------------------------------------------------------------------
# Step 4: Privacy guard — no tracked file should match personal-* patterns
# ----------------------------------------------------------------------------

echo ""
echo "Step 4: Privacy guard check..."
LEAKS=$(cd "$KIRO" && git ls-files \
  'agents/personal-*.json' \
  'agents/accounting.json' \
  'prompts/personal-*.md' \
  'prompts/accounting.md' \
  'steering/personal-*.md' 2>/dev/null \
  | grep -v 'steering/personal-rules-protocol.md' || true)

if [[ -n "$LEAKS" ]]; then
  echo -e "  ${RED}✗${NC} private files are tracked by git:"
  echo "$LEAKS" | sed 's|^|      |'
  echo "  Run: git rm --cached <file> for each, then commit"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} no personal/private files leaked into git"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------

echo ""
echo -e "${GREEN}✓ All checks passed. Safe to push.${NC}"
echo ""
