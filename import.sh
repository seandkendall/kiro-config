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

# --- Helper: ensure Homebrew is installed and up to date ---
ensure_brew() {
  if command -v brew &>/dev/null; then
    echo "  Updating Homebrew..."
    NONINTERACTIVE=1 brew update --quiet 2>/dev/null
    return 0
  fi
  echo ""
  echo "  Installing Homebrew (you may be prompted for your Mac password)..."
  # Homebrew installer needs sudo but we auto-confirm the "Press RETURN" prompt
  echo | /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this session and persist to .zshrc
  if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -f /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  if command -v brew &>/dev/null; then
    if ! grep -q 'brew shellenv' ~/.zshrc 2>/dev/null; then
      echo '' >> ~/.zshrc
      echo '# Homebrew' >> ~/.zshrc
      echo 'eval "$('"$(command -v brew)"' shellenv)"' >> ~/.zshrc
      echo -e "  ${GREEN}✓${NC} Added Homebrew to ~/.zshrc"
    fi
    echo -e "  ${GREEN}✓${NC} Homebrew installed"
    return 0
  else
    echo -e "  ${RED}✗${NC} Homebrew install failed"
    return 1
  fi
}

# --- Step 0: Ensure Homebrew ---
echo "Checking Homebrew..."
ensure_brew

# --- Step 1: Install or update Kiro CLI ---
if command -v kiro-cli &>/dev/null; then
  KIRO_VERSION=$(kiro-cli --version 2>/dev/null || echo "unknown")
  echo -e "${GREEN}✓${NC} Kiro CLI found: $KIRO_VERSION"
  echo "  Updating Kiro CLI..."
  curl -fsSL https://cli.kiro.dev/install | bash 2>&1 | grep -E "complete|already|up.to.date|Installing" | tail -1
  NEW_VERSION=$(kiro-cli --version 2>/dev/null || echo "unknown")
  if [[ "$NEW_VERSION" != "$KIRO_VERSION" ]]; then
    echo -e "  ${GREEN}✓${NC} Updated to $NEW_VERSION"
  else
    echo -e "  ${GREEN}✓${NC} Already on latest ($NEW_VERSION)"
  fi
else
  echo -e "${YELLOW}⚠${NC} Kiro CLI is not installed."
  echo ""
  echo "  Installing Kiro CLI..."
  echo | curl -fsSL https://cli.kiro.dev/install | bash
  echo ""
  # Ensure PATH includes ~/.local/bin
  export PATH="$HOME/.local/bin:$PATH"
  if ! grep -q '\.local/bin' ~/.zshrc 2>/dev/null; then
    echo '' >> ~/.zshrc
    echo '# Kiro CLI' >> ~/.zshrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    echo -e "  ${GREEN}✓${NC} Added ~/.local/bin to PATH in ~/.zshrc"
  fi
  if command -v kiro-cli &>/dev/null; then
    echo -e "${GREEN}✓${NC} Kiro CLI installed: $(kiro-cli --version 2>/dev/null)"
  else
    echo -e "${YELLOW}⚠${NC} Kiro CLI installed but not in PATH yet."
    echo "  Restart your terminal or run: source ~/.zshrc"
  fi
fi
echo ""

# --- Step 2: Check prerequisites ---
echo "Checking prerequisites..."
MISSING=()
if command -v python3 &>/dev/null; then
  PY_VER=$(python3 --version 2>&1)
  echo -e "  ${GREEN}✓${NC} $PY_VER"
else
  echo -e "  ${RED}✗${NC} Python 3 not found"
  MISSING+=("python3")
fi

if command -v node &>/dev/null; then
  NODE_VER=$(node --version 2>&1)
  echo -e "  ${GREEN}✓${NC} Node.js $NODE_VER"
else
  echo -e "  ${RED}✗${NC} Node.js not found"
  MISSING+=("node")
fi

if command -v uvx &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} uvx found"
else
  echo -e "  ${RED}✗${NC} uvx not found"
  MISSING+=("uv")
fi

if command -v npx &>/dev/null; then
  echo -e "  ${GREEN}✓${NC} npx found"
else
  if ! command -v node &>/dev/null; then
    : # already captured as node missing
  else
    echo -e "  ${RED}✗${NC} npx not found"
    MISSING+=("npx")
  fi
fi

if command -v aws &>/dev/null; then
  AWS_VER=$(aws --version 2>&1 | head -1)
  echo -e "  ${GREEN}✓${NC} $AWS_VER"
else
  echo -e "  ${YELLOW}⚠${NC} AWS CLI not found (optional but recommended)"
fi

# Formatters (optional but recommended)
for tool in ruff prettier shfmt delta; do
  if command -v "$tool" &>/dev/null; then
    echo -e "  ${GREEN}✓${NC} $tool found"
  else
    echo -e "  ${YELLOW}⚠${NC} $tool not found (optional — used by formatting hooks)"
    MISSING+=("$tool")
  fi
done

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo ""
  echo -e "${YELLOW}Missing tools:${NC} ${MISSING[*]}"
  echo ""
  echo "  1) Auto-install all missing tools (uses Homebrew)"
  echo "  2) Skip — I'll install them myself"
  echo ""
  read -rp "  Choose [1/2]: " INSTALL_PREREQS
  if [[ "$INSTALL_PREREQS" == "1" ]]; then
    ensure_brew || { echo "Cannot install without Homebrew. Continuing anyway..."; }

    if command -v brew &>/dev/null; then
      for tool in "${MISSING[@]}"; do
        case "$tool" in
          python3)
            echo "  Installing Python..."
            NONINTERACTIVE=1 brew install python 2>&1 | tail -1
            ;;
          node)
            echo "  Installing Node.js..."
            NONINTERACTIVE=1 brew install node 2>&1 | tail -1
            ;;
          uv)
            echo "  Installing uv..."
            curl -LsSf https://astral.sh/uv/install.sh | sh 2>&1 | tail -1
            export PATH="$HOME/.local/bin:$PATH"
            ;;
          npx)
            echo "  npx comes with Node.js — should be available now"
            ;;
          ruff)
            echo "  Installing ruff..."
            NONINTERACTIVE=1 brew install ruff 2>&1 | tail -1
            ;;
          prettier)
            echo "  Installing prettier..."
            npm install -g prettier 2>&1 | tail -1
            ;;
          shfmt)
            echo "  Installing shfmt..."
            NONINTERACTIVE=1 brew install shfmt 2>&1 | tail -1
            ;;
          delta)
            echo "  Installing delta..."
            NONINTERACTIVE=1 brew install git-delta 2>&1 | tail -1
            ;;
        esac
      done
      echo ""
      echo -e "  ${GREEN}✓${NC} Installation complete"
    fi
  else
    echo "  Skipping auto-install."
  fi
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
for f in "$KIRO_DIR/agents"/*.json; do
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
      python3 << 'LEGACY_CLEANUP_EOF'
import json, glob, os

kiro_dir = os.path.expanduser("~/.kiro")
deprecated_mcp = ['code-doc-gen-mcp-server', 'aws-diagram-mcp-server', 'core-mcp-server',
                  'nova-canvas-mcp-server', 'bedrock-data-automation-mcp-server',
                  'aws-msk-mcp-server', 'nova-act', 'fetch']
remap_ts = {'execute_bash': 'shell', 'fs_write': 'write'}
count = 0

for f in glob.glob(os.path.join(kiro_dir, 'agents', '*.json')):
    try:
        with open(f) as fh:
            d = json.load(fh)
    except:
        continue
    modified = False

    # Remove deprecated fields
    for field in ['$schema', 'useLegacyMcpJson']:
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
LEGACY_CLEANUP_EOF
    fi
    echo -e "  ${GREEN}✓${NC} Legacy cleanup complete"
  else
    echo "  Skipping legacy cleanup."
  fi
  echo ""
fi

# --- Step 4: Copy files ---
DIRS=(agents steering skills prompts settings)

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
    cp "$f" "$dest/"
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

# --- Step 4.5: Check env vars and strip MCP servers that need missing keys ---
echo ""
echo "Checking environment variables..."

# Map: env var -> MCP server keys that require it
# Check ~/.zshrc and current env
check_env_var() {
  local var="$1"
  if [[ -n "${!var}" ]]; then
    return 0
  fi
  if grep -q "export $var=" ~/.zshrc 2>/dev/null; then
    return 0
  fi
  return 1
}

GITHUB_SET=false
TWENTY_FIRST_SET=false
FIGMA_SET=false

if check_env_var "GITHUB_PERSONAL_ACCESS_TOKEN"; then
  echo -e "  ${GREEN}✓${NC} GITHUB_PERSONAL_ACCESS_TOKEN is set"
  GITHUB_SET=true
else
  echo -e "  ${YELLOW}⚠${NC} GITHUB_PERSONAL_ACCESS_TOKEN not found"
  read -rp "  Paste your GitHub token (or press Enter to skip): " GH_TOKEN
  if [[ -n "$GH_TOKEN" ]]; then
    echo '' >> ~/.zshrc
    echo "export GITHUB_PERSONAL_ACCESS_TOKEN=\"$GH_TOKEN\"" >> ~/.zshrc
    export GITHUB_PERSONAL_ACCESS_TOKEN="$GH_TOKEN"
    echo -e "  ${GREEN}✓${NC} Added to ~/.zshrc"
    GITHUB_SET=true
  fi
fi

if check_env_var "TWENTY_FIRST_API_KEY"; then
  echo -e "  ${GREEN}✓${NC} TWENTY_FIRST_API_KEY is set"
  TWENTY_FIRST_SET=true
else
  echo -e "  ${YELLOW}⚠${NC} TWENTY_FIRST_API_KEY not found (21st.dev Magic UI generation)"
  read -rp "  Paste your 21st.dev API key (or press Enter to skip): " TF_KEY
  if [[ -n "$TF_KEY" ]]; then
    echo '' >> ~/.zshrc
    echo "export TWENTY_FIRST_API_KEY=\"$TF_KEY\"" >> ~/.zshrc
    export TWENTY_FIRST_API_KEY="$TF_KEY"
    echo -e "  ${GREEN}✓${NC} Added to ~/.zshrc"
    TWENTY_FIRST_SET=true
  fi
fi

if check_env_var "FIGMA_API_KEY"; then
  echo -e "  ${GREEN}✓${NC} FIGMA_API_KEY is set"
  FIGMA_SET=true
else
  echo -e "  ${YELLOW}⚠${NC} FIGMA_API_KEY not found (Figma design-to-code)"
  read -rp "  Paste your Figma API key (or press Enter to skip): " FIGMA_KEY
  if [[ -n "$FIGMA_KEY" ]]; then
    echo '' >> ~/.zshrc
    echo "export FIGMA_API_KEY=\"$FIGMA_KEY\"" >> ~/.zshrc
    export FIGMA_API_KEY="$FIGMA_KEY"
    echo -e "  ${GREEN}✓${NC} Added to ~/.zshrc"
    FIGMA_SET=true
  fi
fi

# --- Step 4.6: Google Workspace MCP setup ---
echo ""
echo "Checking Google Workspace MCP (Google Docs/Sheets/Drive read-only)..."
GOOGLE_MCP_DIR="$HOME/.config/google-drive-mcp"
if [[ -f "$GOOGLE_MCP_DIR/gcp-oauth.keys.json" ]]; then
  echo -e "  ${GREEN}✓${NC} Google OAuth credentials found"
  if [[ -f "$GOOGLE_MCP_DIR/tokens.json" ]]; then
    echo -e "  ${GREEN}✓${NC} Google auth tokens found"
  else
    echo -e "  ${YELLOW}⚠${NC} Tokens not found — running auth..."
    npx -y @piotr-agier/google-drive-mcp auth
  fi
else
  echo -e "  ${YELLOW}⚠${NC} Google Workspace MCP not configured (optional)"
  echo ""
  echo "  To enable Google Docs/Sheets/Drive access:"
  echo "    1. Go to https://console.cloud.google.com"
  echo "    2. Create a project (or use existing)"
  echo "    3. Enable: Google Drive API, Google Docs API, Google Sheets API"
  echo "    4. Configure OAuth consent screen (External, add your email as test user)"
  echo "    5. Create OAuth credentials → Desktop app → Download JSON"
  echo "    6. Place the file at: $GOOGLE_MCP_DIR/gcp-oauth.keys.json"
  echo "    7. Run: npx -y @piotr-agier/google-drive-mcp auth"
  echo ""
  echo "  The google-workspace agent will be disabled until credentials are configured."
  echo ""
  # Disable the google-workspace agent's MCP server since no credentials
  if [[ -f "$KIRO_DIR/agents/google-workspace.json" ]]; then
    python3 -c "
import json
with open('$KIRO_DIR/agents/google-workspace.json') as f:
    d = json.load(f)
d['mcpServers']['google-drive']['disabled'] = True
with open('$KIRO_DIR/agents/google-workspace.json', 'w') as f:
    json.dump(d, f, indent=2, ensure_ascii=False)
    f.write('\n')
print('    Disabled google-drive MCP server (no credentials)')
"
  fi
fi

# Strip MCP servers from installed agents if keys are missing
if ! $GITHUB_SET || ! $TWENTY_FIRST_SET || ! $FIGMA_SET; then
  echo ""
  echo "  Removing MCP servers that require missing API keys..."
  python3 << 'STRIP_MCP_EOF'
import json, glob, os

github_set = os.environ.get("GITHUB_PERSONAL_ACCESS_TOKEN", "") != ""
twenty_first_set = os.environ.get("TWENTY_FIRST_API_KEY", "") != ""
figma_set = os.environ.get("FIGMA_API_KEY", "") != ""
kiro_dir = os.path.expanduser("~/.kiro")
count = 0

for f in glob.glob(os.path.join(kiro_dir, "agents", "*.json")):
    try:
        with open(f) as fh:
            d = json.load(fh)
    except:
        continue
    modified = False
    servers = d.get("mcpServers", {})

    if not github_set:
        for key in list(servers.keys()):
            env = servers[key].get("env", {})
            if "GITHUB_PERSONAL_ACCESS_TOKEN" in str(env):
                del servers[key]
                modified = True

    if not twenty_first_set:
        for key in list(servers.keys()):
            env = servers[key].get("env", {})
            if "TWENTY_FIRST_API_KEY" in str(env):
                del servers[key]
                modified = True

    if not figma_set:
        for key in list(servers.keys()):
            env = servers[key].get("env", {})
            if "FIGMA_API_KEY" in str(env):
                del servers[key]
                modified = True

    if modified:
        with open(f, "w") as fh:
            json.dump(d, fh, indent=2, ensure_ascii=False)
            fh.write("\n")
        count += 1

if count:
    print(f"    Removed unavailable MCP servers from {count} agent(s)")
else:
    print("    No changes needed")
STRIP_MCP_EOF
fi

# --- Step 5: Apply Kiro CLI settings ---
if command -v kiro-cli &>/dev/null && [[ -f "$SCRIPT_DIR/settings/cli.json" ]]; then
  echo ""
  echo "Applying Kiro CLI settings..."
  SCRIPT_DIR="$SCRIPT_DIR" python3 << 'SETTINGS_EOF'
import json, subprocess, os

settings_file = os.path.join(os.environ.get("SCRIPT_DIR", "."), "settings", "cli.json")
try:
    with open(settings_file) as f:
        settings = json.load(f)
except:
    settings = {}

# Settings to always apply (core defaults)
for key, value in settings.items():
    if key == "mcp.loadedBefore":
        continue
    if isinstance(value, bool):
        val_str = "true" if value else "false"
    elif isinstance(value, (int, float)):
        val_str = str(value)
    else:
        val_str = f'"{value}"'
    subprocess.run(["kiro-cli", "settings", key, val_str], capture_output=True)

print("  Applied settings: defaultAgent, defaultModel, subagent, thinking, todoList, etc.")
SETTINGS_EOF
  echo -e "  ${GREEN}✓${NC} Kiro CLI settings configured"
fi

# --- Step 6: Done ---
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║          Installation Complete!          ║"
echo "╚══════════════════════════════════════════╝"
echo ""
if ! $GITHUB_SET || ! $TWENTY_FIRST_SET || ! $FIGMA_SET; then
  echo "To enable all features later, add missing API keys to ~/.zshrc:"
  ! $GITHUB_SET && echo "  export GITHUB_PERSONAL_ACCESS_TOKEN=\"ghp_your_token_here\""
  ! $TWENTY_FIRST_SET && echo "  export TWENTY_FIRST_API_KEY=\"your_21st_dev_key_here\""
  ! $FIGMA_SET && echo "  export FIGMA_API_KEY=\"your_figma_api_key_here\""
  echo "Then re-run ./import.sh to restore the MCP servers."
  echo ""
fi
echo "To start using Kiro CLI:"
echo "  source ~/.zshrc && kiro-cli chat"
echo ""
echo "See README.md for full documentation."
