#!/usr/bin/env bash
# chaotic.sh — add Chaotic-AUR key/mirror and pacman.conf (with mirror hardening)
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from lib/scripts/
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

# --- Import key ---
log_status "Importing Chaotic-AUR key"
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sleep 0.2
sudo pacman-key --lsign-key 3056513887B78AEB
sleep 0.2

# --- Install keyring + mirrorlist (pre-repo) ---
log_status "Installing chaotic-keyring and chaotic-mirrorlist"
sudo pacman -U --noconfirm \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
  'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

# --- Sanitize mirrorlist: comment out known-bad mirrors ---
MIRRORLIST="/etc/pacman.d/chaotic-mirrorlist"
if [[ -f "$MIRRORLIST" ]]; then
  log_status "De-preferring problematic mirrors in $MIRRORLIST"
  # Add more patterns on the right as needed, separated by \|
  sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=[[:space:]]*.*(warp\.dev).*|# &|' "$MIRRORLIST"
fi

# After installing keyring + mirrorlist
if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
  printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
fi

# Optionally de-prefer flaky mirrors:
sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' /etc/pacman.d/chaotic-mirrorlist || true

# Clean + hard refresh
sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true
sudo pacman -Syyu --noconfirm

