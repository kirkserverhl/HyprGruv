#!/usr/bin/env bash
# Start SwayNC notification daemon.

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
"$SCRIPTS/notify-install-user-dbus.sh" 2>/dev/null || true

killall dunst 2>/dev/null || true

if [[ -x "$SCRIPTS/swaync-daemon.sh" ]]; then
    "$SCRIPTS/swaync-daemon.sh" &>/dev/null &
fi

# Apply Zoho quiet hours after the daemon is up (no-op outside the window).
if [[ -x "$HOME/.hyprgruv/lib/scripts/zoho-notify-quiet.sh" ]]; then
    bash "$HOME/.hyprgruv/lib/scripts/zoho-notify-quiet.sh" --apply >/dev/null 2>&1 || true
fi

disown 2>/dev/null || true