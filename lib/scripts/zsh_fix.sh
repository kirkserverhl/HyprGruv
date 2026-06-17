#!/usr/bin/env bash
# zsh_fix.sh — ensure Oh My Zsh custom plugins (post shell.sh)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
  exit 1
}
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/oh_my_zsh.sh"

if ! oh_my_zsh_installed; then
  log_warning "Oh My Zsh not found (~/.oh-my-zsh). Re-run shell setup or:"
  log_warning "  RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
  exit 0
fi

install_oh_my_zsh_plugins