#!/bin/bash
# export-agents.sh — Export Kiro agents to a timestamped directory in ~/Downloads
# Usage: ./export-agents.sh          (shareable export, excludes personal agents + nova-act)
#        ./export-agents.sh --full   (full backup, all agents + nova-act MCP server)

set -e

AGENTS_DIR="$HOME/.kiro/agents"
NOVA_ACT_SERVER="$HOME/.kiro/mcp-servers/nova_act_mcp_server.py"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FULL=false

if [[ "$1" == "--full" ]]; then
  FULL=true
fi

if $FULL; then
  EXPORT_DIR="$HOME/Downloads/kiro-agents-full-$TIMESTAMP"
else
  EXPORT_DIR="$HOME/Downloads/kiro-agents-$TIMESTAMP"
fi

mkdir -p "$EXPORT_DIR"

EXCLUDE_SHARE=(reinvent clean unity godot stocks outlook shopify agent_config.json.example)

for f in "$AGENTS_DIR"/*.json; do
  filename=$(basename "$f")

  if ! $FULL; then
    skip=false
    for ex in "${EXCLUDE_SHARE[@]}"; do
      if [[ "$filename" == "$ex" || "$filename" == "${ex}.json" ]]; then
        skip=true
        break
      fi
    done
    $skip && continue

    # Copy and strip nova-act MCP server entry
    python3 -c "
import json, sys
with open('$f') as fh:
    d = json.load(fh)
servers = d.get('mcpServers', {})
if 'nova-act' in servers:
    del servers['nova-act']
with open(sys.argv[1], 'w') as out:
    json.dump(d, out, indent=2, ensure_ascii=False)
" "$EXPORT_DIR/$filename"
  else
    cp "$f" "$EXPORT_DIR/$filename"
  fi
done

# Full mode: also copy the nova-act MCP server script
if $FULL && [[ -f "$NOVA_ACT_SERVER" ]]; then
  mkdir -p "$EXPORT_DIR/mcp-servers"
  cp "$NOVA_ACT_SERVER" "$EXPORT_DIR/mcp-servers/"
fi

COUNT=$(ls -1 "$EXPORT_DIR"/*.json 2>/dev/null | wc -l | tr -d ' ')
echo "Exported $COUNT agents to: $EXPORT_DIR"
if $FULL; then
  [[ -f "$EXPORT_DIR/mcp-servers/nova_act_mcp_server.py" ]] && echo "Included: nova_act_mcp_server.py"
else
  echo "Mode: shareable (nova-act MCP server stripped, personal agents excluded)"
fi
