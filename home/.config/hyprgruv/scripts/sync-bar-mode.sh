#!/usr/bin/env bash
# Login helper: wait for hyprpm-reload.sh if it is still running, then
# enforce saved bar mode. hyprpm-reload already applies bar mode on success;
# this is a fallback (do not call it 0.6s after login — that races plugins).
set -euo pipefail

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
LOCK="$STATE/hyprpm-reload.lock"

if [[ -f "$LOCK" ]]; then
    i=0
    while [[ -f "$LOCK" ]] && (( i < 60 )); do
        sleep 0.5
        i=$((i + 1))
    done
    # hyprpm-reload applies bar mode itself; skip a second pass if it finished.
    if [[ ! -f "$LOCK" ]]; then
        exit 0
    fi
fi

exec "$HOME/.config/hyprgruv/scripts/apply-bar-mode.sh"