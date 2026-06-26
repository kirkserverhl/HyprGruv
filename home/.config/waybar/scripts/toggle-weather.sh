#!/usr/bin/env bash
# Toggle inline weather module visibility (right-click on clock).
set -euo pipefail

FLAG="${HOME}/.cache/waybar-weather-visible"
DATE_FLAG="${HOME}/.cache/waybar-clock-date-visible"

if [ -f "$FLAG" ]; then
  rm -f "$FLAG"
else
  touch "$FLAG"
  rm -f "$DATE_FLAG"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true