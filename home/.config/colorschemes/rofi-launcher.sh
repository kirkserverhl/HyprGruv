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
ACCENT_PICKER="$HOME/.config/hyprgruv/scripts/pick-theme-accent.sh"

if [[ -n "$wallpaper" ]]; then
    # 1) Theme default palette + wallpaper (gruvbox orange, nord frost, …)
    "$APPLY_SCRIPT" "$selected" "$wallpaper" >/dev/null 2>&1
    # 2) SDDM / default_wp only — must finish before accent rebuild (no palette regen)
    if [[ -x "$SET_WALLPAPER" ]]; then
        SET_WALLPAPER_SKIP_PALETTE=1 "$SET_WALLPAPER" "$wallpaper" >/dev/null 2>&1 || true
    else
        notify-send "Theme switcher" "set_wallpaper.sh missing — SDDM default not updated" -u critical 2>/dev/null || true
    fi
    # 3) LAST: accent splotch → write primary/source → full chrome rebuild
    #    (must be last so apply-theme / set_wallpaper cannot re-apply default orange)
    if [[ -x "$ACCENT_PICKER" ]]; then
        bash "$ACCENT_PICKER" "$selected" "$wallpaper" || true
    fi
else
    "$APPLY_SCRIPT" "$selected" >/dev/null 2>&1
    if [[ -x "$ACCENT_PICKER" ]]; then
        bash "$ACCENT_PICKER" "$selected" || true
    fi
fi