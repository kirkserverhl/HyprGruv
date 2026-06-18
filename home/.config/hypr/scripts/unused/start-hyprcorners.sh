#!/usr/bin/env bash
# Launcher for geometry-aware hot corners (auto-restart on crash).

set -euo pipefail

LOG=/tmp/hyprcorners.log
HOTCORNER_SCRIPT="$HOME/.config/hypr/scripts/hotcorners.sh"

pkill -f '[/]start-hyprcorners.sh' 2>/dev/null || true
pkill -f '[/]hotcorners.sh' 2>/dev/null || true
pkill -f '[/]hyprcorners$' 2>/dev/null || true
sleep 0.2

echo "[$(date)] Starting hotcorners watcher" >> "$LOG"

while true; do
    "$HOTCORNER_SCRIPT" >> "$LOG" 2>&1
    code=$?
    echo "[$(date)] hotcorners.sh exited with $code, restarting in 2s..." >> "$LOG"
    sleep 2
done