#!/usr/bin/env bash
# Hyprsunset controls — toggle, presets, and config editor scaffold.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/hyprgruv-rofi-grid.sh"

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
export HYPRGRUV_ICONS_DIR="$SETTINGS_DIR/icons"
export HYPRGRUV_ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"

CONF="$HOME/.config/hypr/conf/hyprsunset.conf"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
STATE_FILE="$STATE_DIR/hyprsunset-enabled"
mkdir -p "$STATE_DIR"

hyprsunset_running() { pgrep -x hyprsunset >/dev/null 2>&1; }

status_text() {
    hyprsunset_running && echo "on" || echo "off"
}

start_hyprsunset() {
    if [[ -f "$CONF" ]]; then
        hyprsunset -c "$CONF" &
    else
        hyprsunset --temperature 5500 &
    fi
    echo "1" >"$STATE_FILE"
}

stop_hyprsunset() {
    pkill -x hyprsunset 2>/dev/null || true
    echo "0" >"$STATE_FILE"
}

chosen=$(hyprgruv_rofi_pick "Hyprsunset" \
    "Toggle ($(status_text))|hyprsunset|toggle" \
    "Warm (4500K)|themes|warm" \
    "Neutral (6500K)|settings|neutral" \
    "Cool / Day (9000K)|waypaper|cool" \
    "Off (disable)|exit|off" \
    "Edit config|setup|edit" \
    "Back|back|back") || exit 0
[[ -z "${chosen:-}" ]] && exit 0

case "$chosen" in
    Toggle*)
        if hyprsunset_running; then
            stop_hyprsunset
            notify-send "Hyprsunset" "Disabled"
        else
            start_hyprsunset
            notify-send "Hyprsunset" "Enabled"
        fi
        ;;
    "Warm (4500K)")
        stop_hyprsunset; sleep 0.2
        hyprsunset --temperature 4500 &
        echo "1" >"$STATE_FILE"
        notify-send "Hyprsunset" "Warm preset (4500K)"
        ;;
    "Neutral (6500K)")
        stop_hyprsunset; sleep 0.2
        hyprsunset --temperature 6500 &
        echo "1" >"$STATE_FILE"
        notify-send "Hyprsunset" "Neutral preset (6500K)"
        ;;
    "Cool / Day (9000K)")
        stop_hyprsunset; sleep 0.2
        hyprsunset --temperature 9000 &
        echo "1" >"$STATE_FILE"
        notify-send "Hyprsunset" "Cool preset (9000K)"
        ;;
    "Off (disable)")
        stop_hyprsunset
        notify-send "Hyprsunset" "Disabled"
        ;;
    "Edit config")
        "${EDITOR:-nvim}" "$CONF"
        ;;
    Back)
        exec "$HOME/.config/hypr/scripts/hyprgruv-settings.sh" settings
        ;;
esac