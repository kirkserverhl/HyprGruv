#!/bin/bash
# Alt+T theme switcher: GTK theme grid → GTK wallpaper grid → apply theme.

THEME_DIR="$(readlink -f "$HOME/.config/colorschemes")"
APPLY_SCRIPT="$THEME_DIR/apply-theme.sh"
THEME_PICKER="$THEME_DIR/theme-picker.py"
WALLPAPER_SCRIPT="$THEME_DIR/wallpaper-selector.sh"

selected=""
if [[ -f "$THEME_PICKER" ]]; then
    if ! selected=$(python3 "$THEME_PICKER"); then
        exit 1
    fi
fi

[[ -z "$selected" ]] && exit 0

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