#!/usr/bin/env bash
# Launcher for hot corners (smart geometry-aware version)
# Triggers hymission on the real physical bottom corners of your monitors.
# Auto-restarts if the script ever dies.

LOG=/tmp/hyprcorners.log
HOTCORNER_SCRIPT="$HOME/.config/hypr/scripts/hotcorners.sh"

pkill -f 'hotcorners.sh' 2>/dev/null || true
pkill -f '[/]hyprcorners$' 2>/dev/null || true   # kill old cargo version if still around
sleep 0.3

echo "[$(date)] Starting smart hotcorners (geometry-aware, auto-restart)" >> "$LOG"

while true; do
    "$HOTCORNER_SCRIPT" >> "$LOG" 2>&1
    EXIT_CODE=$?
    echo "[$(date)] hotcorners.sh exited with $EXIT_CODE, restarting in 2s..." >> "$LOG"
    sleep 2
done
