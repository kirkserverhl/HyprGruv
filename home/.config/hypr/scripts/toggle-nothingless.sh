#!/usr/bin/env bash
# Simple toggle between NothingLess and Waybar (with last theme from CTRL+W switcher).
# Recommended bind: ALT + SHIFT + N  (or change to whatever you like)

STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/last_layout"
NOTIFY=${NOTIFY:-notify-send}

mkdir -p "$(dirname "$STATE_FILE")"

if pgrep -x nothingless >/dev/null 2>&1; then
    # NothingLess is active → switch to Waybar (last chosen theme)
    pkill -x nothingless 2>/dev/null || true
    sleep 0.1
    ~/.config/waybar/scripts/launch.sh
    [[ "$NOTIFY" = ":" ]] || $NOTIFY "Waybar" "Restored (last theme)"
else
    # Waybar (or nothing) active → switch to NothingLess
    pkill -x waybar 2>/dev/null || true
    sleep 0.1
    echo "nothingless" > "$STATE_FILE"
    nothingless &
    [[ "$NOTIFY" = ":" ]] || $NOTIFY "NothingLess" "Enabled"
fi
