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

SET_WALLPAPER="$HOME/.config/hyprgruv/scripts/set_wallpaper.sh"

if [[ -n "$wallpaper" ]]; then
    "$APPLY_SCRIPT" "$selected" "$wallpaper" >/dev/null 2>&1
    # Post-command hook: SDDM/default_wp cache + palette.sh (same as waypaper Ctrl+P flow).
    if [[ -x "$SET_WALLPAPER" ]]; then
        SET_WALLPAPER_FORCE_PALETTE=1 "$SET_WALLPAPER" "$wallpaper" >/dev/null 2>&1 &
    fi
else
    "$APPLY_SCRIPT" "$selected" >/dev/null 2>&1
fi