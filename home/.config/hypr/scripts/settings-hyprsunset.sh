#!/usr/bin/env bash
# Hyprsunset controls — toggle, presets, and config editor scaffold.
set -euo pipefail

ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
[[ -d "$SETTINGS_DIR" ]] || SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
ICONS="$SETTINGS_DIR/icons"
CONF="$HOME/.config/hypr/conf/hyprsunset.conf"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
STATE_FILE="$STATE_DIR/hyprsunset-enabled"
mkdir -p "$STATE_DIR"

hyprsunset_running() {
    pgrep -x hyprsunset >/dev/null 2>&1
}

status_text() {
    if hyprsunset_running; then
        echo "on"
    else
        echo "off"
    fi
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

menu=$(
    printf '%b' \
        "Toggle ($(status_text))\0icon\x1f${ICONS}/hyprsunset.png\n" \
        "Warm (4500K)\0icon\x1f${ICONS}/themes.png\n" \
        "Neutral (6500K)\0icon\x1f${ICONS}/settings.png\n" \
        "Cool / Day (9000K)\0icon\x1f${ICONS}/waypaper.png\n" \
        "Off (disable)\0icon\x1f${ICONS}/exit.png\n" \
        "Edit config\0icon\x1f${ICONS}/setup.png\n" \
        "Back\0icon\x1f${ICONS}/back.png\n"
)

chosen=$(printf '%b' "$menu" | rofi -dmenu -i -show-icons -config "$ROFI_CONFIG" -p "Hyprsunset" || true)
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
        stop_hyprsunset
        sleep 0.2
        hyprsunset --temperature 4500 &
        echo "1" >"$STATE_FILE"
        notify-send "Hyprsunset" "Warm preset (4500K)"
        ;;
    "Neutral (6500K)")
        stop_hyprsunset
        sleep 0.2
        hyprsunset --temperature 6500 &
        echo "1" >"$STATE_FILE"
        notify-send "Hyprsunset" "Neutral preset (6500K)"
        ;;
    "Cool / Day (9000K)")
        stop_hyprsunset
        sleep 0.2
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