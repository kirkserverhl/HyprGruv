#!/usr/bin/env bash
# default_wp.sh — set a default wallpaper via Waypaper
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

display_header "Default Wallpaper"

# ------------------------------------------------------------
# Ensure Waypaper is installed
# ------------------------------------------------------------
ensure_waypaper() {
  if command -v waypaper >/dev/null 2>&1; then
    return 0
  fi
  log_status "Installing waypaper…"
  # Try pacman first (if available in repo), fallback to yay (AUR)
  if sudo pacman -Si waypaper >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm waypaper
  elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm waypaper
  else
    log_error "waypaper not found in repos and yay is not installed."
    return 1
  fi
}
ensure_waypaper

# ------------------------------------------------------------
# Pick a wallpaper (prefer space_walk.png; else first image)
# ------------------------------------------------------------
CANDIDATE_DIRS=(
  "$HYPR_DIR/home/wallpaper"
  "$HYPR_DIR/assets/wallpaper"
)
WALLPAPER=""
for d in "${CANDIDATE_DIRS[@]}"; do
  if [[ -f "$d/space_walk.png" ]]; then
    WALLPAPER="$d/space_walk.png"
    break
  fi
done
if [[ -z "${WALLPAPER:-}" ]]; then
  for d in "${CANDIDATE_DIRS[@]}"; do
    if [[ -d "$d" ]]; then
      # first png/jpg/jpeg found
      WALLPAPER="$(find "$d" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | head -n1 || true)"
      [[ -n "$WALLPAPER" ]] && break
    fi
  done
fi

if [[ -z "${WALLPAPER:-}" ]]; then
  log_error "No wallpaper image found in: ${CANDIDATE_DIRS[*]}"
  exit 1
fi

log_status "Setting wallpaper: $(basename "$WALLPAPER")"

# ------------------------------------------------------------
# Apply the wallpaper (support both common Waypaper CLIs)
# ------------------------------------------------------------
if waypaper --wallpaper "$WALLPAPER" --apply >/dev/null 2>&1; then
  :
elif waypaper --wallpaper "$WALLPAPER" >/dev/null 2>&1; then
  :
else
  log_error "Failed to set wallpaper with waypaper."
  exit 1
fi

log_success "Wallpaper applied successfully"
sleep 0.3
clear
