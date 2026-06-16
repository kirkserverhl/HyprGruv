#!/usr/bin/env bash
# Toggle inline weather module visibility (right-click on clock).
set -euo pipefail

FLAG="${HOME}/.cache/waybar-weather-visible"

if [ -f "$FLAG" ]; then
  rm -f "$FLAG"
else
  touch "$FLAG"
fi

pkill -RTMIN+9 waybar 2>/dev/null || true