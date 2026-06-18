#!/usr/bin/env bash
# Ensure ~/.config/hyprgruv is deployed (stow or symlink into repo).
set -euo pipefail

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=../common.sh
source "$HYPR_DIR/lib/common.sh"

DEPLOYED="${HOME}/.config/hyprgruv"
REPO_PKG="${HYPR_DIR}/home/.config/hyprgruv"
PROBE="${DEPLOYED}/scripts/terminal.sh"

if [[ -e "$PROBE" ]]; then
    log_success "Dotfiles present: $DEPLOYED"
    exit 0
fi

log_warning "Missing $DEPLOYED — deploying hyprgruv dotfiles from repo"

mkdir -p "${HOME}/.config"
ln -sfn "$REPO_PKG" "$DEPLOYED"

if [[ -e "$PROBE" ]]; then
    log_success "Linked $DEPLOYED -> $REPO_PKG"
    exit 0
fi

log_error "Failed to deploy dotfiles (expected $PROBE)"
exit 1