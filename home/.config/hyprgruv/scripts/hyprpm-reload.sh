#!/usr/bin/env bash
# hyprpm-reload.sh — load hyprpm plugins once Hyprland's socket is ready.
# Called on session start only (not every config reload — that caused a hyprbars loop).

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/waybar"
GUARD_FILE="$STATE_DIR/bar_mode_guard"

if [[ -f "$GUARD_FILE" ]]; then
    exit 0
fi

if ! command -v hyprpm >/dev/null 2>&1; then
    exit 0
fi

for _ in $(seq 1 50); do
    if hyprctl version >/dev/null 2>&1; then
        hyprpm reload >/dev/null 2>&1 || true
        exit 0
    fi
    sleep 0.2
done

exit 0