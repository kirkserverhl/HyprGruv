#!/usr/bin/env bash
# Laptop / Desktop profile switcher — scaffold for future HyprGruv machine profiles.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/hyprgruv-rofi-grid.sh"

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
export HYPRGRUV_ICONS_DIR="$SETTINGS_DIR/icons"
export HYPRGRUV_ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
PROFILE_FILE="$STATE_DIR/machine-profile"
mkdir -p "$STATE_DIR"

is_laptop() {
    local chassis=""
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        chassis=$(< /sys/class/dmi/id/chassis_type)
        case "$chassis" in
            8|9|10|14) return 0 ;;
        esac
    fi
    [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]
}

detected="desktop"
is_laptop && detected="laptop"

current="(unset)"
[[ -f "$PROFILE_FILE" ]] && current=$(< "$PROFILE_FILE")

chosen=$(hyprgruv_rofi_pick "Laptop / PC  |  active: ${current}" \
    "Laptop Mode|laptop|laptop" \
    "Desktop Mode|system|desktop" \
    "Auto-detect (${detected})|settings|auto" \
    "Back|back|back") || exit 0
[[ -z "${chosen:-}" ]] && exit 0

case "$chosen" in
    "Laptop Mode")
        echo "laptop" >"$PROFILE_FILE"
        notify-send "HyprGruv Settings" "Laptop profile selected (scaffold — not applied yet)"
        ;;
    "Desktop Mode")
        echo "desktop" >"$PROFILE_FILE"
        notify-send "HyprGruv Settings" "Desktop profile selected (scaffold — not applied yet)"
        ;;
    Auto-detect*)
        echo "$detected" >"$PROFILE_FILE"
        notify-send "HyprGruv Settings" "Auto-detected: ${detected} (scaffold — not applied yet)"
        ;;
    Back)
        exec "$HOME/.config/hypr/scripts/hyprgruv-settings.sh" system
        ;;
esac

notify-send -u low "HyprGruv" "Machine profile scaffold — coming soon:
• hibernation / swap sizing
• touchpad & scroll tuning
• fingerprint auth
• waybar + power daemon themes
• dual-monitor dock layouts"