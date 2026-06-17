#!/usr/bin/env bash
# Hide/show all bars (Waybar + Hyprbars). Bound to CTRL+ALT+W.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
BAR_MODE_FILE="$STATE_DIR/bar_mode"
RESTORE_MODE_FILE="$STATE_DIR/bar_mode_before_off"
HYPRBARS="/var/cache/hyprpm/kirk/hyprland-plugins/hyprbars.so"
NOTIFY=${NOTIFY:-notify-send}

mkdir -p "$STATE_DIR"

hyprbars_loaded() {
    hyprctl plugin list 2>/dev/null | grep -q "Plugin hyprbars"
}

waybar_running() {
    pgrep -x waybar >/dev/null 2>&1
}

bars_active() {
    waybar_running || hyprbars_loaded
}

stop_waybar() {
    killall -9 waybar 2>/dev/null || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        waybar_running || break
        sleep 0.05
    done
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
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.2
    fi
    hyprctl plugin load "$HYPRBARS" >/dev/null 2>&1 || true
    sleep 0.15
    hyprctl eval 'reapply_hyprbars()' >/dev/null 2>&1 || true
}

remember_mode_for_restore() {
    local mode="waybar"
    if [[ -f "$BAR_MODE_FILE" ]]; then
        local saved
        saved=$(cat "$BAR_MODE_FILE")
        if [[ "$saved" == "waybar" || "$saved" == "hyprbars" ]]; then
            mode="$saved"
        fi
    fi
    if hyprbars_loaded && ! waybar_running; then
        mode="hyprbars"
    elif waybar_running && ! hyprbars_loaded; then
        mode="waybar"
    fi
    echo "$mode" > "$RESTORE_MODE_FILE"
}

if bars_active; then
    remember_mode_for_restore
    stop_waybar
    unload_hyprbars
    echo "off" > "$BAR_MODE_FILE"
    [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Hidden" -t 1500
else
    restore="waybar"
    if [[ -f "$RESTORE_MODE_FILE" ]]; then
        restore=$(cat "$RESTORE_MODE_FILE")
    fi
    [[ "$restore" == "hyprbars" || "$restore" == "waybar" ]] || restore="waybar"

    echo "$restore" > "$BAR_MODE_FILE"
    if [[ "$restore" == "hyprbars" ]]; then
        stop_waybar
        load_hyprbars
        [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Hyprbars" -t 1500
    else
        unload_hyprbars
        "$HOME/.config/waybar/scripts/launch.sh"
        [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Waybar" -t 1500
    fi
fi