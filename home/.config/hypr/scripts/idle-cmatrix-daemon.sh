#!/usr/bin/env bash
#
# Lightweight idle cmatrix daemon.
# Usage: idle-cmatrix-daemon.sh <timeout_seconds> [name]
# Example: idle-cmatrix-daemon.sh 900 home
#          idle-cmatrix-daemon.sh 300 laptop

TIMEOUT=${1:-900}
NAME=${2:-default}

PIDFILE="/tmp/idle-cmatrix-${NAME}.pid"
LOGFILE="/tmp/idle-cmatrix-${NAME}.log"

# If already running, exit
if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    echo "Already running (pid $(cat "$PIDFILE"))" >&2
    exit 0
fi

echo $$ > "$PIDFILE"

echo "[$(date)] Idle cmatrix daemon started (timeout=${TIMEOUT}s, name=${NAME})" >> "$LOGFILE"

cleanup() {
    rm -f "$PIDFILE"
    echo "[$(date)] Daemon stopped" >> "$LOGFILE"
    exit 0
}
trap cleanup EXIT INT TERM

while true; do
    sleep "$TIMEOUT"

    # Check if cmatrix is already running
    if hyprctl clients -j 2>/dev/null | jq -e 'any(.[]; .class == "cmatrix-full")' >/dev/null 2>&1; then
        echo "[$(date)] Cmatrix already running, skipping" >> "$LOGFILE"
        continue
    fi

    echo "[$(date)] Timeout reached, starting cmatrix..." >> "$LOGFILE"
    ~/.config/hypr/scripts/cmatrix-saver.sh
done
