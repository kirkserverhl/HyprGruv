#!/usr/bin/env bash
# hard_copy.sh — copy asset files into $HOME and (optionally) pacman.conf
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from lib/scripts/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1; }
[[ -f "$HYPR_DIR/lib/state.sh"  ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh";  exit 1; }
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

display_header "Hard Copy Files"

# Copy ~/ files from assets/root → $HOME
ROOT_SRC="$ASSET_DIR/root"
if [[ -d "$ROOT_SRC" ]]; then
  log_status "Copying files from $ROOT_SRC → $HOME"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$ROOT_SRC"/ "$HOME"/
  else
    cp -a "$ROOT_SRC"/. "$HOME"/
  fi
  log_success "Home files copied."
else
  log_status "No root assets directory at $ROOT_SRC — skipping copy to \$HOME."
fi

# Optional: seed /etc/pacman.conf from assets (disabled by default)
# Enable by running: UPDATE_PACMAN_CONF=1 ./hard_copy.sh
if [[ "${UPDATE_PACMAN_CONF:-0}" == "1" ]]; then
  ASSET_PACMAN_CONF="$ASSET_DIR/pacman.conf"
  if [[ -f "$ASSET_PACMAN_CONF" ]]; then
    if sudo test -f /etc/pacman.conf; then
      if sudo diff -q /etc/pacman.conf "$ASSET_PACMAN_CONF" >/dev/null 2>&1; then
        log_status "/etc/pacman.conf already matches asset; no changes."
      else
        TS="$(date +%Y%m%d_%H%M%S)"
        sudo cp -a /etc/pacman.conf "/etc/pacman.conf.bak.$TS"
        log_status "Backed up /etc/pacman.conf → /etc/pacman.conf.bak.$TS"
        log_status "Updating /etc/pacman.conf from assets"
        sudo install -m 0644 "$ASSET_PACMAN_CONF" /etc/pacman.conf
        log_success "pacman.conf updated."
      fi
    else
      log_status "Seeding /etc/pacman.conf from assets"
      sudo install -m 0644 "$ASSET_PACMAN_CONF" /etc/pacman.conf
      log_success "pacman.conf installed."
    fi
  else
    log_status "No pacman.conf found at $ASSET_DIR — skipping."
  fi
else
  log_status "Skipping pacman.conf updates (set UPDATE_PACMAN_CONF=1 to enable)."
fi

sleep 0.2
