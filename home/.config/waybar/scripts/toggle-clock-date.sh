#!/usr/bin/env bash
# Toggle inline month/date to the left of the clock (left-click).
# Uses waybar custom-module signal RTMIN+4 (see shared/clock.json).
set -euo pipefail

FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-clock-date-visible"
WEATHER_FLAG="${XDG_CACHE_HOME:-$HOME/.cache}/waybar-weather-visible"
mkdir -p "$(dirname "$FLAG")"

if [[ -f "$FLAG" ]]; then
	rm -f "$FLAG"
else
	touch "$FLAG"
	# weather + date share the "expanded clock" slot in some themes
	rm -f "$WEATHER_FLAG"
fi

# Prefer custom signal (fast); fall back to full config reload
if pkill -RTMIN+4 waybar 2>/dev/null; then
	exit 0
fi
pkill -SIGUSR2 waybar 2>/dev/null || true
