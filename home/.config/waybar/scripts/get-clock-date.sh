#!/usr/bin/env bash
# Month + day shown to the LEFT of the clock when expanded (left-click toggle).
# Empty when collapsed so hide-empty-text keeps the time module stationary.
set -euo pipefail

FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clock-date-visible"

if [[ ! -f "$FLAG" ]]; then
	printf '%s\n' '{"text":"","class":"collapsed"}'
	exit 0
fi

# Full month + day, trailing space so it sits cleanly left of HH:MM
printf '{"text":"%s ","class":"expanded"}\n' "$(date +'%B %-d')"
