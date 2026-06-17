#!/usr/bin/env bash
# Laptop / Desktop profile switcher — scaffold for future HyprGruv machine profiles.
#
# Planned:
#   - Laptop detection in welcome wizard (hibernation, touchpad, scrolling, monitor, keyboard)
#   - Swap profiles: hibernation, fingerprint, waybar themes + power daemon
#   - Dual-monitor laptop handling (dock vs lid-closed layouts)
set -euo pipefail

ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
ICONS="$SETTINGS_DIR/icons"
HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
PROFILE_FILE="$STATE_DIR/machine-profile"
mkdir -p "$STATE_DIR"

is_laptop() {
    local chassis=""
    if [[ -r /sys/class/dmi/id/chassis_type ]]; then
        chassis=$(< /sys/class/dmi/id/chassis_type)
        case "$chassis" in
            8|9|10|14) return 0 ;; # portable / laptop / notebook / sub-notebook
        esac
    fi
    [[ -d /sys/class/power_supply/BAT0 || -d /sys/class/power_supply/BAT1 ]]
}

detected="desktop"
is_laptop && detected="laptop"

current="(unset)"
[[ -f "$PROFILE_FILE" ]] && current=$(< "$PROFILE_FILE")

menu=$(
    printf '%b' \
        "Laptop Mode\0icon\x1f${ICONS}/laptop.png\n" \
        "Desktop Mode\0icon\x1f${ICONS}/system.png\n" \
        "Auto-detect (${detected})\0icon\x1f${ICONS}/settings.png\n" \
        "Back\0icon\x1f${ICONS}/back.png\n"
)

chosen=$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -config "$ROFI_CONFIG" -p "Laptop / PC  |  active: ${current}" || true)
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