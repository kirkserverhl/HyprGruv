#!/usr/bin/env bash
# default_wp.sh — opening wallpaper + shipped gruvbox-dark configs (no matugen)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

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

if [[ "${SKIP_WALLPAPER:-0}" == "1" ]]; then
  log_warning "SKIP_WALLPAPER=1 set — skipping wallpaper + default theme seed"
  log_status "You can run this manually later from a graphical session:"
  log_status "  bash $0"
  exit 0
fi

# Wallpaper library must be a real ~/Pictures/Wallpapers (not a stow
# symlink into ~/.hyprgruv — downloads would pollute the git tree).
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

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

SEED="$HYPR_DIR/lib/scripts/seed-default-theme.sh"
if [[ ! -f "$SEED" ]]; then
  log_error "Missing $SEED"
  exit 1
fi

log_status "Seeding shipped gruvbox-dark theme + Arch/Gruvbox wallpaper (no matugen)"
# First install: copy missing live files and set the opening wallpaper.
# Never overwrite an existing live palette (user may have switched themes).
if ! bash "$SEED" --wallpaper; then
  log_warning "seed-default-theme.sh finished with warnings"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true

log_success "Opening wallpaper and gruvbox-dark defaults applied"
sleep 0.3
clear
