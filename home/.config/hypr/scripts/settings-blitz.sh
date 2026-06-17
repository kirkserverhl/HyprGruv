#!/usr/bin/env bash
# Blitz mode — minimal, work-focused Hyprland profile.
set -euo pipefail

ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
ICONS="$SETTINGS_DIR/icons"
BLITZ_SCRIPT="$HOME/.config/hypr/scripts/blitz-mode.sh"

blitz_active() {
    [[ "$(hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1{print $2}')" == "0" ]]
}

status="normal"
blitz_active && status="blitz"

menu=$(
    printf '%b' \
        "Enable Blitz\0icon\x1f${ICONS}/blitz.png\n" \
        "Disable Blitz (reload)\0icon\x1f${ICONS}/settings.png\n" \
        "Status: ${status}\0icon\x1f${ICONS}/system.png\n" \
        "Back\0icon\x1f${ICONS}/back.png\n"
)

chosen=$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -config "$ROFI_CONFIG" -p "Blitz Mode" || true)
[[ -z "${chosen:-}" ]] && exit 0

case "$chosen" in
    "Enable Blitz")
        if blitz_active; then
            notify-send "Blitz Mode" "Already active"
        else
            bash "$BLITZ_SCRIPT"
            notify-send "Blitz Mode" "Enabled — animations/blur/gaps off"
        fi
        ;;
    "Disable Blitz (reload)")
        hyprctl reload
        notify-send "Blitz Mode" "Disabled — config reloaded"
        ;;
    Status*)
        if blitz_active; then
            notify-send "Blitz Mode" "Active (animations disabled)"
        else
            notify-send "Blitz Mode" "Normal (full effects)"
        fi
        ;;
    Back)
        exec "$HOME/.config/hypr/scripts/hyprgruv-settings.sh" settings
        ;;
esac