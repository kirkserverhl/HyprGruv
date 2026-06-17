#!/usr/bin/env bash
# Cycle bar mode: Waybar → Hyprbars → None → Waybar (repeat). Bound to ALT+W.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
BAR_MODE_FILE="$STATE_DIR/bar_mode"
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

start_waybar() {
    unload_hyprbars
    sleep 0.1
    "$HOME/.config/waybar/scripts/launch.sh"
}

current_mode() {
    local wb hb
    wb=$(waybar_running && echo 1 || echo 0)
    hb=$(hyprbars_loaded && echo 1 || echo 0)

    if [[ "$wb" == 1 && "$hb" == 0 ]]; then
        echo "waybar"
        return
    fi
    if [[ "$hb" == 1 && "$wb" == 0 ]]; then
        echo "hyprbars"
        return
    fi
    if [[ "$wb" == 0 && "$hb" == 0 ]]; then
        echo "off"
        return
    fi

    # Mixed state — trust saved mode, then clean up on apply.
    if [[ -f "$BAR_MODE_FILE" ]]; then
        local saved
        saved=$(<"$BAR_MODE_FILE")
        [[ "$saved" == "waybar" || "$saved" == "hyprbars" || "$saved" == "off" ]] && {
            echo "$saved"
            return
        }
    fi

    echo "waybar"
}

apply_mode() {
    local mode="$1"

    case "$mode" in
        waybar)
            echo "waybar" >"$BAR_MODE_FILE"
            start_waybar
            [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Waybar" -t 1500
            ;;
        hyprbars)
            echo "hyprbars" >"$BAR_MODE_FILE"
            stop_waybar
            load_hyprbars
            [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Hyprbars" -t 1500
            ;;
        off)
            echo "off" >"$BAR_MODE_FILE"
            stop_waybar
            unload_hyprbars
            [[ "$NOTIFY" = ":" ]] || $NOTIFY "Bar" "Hidden" -t 1500
            ;;
    esac
}

mode=$(current_mode)

case "$mode" in
    waybar)   next="hyprbars" ;;
    hyprbars) next="off" ;;
    off|*)    next="waybar" ;;
esac

apply_mode "$next"