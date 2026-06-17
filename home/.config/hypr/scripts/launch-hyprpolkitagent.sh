#!/usr/bin/env bash
# Start Hyprland's polkit authentication agent (single instance).

set -euo pipefail

AGENT=/usr/lib/hyprpolkitagent/hyprpolkitagent

if [[ ! -x "$AGENT" ]]; then
	echo "hyprpolkitagent not found at $AGENT" >&2
	exit 1
fi

if pgrep -f "$AGENT" >/dev/null 2>&1; then
	exit 0
fi

exec "$AGENT"