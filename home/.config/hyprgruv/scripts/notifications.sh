#!/usr/bin/env bash
# Unified notification dispatcher — reads ~/.local/state/notify-daemon

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/notify-daemon"

active_daemon() {
    if [[ -f "$STATE" ]]; then
        tr -d '[:space:]' <"$STATE"
        return
    fi
    echo dunst
}

daemon="$(active_daemon)"

case "$daemon" in
    swaync)
        exec "$SCRIPTS/swaync.sh" "$@"
        ;;
    dunst|*)
        case "${1:-}" in
            toggle-pause|toggle|dnd)
                dunstctl set-paused toggle
                ;;
            close-all|close)
                dunstctl close-all
                ;;
            *)
                exec "$SCRIPTS/dunst.sh" "$@"
                ;;
        esac
        ;;
esac