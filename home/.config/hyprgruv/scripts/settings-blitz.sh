#!/usr/bin/env bash
# Blitz mode — minimal, work-focused Hyprland profile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/hyprgruv-rofi-grid.sh"

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
export HYPRGRUV_ICONS_DIR="$SETTINGS_DIR/icons"
export HYPRGRUV_ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"

BLITZ_SCRIPT="$HOME/.config/hyprgruv/scripts/blitz-mode.sh"

blitz_active() {
    [[ "$(hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1{print $2}')" == "0" ]]
}

status="normal"
blitz_active && status="blitz"

chosen=$(hyprgruv_rofi_pick "Blitz Mode" \
    "Enable Blitz|blitz|on" \
    "Disable Blitz (reload)|settings|off" \
    "Status: ${status}|system|status" \
    "Back|back|back") || exit 0
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
        exec "$HOME/.config/hyprgruv/scripts/hyprgruv-settings.sh" settings
        ;;
esac