#!/usr/bin/env bash
# Super+W
#
#   Theme tile  → sorted themed wallpapers → source color → static apply
#   Waypaper    → free / all wallpapers + matugen / pywal (optional path only)
#
# Waypaper is never required for a theme switch.

set -euo pipefail

THEME_DIR="$(readlink -f "$HOME/.config/colorschemes")"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"
THEME_PICKER="$THEME_DIR/theme-picker.py"
WALLPAPER_SCRIPT="$THEME_DIR/wallpaper-selector.sh"
WAYPAPER_MODE="__waypaper__"
WAYPAPER_BIN="$HOME/.local/bin/waypaper"
ACCENT_PICKER="$HOME/.config/hyprgruv/scripts/pick-theme-accent.sh"

killall -9 rofi 2>/dev/null || true

# --- theme grid (includes optional Waypaper tile) ---
selected=""
if [[ -f "$THEME_PICKER" ]]; then
    if ! selected=$(python3 "$THEME_PICKER"); then
        exit 1
    fi
fi
[[ -z "$selected" ]] && exit 0

# --- optional: Waypaper for matugen / pywal / all wallpapers ---
if [[ "$selected" == "$WAYPAPER_MODE" ]]; then
    rm -f "$HOME/.config/colorschemes/.active-config" 2>/dev/null || true
    notify-send -e -u low -t 2500 "Waypaper" "All wallpapers · matugen / pywal colors" 2>/dev/null || true
    if [[ -x "$WAYPAPER_BIN" ]]; then
        "$WAYPAPER_BIN" >/dev/null 2>&1 &
    else
        waypaper >/dev/null 2>&1 &
    fi
    exit 0
fi

# --- themed path: sorted wallpapers for this theme only ---
wallpaper=""
if [[ -x "$WALLPAPER_SCRIPT" ]]; then
    picker_err_file=$(mktemp)
    if ! wallpaper=$(THEME_SWITCHER_APPLY=1 "$WALLPAPER_SCRIPT" "$selected" 2>"$picker_err_file"); then
        picker_err=$(head -1 "$picker_err_file" 2>/dev/null || true)
        rm -f "$picker_err_file"
        [[ -z "$picker_err" ]] && picker_err="No wallpapers found for theme"
        notify-send "Wallpaper picker failed" "Could not open picker for: $selected — $picker_err" -u critical
        exit 1
    fi
    rm -f "$picker_err_file"
fi

# --- source / primary color ---
if [[ -x "$ACCENT_PICKER" ]]; then
    if accent=$(bash "$ACCENT_PICKER" "$selected"); then
        notify-send -e -u low -t 1800 "Theme" "$selected · source $accent" 2>/dev/null || true
    else
        rm -f "$THEME_DIR/$selected/user-accent" 2>/dev/null || true
        notify-send -e -u low -t 1800 "Theme" "$selected · default source" 2>/dev/null || true
    fi
fi

# --- one static apply (not matugen extract) ---
notify-send -e -u low -t 2000 "Theme" "Applying $selected…" 2>/dev/null || true
if [[ -n "$wallpaper" && -f "$wallpaper" ]]; then
    apply_cmd=("$APPLY_SCRIPT" "$selected" "$wallpaper")
else
    apply_cmd=("$APPLY_SCRIPT" "$selected")
fi
if ! "${apply_cmd[@]}" >/tmp/hyprgruv-theme-apply.log 2>&1; then
    err=$(tail -5 /tmp/hyprgruv-theme-apply.log 2>/dev/null | tr '\n' ' ')
    notify-send -u critical "Theme apply failed" "${err:-see /tmp/hyprgruv-theme-apply.log}"
    exit 1
fi
