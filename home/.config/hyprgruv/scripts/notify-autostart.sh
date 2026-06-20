#!/usr/bin/env bash
# Start the notification daemon chosen in ~/.local/state/notify-daemon

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
"$SCRIPTS/notify-install-user-dbus.sh" 2>/dev/null || true

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/notify-daemon"
daemon="dunst"
[[ -f "$STATE" ]] && daemon="$(tr -d '[:space:]' <"$STATE")"

case "$daemon" in
    swaync)
        killall dunst 2>/dev/null || true
        if command -v swaync >/dev/null 2>&1; then
            swaync &>/dev/null &
        elif [[ -x "$HOME/.local/swaync-root/usr/bin/swaync" ]]; then
            "$HOME/.local/swaync-root/usr/bin/swaync" &>/dev/null &
        fi
        ;;
    *)
        killall swaync 2>/dev/null || true
        dunst &>/dev/null &
        ;;
esac

disown 2>/dev/null || true