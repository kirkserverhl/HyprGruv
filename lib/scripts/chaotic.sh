#!/usr/bin/env bash
# chaotic.sh — add Chaotic-AUR key/mirror and pacman.conf (with mirror hardening)
# Supports DRY_RUN=1 or TEST_MODE=1 for safe simulation (no mutating pacman calls)
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

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

DRY=${DRY_RUN:-${TEST_MODE:-0}}

run_or_echo() {
    if [[ "$DRY" == "1" ]]; then
        echo "[dry-run] $*"
    else
        eval "$@"
    fi
}

echo
display_header "Chaotic-AUR setup"
if [[ "$DRY" == "1" ]]; then
    log_warning "Running in TEST/DRY mode — no actual pacman changes will be made"
fi

# --- Import key ---
log_status "Importing Chaotic-AUR key"
run_or_echo 'sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com'
sleep 0.2
run_or_echo 'sudo pacman-key --lsign-key 3056513887B78AEB'
sleep 0.2

# --- Install keyring + mirrorlist (pre-repo) ---
log_status "Installing chaotic-keyring and chaotic-mirrorlist"
if [[ "$DRY" == "1" ]]; then
    echo "[dry-run] sudo pacman -U --noconfirm \\"
    echo "    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \\"
    echo "    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'"
    CHAOTIC_OK=1   # pretend success for dry sim of later logic
else
    if sudo pacman -U --noconfirm \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
      'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' ; then
        CHAOTIC_OK=1
    else
        CHAOTIC_OK=0
        log_warning "Chaotic bootstrap failed. Skipping repo enable."
    fi
fi

# --- Sanitize mirrorlist: comment out known-bad mirrors ---
MIRRORLIST="/etc/pacman.d/chaotic-mirrorlist"
if [[ -f "$MIRRORLIST" || "$DRY" == "1" ]]; then
  log_status "De-preferring problematic mirrors in $MIRRORLIST"
  # Add more patterns on the right as needed, separated by \|
  run_or_echo 'sudo sed -i -E '\''s|^[[:space:]]*Server[[:space:]]*=[[:space:]]*.*(warp\.dev).*|# &|'\'' '"$MIRRORLIST"
fi

# After installing keyring + mirrorlist (only if we have the file or in dry)
if [[ "$DRY" == "1" || ( -f "$MIRRORLIST" && "${CHAOTIC_OK:-0}" -eq 1 ) ]]; then
  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    run_or_echo 'printf '\''\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n'\'' | sudo tee -a /etc/pacman.conf >/dev/null'
  fi
fi

# Optionally de-prefer flaky mirrors:
run_or_echo 'sudo sed -i -E '\''s|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|'\'' /etc/pacman.d/chaotic-mirrorlist || true'

# Clean + hard refresh
run_or_echo 'sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true'
if [[ "$DRY" != "1" ]]; then
  # In real mode, protect the final sync (don't let one bad chaotic mirror kill everything)
  sudo pacman -Syyu --noconfirm || log_warning "pacman -Syyu had issues (continuing anyway)"
else
  echo "[dry-run] sudo pacman -Syyu --noconfirm"
fi

if [[ "$DRY" == "1" ]]; then
    log_status "TEST MODE complete (no changes performed). Re-run without DRY_RUN=1 / TEST_MODE=1 to apply."
fi
