#!/usr/bin/env bash
# Start/restart the hotcorners watcher (safe to call on every config reload).

set -euo pipefail

SCRIPT="$HOME/.config/hyprgruv/scripts/hotcorners.sh"
LOG="/tmp/hotcorners.log"
PIDFILE="${XDG_RUNTIME_DIR:-/tmp}/hotcorners.pid"

while read -r pid; do
	[[ "$pid" == "$$" ]] && continue
	kill -9 "$pid" 2>/dev/null || true
done < <(pgrep -f "$SCRIPT" 2>/dev/null || true)

sleep 0.1
rm -f "$PIDFILE"

setsid "$SCRIPT" >> "$LOG" 2>&1 < /dev/null &
echo $! > "$PIDFILE"