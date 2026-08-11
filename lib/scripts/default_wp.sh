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
  local need_awww=0
  pacman -Qq awww &>/dev/null || need_awww=1

  if ((need_awww)); then
    log_status "Installing awww…"
    if pacman -Si awww &>/dev/null 2>&1; then
      sudo pacman -S --needed --noconfirm awww
    else
      command -v yay >/dev/null 2>&1 || { log_error "yay required for awww"; return 1; }
      yay -S --needed --noconfirm awww
    fi
  fi

  ensure_waypaper_pkg || return 1
  ensure_aur_pkg waypaper-engine || return 1
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
# Wallpaper library must be a real ~/Pictures/Wallpapers (not a stow
# symlink into ~/.hyprgruv — downloads would pollute the git tree).
# ------------------------------------------------------------
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
ASSET_DEFAULT="$HYPR_DIR/assets/wallpapers/default.png"
STOWED_DEFAULT="$HYPR_DIR/home/Pictures/Wallpapers/default.png"
SETTINGS_DEFAULT="$HYPR_DIR/home/.config/settings/default_wp.png"
SDDM_DEFAULT="$HYPR_DIR/assets/sddm/sugar-candy/sddm-wallpaper.png"

_hyprgruv_ensure_real_wallpaper_dir() {
  if [[ -L "$WALLPAPER_DIR" ]]; then
    local link_target tmp
    link_target="$(readlink -f "$WALLPAPER_DIR" 2>/dev/null || true)"
    if [[ -n "$link_target" && "$link_target" == "$HYPR_DIR"* ]]; then
      log_status "Converting stowed wallpaper symlink → real directory"
      tmp="$(mktemp -d "${TMPDIR:-/tmp}/hyprgruv-wallpapers.XXXXXX")"
      if [[ -d "$link_target" ]]; then
        find "$link_target" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
          -exec cp -a {} "$tmp/" \; 2>/dev/null || true
      fi
      rm -f "$WALLPAPER_DIR"
      mkdir -p "$WALLPAPER_DIR"
      if compgen -G "$tmp/*" >/dev/null 2>&1; then
        cp -a "$tmp"/. "$WALLPAPER_DIR"/
      fi
      rm -rf "$tmp"
    else
      tmp="$(mktemp -d "${TMPDIR:-/tmp}/hyprgruv-wallpapers.XXXXXX")"
      [[ -d "$WALLPAPER_DIR" ]] && cp -a "$WALLPAPER_DIR"/. "$tmp"/ 2>/dev/null || true
      rm -f "$WALLPAPER_DIR"
      mkdir -p "$WALLPAPER_DIR"
      [[ -d "$tmp" ]] && cp -a "$tmp"/. "$WALLPAPER_DIR"/ 2>/dev/null || true
      rm -rf "$tmp"
    fi
  else
    mkdir -p "$WALLPAPER_DIR"
  fi
}
_hyprgruv_ensure_real_wallpaper_dir

_hyprgruv_resolve_opening_wallpaper() {
  local candidate
  for candidate in \
    "$WALLPAPER_DIR/default.png" \
    "$ASSET_DEFAULT" \
    "$STOWED_DEFAULT" \
    "$SETTINGS_DEFAULT" \
    "$SDDM_DEFAULT" \
    "$HOME/.config/settings/default_wp.png"; do
    [[ -f "$candidate" ]] || continue
    echo "$candidate"
    return 0
  done
  find -L "$WALLPAPER_DIR" -maxdepth 1 -type f \
    \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
    2>/dev/null | head -1
}

WALLPAPER="$(_hyprgruv_resolve_opening_wallpaper || true)"
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
  log_error "No opening wallpaper found (expected $WALLPAPER_DIR/default.png or repo seed)"
  exit 1
fi

if [[ "$WALLPAPER" != "$WALLPAPER_DIR/default.png" ]]; then
  cp -a "$WALLPAPER" "$WALLPAPER_DIR/default.png"
  log_status "Seeded default wallpaper into $WALLPAPER_DIR"
  WALLPAPER="$WALLPAPER_DIR/default.png"
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

SET_WALLPAPER="$HOME/.config/hyprgruv/scripts/set_wallpaper.sh"

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