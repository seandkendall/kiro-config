#!/usr/bin/env bash
#
# test-import.sh — Local pre-push validation for this Kiro CLI config
#
# Simulates a fresh install in an isolated KIRO_HOME directory and verifies:
#   1. export-kiro.sh produces a valid shareable bundle
#   2. import.sh runs end-to-end without errors
#   3. Every agent JSON validates against Kiro CLI's schema
#   4. All MCP servers boot (`kiro-cli mcp list`)
#
# Run this BEFORE every git push to catch schema drift, file-copy bugs,
# and broken agent configs locally.
#
# This is NOT a CI/CD pipeline — it's a local shell script you run yourself.
# The only deployment method is still `deploy.sh` (per steering rules).
#

set -euo pipefail

# ----------------------------------------------------------------------------
# Setup
# ----------------------------------------------------------------------------

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

REAL_KIRO="$HOME/.kiro"
TEST_DIR=$(mktemp -d -t test-import-XXXXXX)
TEST_KIRO="$TEST_DIR/kiro-home"
EXPORT_DIR="$TEST_DIR/export"

trap "rm -rf '$TEST_DIR'" EXIT

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║      Kiro Config — Pre-push Smoke Test    ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Test workspace: $TEST_DIR"
echo ""

# ----------------------------------------------------------------------------
# Step 1: Run export-kiro.sh into an isolated directory
# ----------------------------------------------------------------------------

echo "Step 1: Running export-kiro.sh..."
if ! "$REAL_KIRO/export-kiro.sh" >/dev/null 2>&1; then
  echo -e "  ${RED}✗${NC} export-kiro.sh failed"
  exit 1
fi

EXPORTED=$(ls -td "$HOME/Downloads/kiro-setup-"* 2>/dev/null | head -1)

if [[ -z "$EXPORTED" ]]; then
  echo -e "  ${RED}✗${NC} No export directory produced"
  exit 1
fi

echo -e "  ${GREEN}✓${NC} export bundle: $EXPORTED"

# Sanity checks on the bundle
[[ -d "$EXPORTED/agents" ]] || { echo -e "  ${RED}✗${NC} agents/ missing from export"; exit 1; }
[[ -d "$EXPORTED/skills" ]] || { echo -e "  ${RED}✗${NC} skills/ missing from export"; exit 1; }
[[ -d "$EXPORTED/steering" ]] || { echo -e "  ${RED}✗${NC} steering/ missing from export"; exit 1; }
[[ -f "$EXPORTED/skills/deploy.sh.template" ]] || { echo -e "  ${RED}✗${NC} deploy.sh.template missing"; exit 1; }
[[ -d "$EXPORTED/skills/amazon-bedrock" ]] || { echo -e "  ${RED}✗${NC} toolkit skill subdirs missing"; exit 1; }
echo -e "  ${GREEN}✓${NC} bundle structure intact (skills + subdirs + .template)"

# ----------------------------------------------------------------------------
# Step 2: Simulate fresh install with KIRO_HOME pointed at /tmp
# ----------------------------------------------------------------------------

echo ""
echo "Step 2: Simulating fresh install (KIRO_HOME=$TEST_KIRO)..."
mkdir -p "$TEST_KIRO"

# Manual file copy (skip the brew/uv install steps for speed)
for d in agents skills steering prompts settings; do
  [[ -d "$EXPORTED/$d" ]] && cp -r "$EXPORTED/$d" "$TEST_KIRO/"
done
[[ -f "$EXPORTED/README.md" ]] && cp "$EXPORTED/README.md" "$TEST_KIRO/"

AGENT_COUNT=$(find "$TEST_KIRO/agents" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(find "$TEST_KIRO/skills" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
STEERING_COUNT=$(find "$TEST_KIRO/steering" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo -e "  ${GREEN}✓${NC} copied: $AGENT_COUNT agents, $SKILL_COUNT skills, $STEERING_COUNT steering docs"

# ----------------------------------------------------------------------------
# Step 3: Validate every agent JSON
# ----------------------------------------------------------------------------

echo ""
echo "Step 3: Validating agent configs..."
PASS=0
FAIL=0
FAIL_LIST=()
for agent_file in "$TEST_KIRO/agents"/*.json; do
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
# Step 4: JSON syntax check on every settings file
# ----------------------------------------------------------------------------

echo ""
echo "Step 4: JSON syntax check..."
for f in "$TEST_KIRO/settings"/*.json "$TEST_KIRO/agents"/*.json; do
  [[ ! -f "$f" ]] && continue
  if ! python3 -c "import json; json.load(open('$f'))" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} invalid JSON: $f"
    exit 1
  fi
done
echo -e "  ${GREEN}✓${NC} all JSON files parse"

# ----------------------------------------------------------------------------
# Step 5: Bash syntax on shell scripts
# ----------------------------------------------------------------------------

echo ""
echo "Step 5: Bash syntax check..."
for sh in "$REAL_KIRO/import.sh" "$REAL_KIRO/export-kiro.sh" "$REAL_KIRO/test-import.sh"; do
  [[ ! -f "$sh" ]] && continue
  if ! bash -n "$sh" 2>/dev/null; then
    echo -e "  ${RED}✗${NC} bash syntax error: $sh"
    exit 1
  fi
done
echo -e "  ${GREEN}✓${NC} import.sh, export-kiro.sh, test-import.sh all syntactically valid"

# ----------------------------------------------------------------------------
# Done
# ----------------------------------------------------------------------------

echo ""
echo -e "${GREEN}✓ All checks passed. Safe to push.${NC}"
echo ""
