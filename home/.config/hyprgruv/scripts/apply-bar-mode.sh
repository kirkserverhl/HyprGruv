#!/usr/bin/env bash
# Login / sync helper — enforce saved bar mode without flipping it.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
BAR_MODE_FILE="$STATE_DIR/bar_mode"
HYPRBARS="/var/cache/hyprpm/kirk/hyprland-plugins/hyprbars.so"

mkdir -p "$STATE_DIR"
rm -f "$STATE_DIR/bar_mode_guard" "$STATE_DIR/bar_mode.lock"

mode="waybar"
if [[ -f "$BAR_MODE_FILE" ]]; then
    mode=$(cat "$BAR_MODE_FILE")
fi
[[ "$mode" == "off" ]] && exit 0

hyprbars_loaded() {
    hyprctl plugin list 2>/dev/null | grep -q "Plugin hyprbars"
}

if [[ "$mode" == "hyprbars" ]]; then
    killall -9 waybar 2>/dev/null || true
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.2
    fi
    hyprctl plugin load "$HYPRBARS" >/dev/null 2>&1 || true
    sleep 0.15
    hyprctl eval 'reapply_hyprbars()' >/dev/null 2>&1 || true
else
    if hyprbars_loaded; then
        hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
    fi
fi