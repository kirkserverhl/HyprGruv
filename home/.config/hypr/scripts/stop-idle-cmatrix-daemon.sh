#!/usr/bin/env bash
# Stops idle cmatrix daemons by name (recommended) or all via PID files

NAME=${1:-}

if [[ -z "$NAME" ]]; then
    echo "Usage: stop-idle-cmatrix-daemon.sh <name|all>"
    echo "  Examples:"
    echo "    stop-idle-cmatrix-daemon.sh home"
    echo "    stop-idle-cmatrix-daemon.sh laptop"
    echo "    stop-idle-cmatrix-daemon.sh all"
    exit 1
fi

if [[ "$NAME" == "all" ]]; then
    # Kill everything using PID files (safe)
    for pidfile in /tmp/idle-cmatrix-*.pid; do
        [[ -f "$pidfile" ]] || continue
        pid=$(cat "$pidfile" 2>/dev/null)
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            echo "Stopped daemon from $pidfile"
        fi
        rm -f "$pidfile"
    done
else
    PIDFILE="/tmp/idle-cmatrix-${NAME}.pid"
    if [[ -f "$PIDFILE" ]]; then
        pid=$(cat "$PIDFILE")
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            echo "Stopped idle-cmatrix daemon: $NAME"
        fi
        rm -f "$PIDFILE"
    else
        echo "No daemon found for name: $NAME"
    fi
fi
