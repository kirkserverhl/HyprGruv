#!/usr/bin/env bash
# hyprpm-reload.sh — load hyprpm plugins once Hyprland's socket is ready.
# Safe to call from config.reloaded (initial parse or hyprctl reload).

set -euo pipefail

if ! command -v hyprpm >/dev/null 2>&1; then
	exit 0
fi

# hyprpm talks to the compositor over the hyprctl socket; during first config
# parse that socket may not exist yet — wait briefly, then bail instead of hang.
for _ in $(seq 1 50); do
	if hyprctl version >/dev/null 2>&1; then
		hyprpm reload >/dev/null 2>&1 || true
		exit 0
	fi
	sleep 0.2
done

exit 0