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

echo "Step 1: Validating V3 agent configs (Markdown + YAML frontmatter)..."
# V3 agents are Markdown with YAML frontmatter (kiro-cli's `agent validate` is JSON-only,
# so we validate the frontmatter directly). V2 JSON backups live in agents/v2-backup/.
set +e
python3 - "$KIRO/agents" <<'PY'
import sys, glob, os
try:
    import yaml
except Exception as e:
    print(f"  pyyaml not available: {e}")
    sys.exit(2)
agents_dir = sys.argv[1]
files = sorted(glob.glob(os.path.join(agents_dir, "*.md")))
if not files:
    print("  no V3 (.md) agents found")
    sys.exit(3)
valid_tags = {"read", "write", "shell", "web", "subagent", "knowledge",
              "todo_list", "@mcp", "@builtin", "*"}
bad, warn = [], []
for f in files:
    name = os.path.basename(f)
    txt = open(f).read()
    if not txt.startswith("---"):
        bad.append((name, "missing YAML frontmatter")); continue
    parts = txt.split("---", 2)
    if len(parts) < 3:
        bad.append((name, "unterminated frontmatter")); continue
    try:
        fm = yaml.safe_load(parts[1])
    except Exception as e:
        bad.append((name, str(e).splitlines()[0])); continue
    if not isinstance(fm, dict):
        bad.append((name, "frontmatter is not a mapping")); continue
    tools = fm.get("tools")
    if tools is None:
        bad.append((name, "missing 'tools'")); continue
    unknown = [t for t in tools if t not in valid_tags]
    if unknown:
        warn.append((name, f"unrecognized tool tag(s): {unknown}"))
    perms = fm.get("permissions")
    if perms is not None and not (isinstance(perms, dict) and isinstance(perms.get("rules"), list)):
        bad.append((name, "permissions must be an object with a 'rules:' list (V3 schema), not a bare array")); continue
for n, m in warn:
    print(f"  ! {n}: {m}")
if bad:
    for n, m in bad:
        print(f"  x {n}: {m}")
    sys.exit(1)
print(f"  validated {len(files)} V3 agents")
sys.exit(0)
PY
RC=$?
set -e
if [[ $RC -ne 0 ]]; then
  echo -e "  ${RED}✗${NC} V3 agent validation failed (rc=$RC)"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} all V3 agents validate (Markdown frontmatter + tool tags)"

# ----------------------------------------------------------------------------
# Step 1.5: V2/V3 parity — the .md files are canonical; .json must match
# ----------------------------------------------------------------------------

echo ""
echo "Step 1.5: V2/V3 agent parity (sync-agents.py --check)..."
set +e
python3 "$KIRO/sync-agents.py" --check
RC=$?
set -e
if [[ $RC -ne 0 ]]; then
  echo -e "  ${RED}✗${NC} V2 JSON out of sync with V3 Markdown — run ./sync-agents.py"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} V2 JSON + prompts/ in sync with V3 Markdown"

# ----------------------------------------------------------------------------
# Step 2: JSON syntax check on all settings + agents
# ----------------------------------------------------------------------------

echo ""
echo "Step 2: JSON syntax check..."
for f in "$KIRO/settings"/*.json "$KIRO/hooks"/*.json "$KIRO/agents"/*.json "$KIRO/agents"/v2-backup/*.json; do
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
# Step 3.5: sync-agents.py self-test
# ----------------------------------------------------------------------------

echo ""
echo "Step 3.5: sync-agents.py self-test..."
set +e
python3 "$KIRO/tests/test_sync_agents.py" >/dev/null 2>&1
RC=$?
set -e
if [[ $RC -ne 0 ]]; then
  echo -e "  ${RED}✗${NC} sync-agents self-test failed — run: python3 tests/test_sync_agents.py"
  exit 1
fi
echo -e "  ${GREEN}✓${NC} sync-agents self-test passed"

# ----------------------------------------------------------------------------
# Step 4: Privacy guard — no tracked file should match personal-* patterns
# ----------------------------------------------------------------------------

echo ""
echo "Step 4: Privacy guard check..."
LEAKS=$(cd "$KIRO" && git ls-files \
  'agents/personal-*.json' \
  'agents/accounting.json' \
  'agents/personal-*.md' \
  'agents/accounting.md' \
  'agents/v2-backup/personal-*.json' \
  'agents/v2-backup/accounting.json' \
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
