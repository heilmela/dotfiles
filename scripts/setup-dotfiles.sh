#!/usr/bin/env bash
# setup-dotfiles.sh — idempotent dotfiles bootstrap
# Usage: curl -fsSL https://raw.githubusercontent.com/heilmela/dotfiles/main/scripts/setup-dotfiles.sh | bash



set -euo pipefail

REPO_URL="https://github.com/heilmela/dotfiles.git"
DOTFILES_DIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

dotfiles() {
  git --git-dir="$DOTFILES_DIR" --work-tree="$HOME" "$@"
}

echo "→ Setting up dotfiles..."

# 1. Clone bare repo (idempotent: skip if already present)
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

# 5. macOS: install Homebrew packages
if [[ "$OSTYPE" == "darwin"* ]] && command -v brew >/dev/null 2>&1; then
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
fi

# 6. Ensure Starship init is in shell config (idempotent: only adds if missing)
STARSHIP_INIT='eval "$(starship init zsh)"'
if [ -f "$HOME/.zshrc" ] && ! grep -qF "starship init" "$HOME/.zshrc"; then
  echo "" >> "$HOME/.zshrc"
  echo "$STARSHIP_INIT" >> "$HOME/.zshrc"
  echo "  Added starship init to ~/.zshrc"
fi

# 7. Ensure dotfiles alias is in shell config (idempotent: only adds if missing)
ALIAS_LINE="alias dotfiles='git --git-dir=\$HOME/.dotfiles --work-tree=\$HOME'"
for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
  if [ -f "$rc" ] && ! grep -qF "$ALIAS_LINE" "$rc"; then
    echo "$ALIAS_LINE" >> "$rc"
    echo "  Added dotfiles alias to $rc"
  fi
done

echo "✓ Done. Restart your shell or run: source ~/.zshrc"
echo "  Then use: dotfiles status / dotfiles add / dotfiles commit / dotfiles push"
