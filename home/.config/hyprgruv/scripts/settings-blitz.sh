#!/usr/bin/env bash
# Blitz mode — WORK-focus toggle (not device profile).
# Laptop/desktop decoration baselines come from apply-machine-profile.sh.
# Blitz: strip blur/animations/gaps for deep work; reload restores profile.
# Keyboard: Super+G runs blitz-mode.sh directly (no separate gap toggle).
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

chosen=$(hyprgruv_rofi_pick "Blitz Mode (work focus)" \
    "Enable Blitz|blitz|on" \
    "Disable Blitz (reload)|settings|off" \
    "Status: ${status}|system|status" \
    "Back|back|back") || exit 0
[[ -z "${chosen:-}" ]] && exit 0

case "$chosen" in
    "Enable Blitz")
        if blitz_active; then
            notify-send "Blitz Mode" "Already active (work focus)"
        else
            bash "$BLITZ_SCRIPT"
        fi
        ;;
    "Disable Blitz (reload)")
        hyprctl reload
        notify-send "Blitz Mode" "Off — laptop/desktop decoration profile restored"
        ;;
    Status*)
        if blitz_active; then
            notify-send "Blitz Mode" "Active — blur/anim/gaps off (work)\nDevice profile is separate (laptop light blur vs desktop rich)"
        else
            notify-send "Blitz Mode" "Normal — using machine decoration profile"
        fi
        ;;
    Back)
        exec "$HOME/.config/hyprgruv/scripts/hyprgruv-settings.sh" settings
        ;;
esac