#!/usr/bin/env bash
# mpk-listen.sh — pad listener
#
#   mpk-listen.sh          start in background (or say if already running)
#   mpk-listen.sh status
#   mpk-listen.sh stop
#   mpk-listen.sh -f       foreground (Hyprland autostart)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PY="$SCRIPT_DIR/mpk-midi.py"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
LOG="$LOG_DIR/mpk-listen.log"
RUN_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv"
PIDFILE="$RUN_DIR/mpk-listen.pid"

mkdir -p "$LOG_DIR" "$RUN_DIR"

listener_pid() {
    local pid=""
    if [[ -f "$PIDFILE" ]]; then
        pid="$(tr -d '[:space:]' <"$PIDFILE" || true)"
        if [[ "$pid" =~ ^[0-9]+$ ]] && [[ -r "/proc/${pid}/cmdline" ]]; then
            if tr '\0' ' ' <"/proc/${pid}/cmdline" | grep -q 'mpk-midi.py listen'; then
                printf '%s\n' "$pid"
                return 0
            fi
        fi
        rm -f "$PIDFILE"
    fi
    # Fallback: one python listener, ignore our own shell.
    local p
    for p in $(pgrep -x python3 || true); do
        if [[ -r "/proc/${p}/cmdline" ]] && tr '\0' ' ' <"/proc/${p}/cmdline" | grep -q 'mpk-midi.py listen'; then
            printf '%s\n' "$p"
            return 0
        fi
    done
    return 1
}

cmd="${1:-start}"

case "$cmd" in
    status)
        if pid="$(listener_pid)"; then
            echo "listening  pid=$pid  log=$LOG"
            tail -5 "$LOG" 2>/dev/null || true
            exit 0
        fi
        echo "not running  log=$LOG"
        exit 1
        ;;
    stop)
        if pid="$(listener_pid)"; then
            kill "$pid" 2>/dev/null || true
            rm -f "$PIDFILE"
            echo "stopped $pid"
            exit 0
        fi
        echo "not running"
        exit 0
        ;;
    -f | --foreground)
        if pid="$(listener_pid)"; then
            echo "already listening pid=$pid" >&2
            exit 0
        fi
        echo $$ >"$PIDFILE"
        exec python3 "$PY" listen >>"$LOG" 2>&1
        ;;
    start | "")
        if pid="$(listener_pid)"; then
            echo "already listening  pid=$pid"
            echo "pads: Bank A bottom-left = CALL, next pad = END"
            echo "log:  $LOG"
            echo "stop: ~/.config/hyprgruv/scripts/mpk-listen.sh stop"
            exit 0
        fi
        nohup python3 "$PY" listen >>"$LOG" 2>&1 &
        echo $! >"$PIDFILE"
        echo "started  pid=$!"
        echo "pads: Bank A bottom-left = CALL, next pad = END"
        echo "log:  $LOG"
        echo "This returns to the prompt. Ctrl+C is not needed."
        ;;
    *)
        echo "usage: mpk-listen.sh [start|status|stop|-f]" >&2
        exit 2
        ;;
esac
