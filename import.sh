#!/bin/bash
# import.sh — Install Kiro CLI setup from this directory
# Usage: Unzip anywhere on your Mac, then run: ./import.sh
#
# This script will:
#   1. Check if Kiro CLI is installed, offer to install it if not
#   2. Check prerequisites (Python, Node.js, uv, uvx)
#   3. Copy agents, steering, skills, prompts, and settings to ~/.kiro/
#   4. Preserve any existing files (won't overwrite without asking)

set -e

KIRO_DIR="$HOME/.kiro"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Kiro CLI Setup Installer           ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# --- Step 1: Check if Kiro CLI is installed ---
if command -v kiro-cli &>/dev/null; then
  KIRO_VERSION=$(kiro-cli --version 2>/dev/null || echo "unknown")
  echo -e "${GREEN}✓${NC} Kiro CLI found: $KIRO_VERSION"
else
  echo -e "${YELLOW}⚠${NC} Kiro CLI is not installed."
  echo ""
  echo "  Install options:"
  echo "    1) Auto-install via official installer (recommended)"
  echo "    2) Install via Homebrew"
  echo "    3) Skip — I'll install it myself later"
  echo ""
  read -rp "  Choose [1/2/3]: " INSTALL_CHOICE
  case "$INSTALL_CHOICE" in
    1)
      echo ""
      echo "  Installing Kiro CLI..."
      curl -fsSL https://cli.kiro.dev/install | bash
      echo ""
      if command -v kiro-cli &>/dev/null; then
        echo -e "${GREEN}✓${NC} Kiro CLI installed successfully"
      else
        echo -e "${YELLOW}⚠${NC} Kiro CLI installed but not in PATH yet."
        echo "  Add this to your shell profile (~/.zshrc or ~/.bashrc):"
        echo '    export PATH="$HOME/.local/bin:$PATH"'
        echo "  Then restart your terminal or run: source ~/.zshrc"
      fi
      ;;
    2)
      echo ""
      echo "  Installing via Homebrew..."
      brew install --cask kiro-cli
      echo -e "${GREEN}✓${NC} Kiro CLI installed via Homebrew"
      ;;
    3)
      echo ""
      echo "  Skipping Kiro CLI install. You can install later:"
      echo "    curl -fsSL https://cli.kiro.dev/install | bash"
      echo "    — or —"
      echo "    brew install --cask kiro-cli"
      ;;
    *)
      echo "  Invalid choice. Skipping install."
      ;;
  esac
  echo ""
fi

# --- Step 2: Check prerequisites ---
echo "Checking prerequisites..."
MISSING=()

if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>&1)
  echo -e "  ${GREEN}✓${NC} $PY_VER"
else
  echo -e "  ${RED}✗${NC} Python 3 not found"
  MISSING+=("Python 3.13+ (https://python.org)")
fi

if command -v node &>/dev/null; then
  NODE_VER=$(node --version 2>&1)
  echo -e "  ${GREEN}✓${NC} Node.js $NODE_VER"
else
  echo -e "  ${RED}✗${NC} Node.js not found"
  MISSING+=("Node.js 20+ (https://nodejs.org)")
fi

if command -v uvx &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} uvx found"
else
  echo -e "  ${RED}✗${NC} uvx not found"
  MISSING+=("uv (curl -LsSf https://astral.sh/uv/install.sh | sh)")
fi

if command -v npx &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} npx found"
else
  echo -e "  ${RED}✗${NC} npx not found (comes with Node.js)"
  MISSING+=("npx (included with Node.js)")
fi

if command -v aws &>/dev/null; then
  AWS_VER=$(aws --version 2>&1 | head -1)
  echo -e "  ${GREEN}✓${NC} $AWS_VER"
else
  echo -e "  ${YELLOW}⚠${NC} AWS CLI not found (optional but recommended)"
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}Missing prerequisites:${NC}"
  for m in "${MISSING[@]}"; do
    echo "  - $m"
  done
  echo ""
  read -rp "Continue anyway? [y/N]: " CONTINUE
  [[ "$CONTINUE" != "y" && "$CONTINUE" != "Y" ]] && echo "Aborted." && exit 1
fi

# --- Step 3: Create ~/.kiro if needed ---
echo ""
if [[ ! -d "$KIRO_DIR" ]]; then
  echo "Creating $KIRO_DIR..."
  mkdir -p "$KIRO_DIR"
fi

# --- Step 3.5: Clean up legacy Kiro config ---
LEGACY_FOUND=false

# Remove legacy global mcp.json (agents are self-contained now)
if [[ -f "$KIRO_DIR/settings/mcp.json" ]]; then
  LEGACY_FOUND=true
  echo -e "  ${YELLOW}⚠${NC}  Found legacy settings/mcp.json"
fi

# Check for legacy agent patterns
LEGACY_AGENTS=()
if [[ -d "$KIRO_DIR/agents" ]]; then
  for f in "$KIRO_DIR/agents"/*.json; do
    [[ ! -f "$f" ]] && continue
    if grep -q '"useLegacyMcpJson"' "$f" 2>/dev/null || \
       grep -q '"autoApprove"' "$f" 2>/dev/null || \
       grep -q '"backup_on_overwrite"' "$f" 2>/dev/null || \
       grep -q '"execute_bash"' "$f" 2>/dev/null || \
       grep -q '"mcp-server-fetch"' "$f" 2>/dev/null || \
       grep -q '"\$schema"' "$f" 2>/dev/null; then
      LEGACY_AGENTS+=("$(basename "$f")")
      LEGACY_FOUND=true
    fi
  done
fi

# Check for deprecated MCP servers in agents
DEPRECATED_SERVERS=("code-doc-gen" "aws-diagram" "core-mcp-server" "nova-canvas" "bedrock-data-automation" "aws-msk" "nova.act" "nova_act")
for f in "$KIRO_DIR/agents"/*.json 2>/dev/null; do
  [[ ! -f "$f" ]] && continue
  for dep in "${DEPRECATED_SERVERS[@]}"; do
    if grep -q "$dep" "$f" 2>/dev/null; then
      LEGACY_FOUND=true
      break 2
    fi
  done
done

if $LEGACY_FOUND; then
  echo ""
  echo -e "${YELLOW}Legacy Kiro configuration detected.${NC}"
  echo "  This installer will clean up outdated config patterns:"
  echo "    - Remove settings/mcp.json (agents are self-contained)"
  echo "    - Remove deprecated fields from agent configs"
  echo "    - Remove deprecated MCP server references"
  echo ""
  read -rp "  Clean up legacy config? [Y/n]: " CLEANUP_CHOICE
  if [[ "$CLEANUP_CHOICE" != "n" && "$CLEANUP_CHOICE" != "N" ]]; then
    # Remove legacy mcp.json
    rm -f "$KIRO_DIR/settings/mcp.json" 2>/dev/null

    # Clean legacy patterns from existing agent configs
    if command -v python3 &>/dev/null; then
      python3 -c "
import json, glob, os

deprecated_mcp = ['code-doc-gen-mcp-server', 'aws-diagram-mcp-server', 'core-mcp-server',
                  'nova-canvas-mcp-server', 'bedrock-data-automation-mcp-server',
                  'aws-msk-mcp-server', 'nova-act', 'fetch']
remap_ts = {'execute_bash': 'shell', 'fs_write': 'write'}
count = 0

for f in glob.glob(os.path.expanduser('$KIRO_DIR/agents/*.json')):
    try:
        with open(f) as fh:
            d = json.load(fh)
    except:
        continue
    modified = False

    # Remove deprecated fields
    for field in ['\$schema', 'useLegacyMcpJson']:
        if field in d:
            del d[field]
            modified = True

    # Remove model: null
    if 'model' in d and d['model'] is None:
        del d['model']
        modified = True

    # Remove deprecated MCP servers
    for dep in deprecated_mcp:
        if dep in d.get('mcpServers', {}):
            del d['mcpServers'][dep]
            modified = True

    # Fix toolsSettings keys
    ts = d.get('toolsSettings', {})
    for old, new in remap_ts.items():
        if old in ts:
            ts[new] = ts.pop(old)
            modified = True

    # Remove backup_on_overwrite
    if 'backup_on_overwrite' in ts.get('write', {}):
        del ts['write']['backup_on_overwrite']
        if not ts['write']:
            del ts['write']
        modified = True

    # Convert autoApprove to allowedTools
    allowed = d.get('allowedTools', [])
    for sk, sv in list(d.get('mcpServers', {}).items()):
        if 'autoApprove' in sv:
            for tool in sv['autoApprove']:
                entry = f'@{sk}/{tool}'
                if entry not in allowed:
                    allowed.append(entry)
            del sv['autoApprove']
            modified = True
    if allowed:
        d['allowedTools'] = allowed

    # Remove @fetch from allowedTools
    if '@fetch' in d.get('allowedTools', []):
        d['allowedTools'].remove('@fetch')
        modified = True

    # Clean empty collections
    if d.get('toolAliases') == {}:
        del d['toolAliases']
        modified = True
    if d.get('allowedTools') == []:
        del d['allowedTools']
        modified = True

    if modified:
        with open(f, 'w') as fh:
            json.dump(d, fh, indent=2, ensure_ascii=False)
            fh.write('\n')
        count += 1

print(f'    Cleaned {count} agent config(s)')
"
    fi
    echo -e "  ${GREEN}✓${NC} Legacy cleanup complete"
  else
    echo "  Skipping legacy cleanup."
  fi
  echo ""
fi

# --- Step 4: Copy files ---
DIRS=(agents steering skills prompts settings)
OVERWRITE_ALL=false
SKIP_ALL=false

copy_dir() {
  local src="$1"
  local dest="$KIRO_DIR/$2"
  local dir_name="$2"

  if [[ ! -d "$SCRIPT_DIR/$src" ]]; then
    return
  fi

  mkdir -p "$dest"
  local count=0

  for f in "$SCRIPT_DIR/$src"/*; do
    [[ ! -f "$f" ]] && continue
    local filename=$(basename "$f")
    local target="$dest/$filename"

    if [[ -f "$target" ]] && ! $OVERWRITE_ALL; then
      if ! $SKIP_ALL; then
        echo -e "  ${YELLOW}File exists:${NC} $dir_name/$filename"
        read -rp "  Overwrite? [y/N/all/skip-all]: " CHOICE
        case "$CHOICE" in
          all) OVERWRITE_ALL=true ;;
          skip-all) SKIP_ALL=true; continue ;;
          y|Y) ;;
          *) continue ;;
        esac
      else
        continue
      fi
    fi

    cp "$f" "$target"
    ((count++))
  done

  [[ $count -gt 0 ]] && echo -e "  ${GREEN}✓${NC} $dir_name/ — $count files"
}

echo "Installing configuration..."
for dir in "${DIRS[@]}"; do
  copy_dir "$dir" "$dir"
done

# Copy README if present
[[ -f "$SCRIPT_DIR/README.md" ]] && cp "$SCRIPT_DIR/README.md" "$KIRO_DIR/README.md"

# --- Step 5: Environment variable reminder ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║          Installation Complete!          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Set up your environment variables:"
echo ""
echo "  export GITHUB_PERSONAL_ACCESS_TOKEN=\"ghp_your_token_here\""
echo ""
echo "Add to ~/.zshrc (or ~/.bashrc) to persist."
echo ""
echo "To start using Kiro CLI:"
echo "  kiro-cli chat"
echo ""
echo "See README.md for full documentation."
