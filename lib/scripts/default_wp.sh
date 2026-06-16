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

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

display_header "Default Wallpaper"

# Respect SKIP_WALLPAPER (handy for non-graphical install phases or laptop testing)
if [[ "${SKIP_WALLPAPER:-0}" == "1" ]]; then
  log_warning "SKIP_WALLPAPER=1 set — skipping wallpaper + matugen step"
  log_status "You can run this manually later from a graphical session:"
  log_status "  bash $0"
  exit 0
fi

# ------------------------------------------------------------
# Ensure Waypaper is installed
# ------------------------------------------------------------
ensure_waypaper_stack() {
  local pkgs=()
  for pkg in awww waypaper waypaper-engine; do
    pacman -Qq "$pkg" &>/dev/null || pkgs+=("$pkg")
  done
  ((${#pkgs[@]})) || return 0

  local official=() aur=()
  for pkg in "${pkgs[@]}"; do
    if pacman -Si "$pkg" &>/dev/null 2>&1; then official+=("$pkg"); else aur+=("$pkg"); fi
  done

  log_status "Installing wallpaper stack: ${pkgs[*]}"
  ((${#official[@]})) && sudo pacman -S --needed --noconfirm "${official[@]}"
  if ((${#aur[@]})); then
    command -v yay >/dev/null 2>&1 || { log_error "yay required for ${aur[*]}"; return 1; }
    yay -S --needed --noconfirm "${aur[@]}"
  fi
}
ensure_waypaper_stack

# ------------------------------------------------------------
# Use the canonical default wallpaper + generate colors with matugen
# Prefer stowed path under $HOME; fall back to repo copy during install
# ------------------------------------------------------------
WALLPAPER="$HOME/Pictures/Wallpapers/default.png"
if [[ ! -f "$WALLPAPER" ]]; then
  WALLPAPER="$HYPR_DIR/home/Pictures/Wallpapers/default.png"
fi

if [[ ! -f "$WALLPAPER" ]]; then
  log_error "Required wallpaper not found: $WALLPAPER"
  exit 1
fi

log_status "Using wallpaper: $(basename "$WALLPAPER")"

# ------------------------------------------------------------
# Ensure matugen (for color scheme generation from wallpaper)
# ------------------------------------------------------------
ensure_matugen() {
  if command -v matugen >/dev/null 2>&1; then
    return 0
  fi
  log_status "Installing matugen…"
  if pacman -Si matugen >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm matugen || return 1
  elif command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm matugen-bin || return 1
  else
    log_error "Install matugen via pacman or matugen-bin (AUR)."
    return 1
  fi
}
ensure_matugen

# Run matugen to generate theme/colors from the wallpaper
log_status "Running matugen on wallpaper (generates ~/.cache/matugen etc.)"
if matugen image "$WALLPAPER"; then
  log_success "matugen completed"
else
  log_warning "matugen exited non-zero (theme files may be partial or need manual re-run)"
fi

log_status "Setting wallpaper via waypaper"

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
