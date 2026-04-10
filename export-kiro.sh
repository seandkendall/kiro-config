#!/bin/bash
# export-kiro.sh — Export full Kiro CLI setup to a timestamped directory in ~/Downloads
# Usage: ./export-kiro.sh          (shareable export, excludes personal agents + credentials)
#        ./export-kiro.sh --full   (full backup, everything including personal agents)
#
# What's included:
#   agents/       — Agent configs (personal agents excluded in share mode)
#   steering/     — All steering docs
#   skills/       — All skill files
#   prompts/      — Prompt templates (personal excluded in share mode)
#   settings/     — cli.json (Kiro CLI preferences)
#   README.md     — Setup instructions for recipients
#
# What's excluded:
#   sessions/, extensions/, powers/, .cli_bash_history, elevenlabskey.txt,
#   steering-backup-Dec42025/, argv.json, .DS_Store

set -e

KIRO_DIR="$HOME/.kiro"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FULL=false

if [[ "$1" == "--full" ]]; then
  FULL=true
fi

if $FULL; then
  EXPORT_DIR="$HOME/Downloads/kiro-setup-full-$TIMESTAMP"
else
  EXPORT_DIR="$HOME/Downloads/kiro-setup-$TIMESTAMP"
fi

# Personal agents/prompts to exclude from shareable export
EXCLUDE_AGENTS=(reinvent clean stocks outlook shopify agent_config.json.example db image-editor promptgen accounting)
EXCLUDE_PROMPTS=(accounting.md reinvent.md clean.md db.md image-editor.md outlook.md promptgen.md shopify.md)

echo "Exporting Kiro setup..."

# --- Agents ---
mkdir -p "$EXPORT_DIR/agents"
for f in "$KIRO_DIR/agents"/*.json; do
  [[ ! -f "$f" ]] && continue
  filename=$(basename "$f")
  if ! $FULL; then
    skip=false
    for ex in "${EXCLUDE_AGENTS[@]}"; do
      if [[ "$filename" == "$ex" || "$filename" == "${ex}.json" ]]; then
        skip=true; break
      fi
    done
    $skip && continue
    # Strip personal MCP server entries from agent configs
    python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
servers = d.get('mcpServers', {})
for key in ['elevenlabs-mcp']:
    servers.pop(key, None)
with open(sys.argv[1], 'w') as out:
    json.dump(d, out, indent=2, ensure_ascii=False)
    out.write('\n')
" "$EXPORT_DIR/agents/$filename"
  else
    cp "$f" "$EXPORT_DIR/agents/$filename"
  fi
done

# --- Steering ---
mkdir -p "$EXPORT_DIR/steering"
for f in "$KIRO_DIR/steering"/*.md; do
  [[ -f "$f" ]] && cp "$f" "$EXPORT_DIR/steering/"
done

# --- Skills ---
mkdir -p "$EXPORT_DIR/skills"
for f in "$KIRO_DIR/skills"/*.md; do
  [[ -f "$f" ]] && cp "$f" "$EXPORT_DIR/skills/"
done

# --- Prompts ---
mkdir -p "$EXPORT_DIR/prompts"
for f in "$KIRO_DIR/prompts"/*.md; do
  [[ ! -f "$f" ]] && continue
  filename=$(basename "$f")
  if ! $FULL; then
    skip=false
    for ex in "${EXCLUDE_PROMPTS[@]}"; do
      [[ "$filename" == "$ex" ]] && skip=true && break
    done
    $skip && continue
  fi
  cp "$f" "$EXPORT_DIR/prompts/$filename"
done

# --- Settings (sanitized) ---
mkdir -p "$EXPORT_DIR/settings"
python3 -c "
import json
with open('$KIRO_DIR/settings/cli.json') as f:
    d = json.load(f)
d.pop('mcp.loadedBefore', None)
with open('$EXPORT_DIR/settings/cli.json', 'w') as f:
    json.dump(d, f, indent=2)
    f.write('\n')
"


# --- README + import script ---
[[ -f "$KIRO_DIR/README.md" ]] && cp "$KIRO_DIR/README.md" "$EXPORT_DIR/README.md"
[[ -f "$KIRO_DIR/import.sh" ]] && cp "$KIRO_DIR/import.sh" "$EXPORT_DIR/import.sh" && chmod +x "$EXPORT_DIR/import.sh"

# --- Export script itself ---
cp "$KIRO_DIR/export-kiro.sh" "$EXPORT_DIR/export-kiro.sh" 2>/dev/null || true

# --- Summary ---
echo ""
echo "Export complete: $EXPORT_DIR"
echo ""
AGENT_COUNT=$(ls -1 "$EXPORT_DIR/agents/"*.json 2>/dev/null | wc -l | tr -d ' ')
STEERING_COUNT=$(ls -1 "$EXPORT_DIR/steering/"*.md 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(ls -1 "$EXPORT_DIR/skills/"*.md 2>/dev/null | wc -l | tr -d ' ')
PROMPT_COUNT=$(ls -1 "$EXPORT_DIR/prompts/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  Agents:   $AGENT_COUNT"
echo "  Steering: $STEERING_COUNT"
echo "  Skills:   $SKILL_COUNT"
echo "  Prompts:  $PROMPT_COUNT"
echo "  Settings: cli.json"
if $FULL; then
  echo "  Mode: full backup (includes personal agents)"
else
  echo "  Mode: shareable (personal agents excluded, credentials stripped)"
fi
echo ""
echo "To install on another machine:"
echo "  1. Unzip anywhere on the Mac"
echo "  2. Run: ./import.sh"
