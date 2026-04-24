#!/usr/bin/env bash
# setup-dotfiles.sh — idempotent dotfiles bootstrap
# Usage: curl -fsSL https://raw.githubusercontent.com/heilmela/dotfiles/main/scripts/setup-dotfiles.sh | bash
#
# NOTE: This script is macOS-only. It assumes Homebrew and macOS conventions
# (Apple Silicon paths, cask packages, etc.). Linux/WSL support is not provided.

set -euo pipefail

if [[ "$OSTYPE" != "darwin"* ]]; then
  echo "✗ This script only supports macOS (detected: $OSTYPE)." >&2
  echo "  Aborting." >&2
  exit 1
fi

REPO_URL="https://github.com/heilmela/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

dotfiles() {
  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

echo "→ Setting up dotfiles..."

# 1. Clone bare repo
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "  Cloning bare repo to $DOTFILES_DIR"
  git clone --bare "$REPO_URL" "$DOTFILES_DIR"
else
  echo "  Bare repo already exists, fetching latest"
  dotfiles fetch origin
fi

# 2. Hide untracked files from status
dotfiles config --local status.showUntrackedFiles no

# 3. Checkout, backing up any conflicts
echo "  Checking out files into \$HOME"
if ! dotfiles checkout 2>/dev/null; then
  echo "  Conflicts detected — backing up to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  dotfiles checkout 2>&1 \
    | grep -E "^\s+\." \
    | awk '{print $1}' \
    | while read -r file; do
        mkdir -p "$BACKUP_DIR/$(dirname "$file")"
        mv "$HOME/$file" "$BACKUP_DIR/$file"
      done
  dotfiles checkout
fi

# 4. Pull latest on re-runs
dotfiles pull origin main 2>/dev/null || true

# 5. Install Homebrew packages
if command -v brew >/dev/null 2>&1; then
  echo "→ Installing Homebrew formulae..."
  brew install --quiet \
    neovim \
    tree-sitter-cli \
    lua-language-server \
    stylua \
    starship

  echo "→ Installing Homebrew casks..."
  brew install --cask --quiet \
    wezterm \
    font-meslo-lg-nerd-font
else
  echo "✗ Homebrew not found. Install from https://brew.sh then re-run this script." >&2
  exit 1
fi

# 6. Patch .zshrc with required init lines (idempotent)
ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"

add_to_zshrc() {
  local marker="$1"
  local line="$2"
  local label="$3"
  if ! grep -qF "$marker" "$ZSHRC"; then
    echo "$line" >> "$ZSHRC"
    echo "  Added $label to ~/.zshrc"
  fi
}

add_to_zshrc "starship init"    'eval "$(starship init zsh)"'                                              "starship init"
add_to_zshrc "HOMEBREW_PREFIX"  'eval "$(/opt/homebrew/bin/brew shellenv)"'                                "homebrew shellenv"
add_to_zshrc ".dotfiles"        "alias dotfiles='git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'"       "dotfiles alias"

echo "✓ Done. Restart your shell or run: source ~/.zshrc"
echo "  Then use: dotfiles status / dotfiles add / dotfiles commit / dotfiles push"
