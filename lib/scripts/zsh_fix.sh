#!/usr/bin/env bash
# zsh_fix.sh — ensure Oh My Zsh plugins are installed (post shell.sh)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
  exit 1
}
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"

ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
PLUGINS_DIR="$ZSH_CUSTOM_DIR/plugins"

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log_warning "Oh My Zsh not found (~/.oh-my-zsh). Skipping zsh plugin fix."
  exit 0
fi

mkdir -p "$PLUGINS_DIR"

clone_plugin() {
  local url="$1" dest="$2" name="$3"
  if [[ -d "$dest" ]]; then
    log_status "$name already installed"
    return 0
  fi
  log_status "Installing $name"
  git clone "$url" "$dest"
}

clone_plugin \
  "https://github.com/zsh-users/zsh-autosuggestions" \
  "$PLUGINS_DIR/zsh-autosuggestions" \
  "zsh-autosuggestions"

clone_plugin \
  "https://github.com/zsh-users/zsh-syntax-highlighting.git" \
  "$PLUGINS_DIR/zsh-syntax-highlighting" \
  "zsh-syntax-highlighting"

clone_plugin \
  "https://github.com/zsh-users/fast-syntax-highlighting.git" \
  "$PLUGINS_DIR/fast-syntax-highlighting" \
  "fast-syntax-highlighting"

log_success "Zsh plugins ready"