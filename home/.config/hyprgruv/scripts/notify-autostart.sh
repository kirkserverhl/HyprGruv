#!/usr/bin/env bash
# Start SwayNC notification daemon.

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
"$SCRIPTS/notify-install-user-dbus.sh" 2>/dev/null || true

killall dunst 2>/dev/null || true

if command -v swaync >/dev/null 2>&1; then
    swaync &>/dev/null &
elif [[ -x "$HOME/.local/swaync-root/usr/bin/swaync" ]]; then
    "$HOME/.local/swaync-root/usr/bin/swaync" &>/dev/null &
fi

disown 2>/dev/null || true