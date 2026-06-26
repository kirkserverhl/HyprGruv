#!/usr/bin/env bash
# Toggle inline date+time module visibility (left-click on clock).
set -euo pipefail

FLAG="${HOME}/.cache/waybar-clock-date-visible"
WEATHER_FLAG="${HOME}/.cache/waybar-weather-visible"

if [ -f "$FLAG" ]; then
  rm -f "$FLAG"
else
  touch "$FLAG"
  rm -f "$WEATHER_FLAG"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true