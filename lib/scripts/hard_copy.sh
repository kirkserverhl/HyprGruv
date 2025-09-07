#!/usr/bin/env bash
# hard_copy.sh — copy asset files into $HOME and (optionally) pacman.conf
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

display_header "Hard Copy Files"

# ------------------------------------------------------------
# Copy ~/ files from assets/root → $HOME
# ------------------------------------------------------------
ROOT_SRC="$ASSET_DIR/root"

if [[ -d "$ROOT_SRC" ]]; then
  log_status "Copying files from $ROOT_SRC → $HOME"
  # Prefer rsync if available (safer, idempotent), otherwise cp -a
  if command -v rsync >/dev/null 2>&1; then
    rsync -a "$ROOT_SRC"/ "$HOME"/
  else
    cp -a "$ROOT_SRC"/. "$HOME"/
  fi
  log_success "Home files copied."
else
  log_status "No root assets directory at $ROOT_SRC — skipping copy to \$HOME."
fi

# ------------------------------------------------------------
# (Optional) Install /etc/pacman.conf from assets
# NOTE: If chaotic.sh already manages pacman.conf, this will skip
# unless the content actually differs.
# ------------------------------------------------------------
ASSET_PACMAN_CONF="$ASSET_DIR/pacman.conf"
if [[ -f "$ASSET_PACMAN_CONF" ]]; then
  # Only replace if different to avoid unnecessary churn
  if sudo test -f /etc/pacman.conf && sudo diff -q /etc/pacman.conf "$ASSET_PACMAN_CONF" >/dev/null 2>&1; then
    log_status "/etc/pacman.conf matches asset; no changes needed."
  else
    TS="$(date +%Y%m%d_%H%M%S)"
    if sudo test -f /etc/pacman.conf; then
      sudo cp -a /etc/pacman.conf "/etc/pacman.conf.bak.$TS"
      log_status "Backed up /etc/pacman.conf → /etc/pacman.conf.bak.$TS"
    fi
    log_status "Installing pacman.conf from assets"
    sudo install -m 0644 "$ASSET_PACMAN_CONF" /etc/pacman.conf
    log_success "pacman.conf updated."
  fi
else
  log_status "No pacman.conf in assets — skipping."
fi

sleep 0.3
