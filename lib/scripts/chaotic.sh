#!/usr/bin/env bash
# chaotic.sh — add Chaotic-AUR key/mirror and pacman.conf
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

display_header "Chaotic-AUR setup"

# ------------------------------------------------------------
# Chaotic key
# ------------------------------------------------------------
log_status "Importing Chaotic-AUR key"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sleep 0.3
sudo pacman-key --lsign-key 3056513887B78AEB
sleep 0.3

# ------------------------------------------------------------
# Chaotic keyring + mirrorlist (pre-repo)
# ------------------------------------------------------------
log_status "Installing chaotic-keyring and chaotic-mirrorlist"
sudo pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
sleep 0.3

# ------------------------------------------------------------
# pacman.conf from repo assets
# ------------------------------------------------------------
ASSET_PACMAN_CONF="$ASSET_DIR/pacman.conf"
if [[ -f "$ASSET_PACMAN_CONF" ]]; then
  TS="$(date +%Y%m%d_%H%M%S)"
  if [[ -f /etc/pacman.conf ]]; then
    sudo cp -a /etc/pacman.conf "/etc/pacman.conf.bak.$TS"
    log_status "Backed up /etc/pacman.conf to /etc/pacman.conf.bak.$TS"
  fi
  log_status "Installing pacman.conf from assets"
  sudo install -m 0644 "$ASSET_PACMAN_CONF" /etc/pacman.conf
else
  log_error "Missing asset: $ASSET_PACMAN_CONF"
  exit 1
fi

# ------------------------------------------------------------
# Sync/refresh after adding repo
# ------------------------------------------------------------
log_status "Refreshing package databases (pacman -Syu)"
sudo pacman -Syu --noconfirm

log_success "Chaotic-AUR configured successfully"
