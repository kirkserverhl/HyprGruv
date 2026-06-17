#!/usr/bin/env bash
# Mutually exclusive toggle: Waybar <-> Hyprbars. Bound to ALT+W.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
BAR_MODE_FILE="$STATE_DIR/bar_mode"
LAYOUT_FILE="$STATE_DIR/last_layout"
HYPRBARS="/var/cache/hyprpm/kirk/hyprland-plugins/hyprbars.so"
NOTIFY=${NOTIFY:-notify-send}

mkdir -p "$STATE_DIR"
rm -f "$STATE_DIR/bar_mode_guard" "$STATE_DIR/bar_mode.lock"

hyprbars_loaded() {
    hyprctl plugin list 2>/dev/null | grep -q "Plugin hyprbars"
}

waybar_running() {
    pgrep -x waybar >/dev/null 2>&1
}

full_waybar_running() {
    pgrep -a waybar 2>/dev/null | grep -qE 'themes/(tester|subtle|freshstart|alchemy|velvetline|ultra_minimal)/'
}

stop_waybar() {
    killall -9 waybar 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        waybar_running || break
        sleep 0.05
    done
}

current_mode() {
    if full_waybar_running && ! hyprbars_loaded; then
        echo "waybar"
    elif hyprbars_loaded && ! waybar_running; then
        echo "hyprbars"
    elif [[ -f "$BAR_MODE_FILE" ]]; then
        local saved
        saved=$(cat "$BAR_MODE_FILE")
        if [[ "$saved" == "off" ]]; then
            if [[ -f "$STATE_DIR/bar_mode_before_off" ]]; then
                cat "$STATE_DIR/bar_mode_before_off"
            else
                echo "waybar"
            fi
        else
            echo "$saved"
        fi
    elif hyprbars_loaded; then
        echo "hyprbars"
    else
        echo "waybar"
    fi
}

unload_hyprbars() {
    hyprbars_loaded || return 0
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
    sleep 0.25
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.25
    fi
}

load_hyprbars() {
    # Full unload/load cycle so add_button never stacks on an existing instance.
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.2
    fi
    hyprctl plugin load "$HYPRBARS" >/dev/null 2>&1 || true
    sleep 0.15
    hyprctl eval 'reapply_hyprbars()' >/dev/null 2>&1 || true
}

mode=$(current_mode)

if [[ "$mode" == "waybar" ]]; then
    echo "hyprbars" > "$BAR_MODE_FILE"
    stop_waybar
    load_hyprbars
    [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Hyprbars" -t 1500
else
    echo "waybar" > "$BAR_MODE_FILE"
    pkill -x nothingless 2>/dev/null || true
    if [[ -f "$LAYOUT_FILE" ]] && [[ "$(cat "$LAYOUT_FILE")" == "nothingless" ]]; then
        rm -f "$LAYOUT_FILE"
    fi
    unload_hyprbars
    sleep 0.1
    "$HOME/.config/waybar/scripts/launch.sh"
    [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Waybar" -t 1500
fi