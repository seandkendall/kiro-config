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
# Step 5: Settings drift warning (soft check — informs, doesn't block)
# ----------------------------------------------------------------------------

echo ""
echo "Step 5: Settings drift check..."
SETTINGS_DIFF=$(cd "$KIRO" && git diff --name-only settings/cli.json agents/ 2>/dev/null)
if [[ -n "$SETTINGS_DIFF" ]]; then
  YELLOW='\033[1;33m'
  echo -e "  ${YELLOW}!${NC} config files have uncommitted changes:"
  echo "$SETTINGS_DIFF" | sed 's|^|      |'
  echo ""
  echo -e "  ${YELLOW}!${NC} Review the diff before committing — Kiro CLI silently mutates"
  echo "      settings/cli.json (e.g., chat.greeting.enabled) and agents/*.json"
  echo "      formatting between sessions. Confirm each change is intentional."
  echo ""
  echo "      Show diff:    git diff settings/cli.json agents/"
  echo "      Revert:       git checkout -- <file>"
  echo "      Stage subset: git add <specific-file>  (preferred over 'git add -A')"
else
  echo -e "  ${GREEN}✓${NC} no config drift in settings/cli.json or agents/"
fi

# ----------------------------------------------------------------------------
# Step 6: Cypress regression guard (post-v0.12.0 migration)
# ----------------------------------------------------------------------------

echo ""
echo "Step 6: Cypress regression guard..."
# Allow:
#   - CHANGELOG.md (historical migration notes)
#   - skills/cypress-to-playwright-migration.md (the runbook with intentional Cypress examples)
#   - skills/playwright-fixtures.template.ts (migration helper; header docs what it replaces)
#   - validate.sh (this file; the regex pattern itself is a literal-string false positive)
CYPRESS_LEAKS=$(cd "$KIRO" && git ls-files \
  | grep -v '^CHANGELOG\.md$' \
  | grep -v '^skills/cypress-to-playwright-migration\.md$' \
  | grep -v '^skills/playwright-fixtures\.template\.ts$' \
  | grep -v '^validate\.sh$' \
  | xargs grep -l -E "cypress|data-cy" 2>/dev/null || true)

if [[ -n "$CYPRESS_LEAKS" ]]; then
  YELLOW='\033[1;33m'
  echo -e "  ${YELLOW}!${NC} Cypress / data-cy references found in tracked files:"
  echo "$CYPRESS_LEAKS" | sed 's|^|      |'
  echo ""
  echo -e "  ${YELLOW}!${NC} Per v0.12.0, all Cypress references should have migrated to Playwright."
  echo "      data-cy → data-testid, cypress/e2e/ → tests/e2e/, cy.* → page.*"
  echo "      See skills/cypress-to-playwright-migration.md for the runbook."
  echo "      If these refs are intentional (e.g., another historical doc),"
  echo "      add the file to the skip list at the top of Step 6 in validate.sh."
else
  echo -e "  ${GREEN}✓${NC} no Cypress/data-cy regressions"
fi

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------

echo ""
echo -e "${GREEN}✓ All checks passed. Safe to push.${NC}"
echo ""
