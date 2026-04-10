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
