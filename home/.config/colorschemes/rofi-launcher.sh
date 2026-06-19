#!/bin/bash
# Super+W theme switcher: theme grid (incl. Waypaper) → wallpaper grid or Waypaper GUI.

THEME_DIR="$(readlink -f "$HOME/.config/colorschemes")"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"
THEME_PICKER="$THEME_DIR/theme-picker.py"
WALLPAPER_SCRIPT="$THEME_DIR/wallpaper-selector.sh"
WAYPAPER_MODE="__waypaper__"
WAYPAPER_BIN="$HOME/.local/bin/waypaper"

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

wallpaper=""
if [[ -x "$WALLPAPER_SCRIPT" ]]; then
    if ! wallpaper=$(THEME_SWITCHER_APPLY=1 "$WALLPAPER_SCRIPT" "$selected"); then
        notify-send "Wallpaper picker failed" "Could not open picker for: $selected" -u critical
        exit 1
    fi
fi

if [[ -n "$wallpaper" ]]; then
    "$APPLY_SCRIPT" "$selected" "$wallpaper" >/dev/null 2>&1
else
    "$APPLY_SCRIPT" "$selected" >/dev/null 2>&1
fi