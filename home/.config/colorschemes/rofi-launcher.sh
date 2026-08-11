#!/usr/bin/env bash
# Super+W — theme → wallpaper → primary accent (splotches) → ONE full apply
#
# Important: do NOT apply the full theme before the accent rofi.
# That painted default orange and blocked the accent UI for a long time.

set -euo pipefail

THEME_DIR="$(readlink -f "$HOME/.config/colorschemes")"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"
THEME_PICKER="$THEME_DIR/theme-picker.py"
WALLPAPER_SCRIPT="$THEME_DIR/wallpaper-selector.sh"
WAYPAPER_MODE="__waypaper__"
WAYPAPER_BIN="$HOME/.local/bin/waypaper"
SET_WALLPAPER="$HOME/.config/hyprgruv/scripts/set_wallpaper.sh"
ACCENT_PICKER="$HOME/.config/hyprgruv/scripts/pick-theme-accent.sh"

killall -9 rofi 2>/dev/null || true

selected=""
if [[ -f "$THEME_PICKER" ]]; then
    if ! selected=$(python3 "$THEME_PICKER"); then
        exit 1
    fi
fi
[[ -z "$selected" ]] && exit 0

if [[ "$selected" == "$WAYPAPER_MODE" ]]; then
    if [[ -x "$WAYPAPER_BIN" ]]; then
        "$WAYPAPER_BIN" >/dev/null 2>&1 &
    else
        waypaper >/dev/null 2>&1 &
    fi
    exit 0
fi

# --- wallpaper (fast) ---
wallpaper=""
if [[ -x "$WALLPAPER_SCRIPT" ]]; then
    picker_err_file=$(mktemp)
    if ! wallpaper=$(THEME_SWITCHER_APPLY=1 "$WALLPAPER_SCRIPT" "$selected" 2>"$picker_err_file"); then
        picker_err=$(head -1 "$picker_err_file")
        rm -f "$picker_err_file"
        [[ -z "$picker_err" ]] && picker_err="No wallpapers found for theme"
        notify-send "Wallpaper picker failed" "Could not open picker for: $selected — $picker_err" -u critical
        exit 1
    fi
    rm -f "$picker_err_file"
fi

# --- primary accent splotches FIRST (fast; only rofi + tiny PNGs) ---
# Writes colorschemes/<theme>/user-accent before any heavy apply.
if [[ -x "$ACCENT_PICKER" ]]; then
    if accent=$(bash "$ACCENT_PICKER" "$selected" ${wallpaper:+"$wallpaper"}); then
        notify-send -e -u low -t 2000 "Theme" "$selected · accent $accent" 2>/dev/null || true
    else
        # Esc = keep theme default primary; clear previous user-accent so default wins
        rm -f "$THEME_DIR/$selected/user-accent" 2>/dev/null || true
        # leave source-color as theme default if present
        notify-send -e -u low -t 2000 "Theme" "$selected · default primary" 2>/dev/null || true
    fi
fi

# --- ONE full theme apply (reads user-accent for primary/source) ---
notify-send -e -u low -t 2500 "Theme" "Applying $selected…" 2>/dev/null || true
if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
    "$APPLY_SCRIPT" "$selected" "$wallpaper" >/dev/null 2>&1 || true
    if [[ -x "$SET_WALLPAPER" ]]; then
        SET_WALLPAPER_SKIP_PALETTE=1 "$SET_WALLPAPER" "$wallpaper" >/dev/null 2>&1 || true
    fi
else
    "$APPLY_SCRIPT" "$selected" >/dev/null 2>&1 || true
fi

notify-send -e -u low "Theme ready" "$selected applied" 2>/dev/null || true
