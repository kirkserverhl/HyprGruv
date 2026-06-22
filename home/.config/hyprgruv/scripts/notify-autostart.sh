#!/usr/bin/env bash
# Start SwayNC notification daemon.

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
"$SCRIPTS/notify-install-user-dbus.sh" 2>/dev/null || true

killall dunst 2>/dev/null || true

if [[ -x "$SCRIPTS/swaync-daemon.sh" ]]; then
    "$SCRIPTS/swaync-daemon.sh" &>/dev/null &
fi

disown 2>/dev/null || true