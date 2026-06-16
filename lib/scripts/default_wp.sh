#!/usr/bin/env bash
# default_wp.sh — apply opening wallpaper + first matugen palette (non-interactive)
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
# Ensure matugen (set_wallpaper.sh uses it for the auto palette)
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

# ------------------------------------------------------------
# Resolve canonical opening wallpaper
# ------------------------------------------------------------
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER="$WALLPAPER_DIR/default.png"
STOWED_DEFAULT="$HYPR_DIR/home/Pictures/Wallpapers/default.png"

mkdir -p "$WALLPAPER_DIR"

if [[ ! -f "$WALLPAPER" && -f "$STOWED_DEFAULT" ]]; then
  cp -a "$STOWED_DEFAULT" "$WALLPAPER"
  log_status "Seeded default wallpaper into $WALLPAPER_DIR"
fi

if [[ ! -f "$WALLPAPER" ]]; then
  WALLPAPER="$STOWED_DEFAULT"
fi

if [[ ! -f "$WALLPAPER" ]]; then
  log_error "Required wallpaper not found: $WALLPAPER"
  exit 1
fi

log_status "Opening wallpaper: $(basename "$WALLPAPER")"

# ------------------------------------------------------------
# Ensure wallpaper daemon is up (waypaper post_command needs it)
# ------------------------------------------------------------
if ! pgrep -f "waypaper-engine.*daemon" >/dev/null 2>&1; then
  if command -v waypaper-engine >/dev/null 2>&1; then
    log_status "Starting waypaper-engine daemon…"
    waypaper-engine daemon &>/dev/null &
    sleep 1.5
  fi
fi

SET_WALLPAPER="$HOME/.config/hypr/scripts/set_wallpaper.sh"

# ------------------------------------------------------------
# Apply wallpaper + first matugen palette (Dark Standard, source color 1)
# set_wallpaper.sh auto-picks the first good source color with tonal-spot.
# SKIP_PALETTE_CHOOSER=1 skips the interactive palette menu on first boot.
# ------------------------------------------------------------
log_status "Applying wallpaper with first matugen palette (non-interactive)"
export SKIP_PALETTE_CHOOSER=1

applied=0
if command -v waypaper >/dev/null 2>&1; then
  if waypaper --wallpaper "$WALLPAPER" --apply >/dev/null 2>&1; then
    applied=1
  elif waypaper --wallpaper "$WALLPAPER" >/dev/null 2>&1; then
    applied=1
  fi
fi

if [[ "$applied" -eq 0 && -x "$SET_WALLPAPER" ]]; then
  log_status "waypaper did not apply — running set_wallpaper.sh directly"
  bash "$SET_WALLPAPER" "$WALLPAPER" || true
  applied=1
fi

if [[ "$applied" -eq 0 ]]; then
  log_error "Failed to set wallpaper with waypaper or set_wallpaper.sh."
  exit 1
fi

# Belt-and-suspenders: ensure the image is visible even if waypaper bookkeeping is odd
if command -v awww >/dev/null 2>&1; then
  awww img "$WALLPAPER" >/dev/null 2>&1 || true
fi

pkill -SIGUSR2 waybar 2>/dev/null || true

log_success "Opening wallpaper applied (Dark Standard + first source color)"
sleep 0.3
clear