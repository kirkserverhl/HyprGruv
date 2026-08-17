#!/usr/bin/env bash
# seed-default-theme.sh — copy shipped gruvbox-dark defaults (no matugen)
#
# First-install / missing-palette only. Does not overwrite a live theme
# unless --force. git-eod-pull must never pass --force.
#
# Usage:
#   seed-default-theme.sh              # copy missing live files only
#   seed-default-theme.sh --wallpaper  # also set the opening wallpaper
#   seed-default-theme.sh --force      # overwrite live color files (manual restore)

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
DEFAULTS="$HYPR_DIR/lib/defaults/gruvbox-dark"
LIVE_SRC="$DEFAULTS/live"
THEME="gruvbox-dark"
THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/colorschemes/$THEME"
HOME_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPER_NAME="gruvbox_stripes_arch.png"

FORCE=0
SET_WALLPAPER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
  --force) FORCE=1; shift ;;
  --wallpaper) SET_WALLPAPER=1; shift ;;
  -h | --help)
    sed -n '2,12p' "$0"
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [[ ! -d "$DEFAULTS" ]]; then
  echo "seed-default-theme: missing $DEFAULTS" >&2
  exit 1
fi

if [[ -f "$DEFAULTS/wallpaper.name" ]]; then
  WALLPAPER_NAME="$(tr -d '[:space:]' <"$DEFAULTS/wallpaper.name")"
fi

log() { printf 'seed-default-theme: %s\n' "$*"; }

# --- wallpaper files (never overwrite an existing library image on pull) ---
seed_wallpaper_files() {
  local src="" candidate
  for candidate in \
    "$HYPR_DIR/assets/wallpapers/$WALLPAPER_NAME" \
    "$HYPR_DIR/assets/wallpapers/default.png" \
    "$THEME_DIR/wallpapers/$WALLPAPER_NAME" \
    "$HYPR_DIR/home/.config/colorschemes/$THEME/wallpapers/$WALLPAPER_NAME"
  do
    [[ -f "$candidate" ]] || continue
    src="$candidate"
    break
  done
  [[ -n "$src" ]] || {
    log "no shipped wallpaper found"
    return 1
  }

  mkdir -p "$WALLPAPER_DIR" "$HOME_CFG/settings" "$THEME_DIR/wallpapers"

  if [[ ! -f "$WALLPAPER_DIR/$WALLPAPER_NAME" ]]; then
    cp -a "$src" "$WALLPAPER_DIR/$WALLPAPER_NAME"
    log "seeded $WALLPAPER_DIR/$WALLPAPER_NAME"
  fi
  if [[ ! -f "$WALLPAPER_DIR/default.png" ]]; then
    cp -a "$src" "$WALLPAPER_DIR/default.png"
    log "seeded $WALLPAPER_DIR/default.png"
  fi
  if [[ ! -f "$THEME_DIR/wallpapers/$WALLPAPER_NAME" ]]; then
    cp -a "$src" "$THEME_DIR/wallpapers/$WALLPAPER_NAME"
  fi
  if [[ ! -f "$HOME_CFG/settings/default_wp.png" || $FORCE -eq 1 ]]; then
    if [[ $SET_WALLPAPER -eq 1 || $FORCE -eq 1 || ! -f "$HOME_CFG/settings/default_wp.png" ]]; then
      if command -v magick >/dev/null 2>&1; then
        magick "$src" -strip -interlace none -quality 92 "$HOME_CFG/settings/default_wp.png" 2>/dev/null \
          || cp -f "$src" "$HOME_CFG/settings/default_wp.png"
      else
        cp -f "$src" "$HOME_CFG/settings/default_wp.png"
      fi
    fi
  fi
}

# --- theme slot pointers (source color + default wallpaper name) ---
seed_theme_slot() {
  mkdir -p "$THEME_DIR"
  if [[ $FORCE -eq 1 || ! -f "$THEME_DIR/source-color" ]]; then
    [[ -f "$DEFAULTS/source-color" ]] && cp -a "$DEFAULTS/source-color" "$THEME_DIR/source-color"
  fi
  if [[ $FORCE -eq 1 || ! -f "$THEME_DIR/user-accent" ]]; then
    [[ -f "$DEFAULTS/user-accent" ]] && cp -a "$DEFAULTS/user-accent" "$THEME_DIR/user-accent"
  fi
  if [[ $FORCE -eq 1 || ! -f "$THEME_DIR/palette.json" ]]; then
    [[ -f "$DEFAULTS/palette.json" ]] && cp -a "$DEFAULTS/palette.json" "$THEME_DIR/palette.json"
  fi
  if [[ $FORCE -eq 1 || ! -f "$THEME_DIR/default-wallpaper" ]]; then
    printf '%s\n' "$WALLPAPER_NAME" >"$THEME_DIR/default-wallpaper"
  fi

  local current="$HOME_CFG/colorschemes/.current-theme"
  mkdir -p "$(dirname "$current")"
  if [[ $FORCE -eq 1 || ! -f "$current" || -z "$(tr -d '[:space:]' <"$current" 2>/dev/null || true)" ]]; then
    printf '%s\n' "$THEME" >"$current"
  fi
  touch "$HOME_CFG/colorschemes/.use-preset-colors"

  local state="$HOME_CFG/colorschemes/.wallpaper-state"
  local wp="$WALLPAPER_DIR/$WALLPAPER_NAME"
  if [[ -f "$wp" ]] && { [[ $FORCE -eq 1 ]] || ! grep -q "^$THEME:" "$state" 2>/dev/null; }; then
    touch "$state"
    if grep -q "^$THEME:" "$state" 2>/dev/null; then
      sed -i "/^$THEME:/d" "$state"
    fi
    printf '%s:%s\n' "$THEME" "$wp" >>"$state"
  fi
}

# --- copy shipped live outputs (gitignored destinations) ---
copy_live_tree() {
  [[ -d "$LIVE_SRC" ]] || return 0
  local src dest rel copied=0 skipped=0
  while IFS= read -r -d '' src; do
    rel="${src#"$LIVE_SRC"/}"
    dest="$HOME_CFG/$rel"
    if [[ $FORCE -eq 0 && -f "$dest" && -s "$dest" ]]; then
      ((skipped++)) || true
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    ((copied++)) || true
  done < <(find "$LIVE_SRC" -type f -print0)
  log "live files: copied $copied, kept $skipped"
}

# --- optional python writers (still no matugen) ---
run_static_writers() {
  local gen="$HOME_CFG/colorschemes/generate-preset-colors.py"
  [[ -f "$gen" ]] || gen="$HYPR_DIR/home/.config/colorschemes/generate-preset-colors.py"
  [[ -f "$gen" ]] || return 0
  # --seed writes waybar/hypr/rofi/mpv/kitty/starship/nvim from palette.json
  python3 "$gen" --seed "$THEME" >/dev/null 2>&1 || true
}

set_opening_wallpaper() {
  local wp="$WALLPAPER_DIR/$WALLPAPER_NAME"
  [[ -f "$wp" ]] || wp="$WALLPAPER_DIR/default.png"
  [[ -f "$wp" ]] || return 0

  printf '%s\n' "$wp" >"$HOME_CFG/last_wallpaper.txt"
  printf '%s\n' "$wp" >"$HOME_CFG/settings/default" 2>/dev/null || true

  local ini="$HOME_CFG/waypaper/config.ini"
  if [[ -f "$ini" ]]; then
    if grep -q '^wallpaper[[:space:]]*=' "$ini" 2>/dev/null; then
      sed -i "s|^wallpaper[[:space:]]*=.*|wallpaper = $wp|" "$ini"
    else
      printf '\nwallpaper = %s\n' "$wp" >>"$ini"
    fi
  fi

  local ensure="$HYPR_DIR/lib/scripts/ensure-hypr-config.sh"
  [[ -f "$ensure" ]] && bash "$ensure" 2>/dev/null || true
  if [[ -f "$HOME_CFG/hypr/hyprland.lua" ]]; then
    mkdir -p "$HOME_CFG/hypr/hyprlock" 2>/dev/null || true
    if [[ -f "$HOME_CFG/settings/default_wp.png" ]]; then
      ln -sfn "$HOME_CFG/settings/default_wp.png" "$HOME_CFG/hypr/hyprlock/wallpaper" 2>/dev/null || true
    fi
  fi

  # Display only — never call set_wallpaper.sh (that path runs matugen).
  local awww="$HOME_CFG/colorschemes/awww-wallpaper.sh"
  [[ -f "$awww" ]] || awww="$HYPR_DIR/home/.config/colorschemes/awww-wallpaper.sh"
  if command -v awww >/dev/null 2>&1; then
    if [[ -f "$awww" ]]; then
      AWWW_PERSIST=1 bash "$awww" "$wp" all >/dev/null 2>&1 || true
    else
      awww img --resize crop "$wp" >/dev/null 2>&1 || true
    fi
  fi

  local assets="$HOME_CFG/hyprgruv/scripts/apply-desktop-assets.sh"
  if [[ -x "$assets" || -f "$assets" ]]; then
    bash "$assets" "$THEME" >/dev/null 2>&1 || true
  fi

  pkill -SIGUSR2 waybar 2>/dev/null || true
}

seed_wallpaper_files || true
seed_theme_slot
copy_live_tree
if [[ $FORCE -eq 1 || $SET_WALLPAPER -eq 1 ]]; then
  run_static_writers
fi
if [[ $SET_WALLPAPER -eq 1 ]]; then
  set_opening_wallpaper
fi

log "gruvbox-dark defaults ready (source $(tr -d '[:space:]' <"$THEME_DIR/source-color" 2>/dev/null || echo '#689d6a'))"
