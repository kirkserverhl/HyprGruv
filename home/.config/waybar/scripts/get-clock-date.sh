#!/usr/bin/env bash
# Date + time string shown to the left of the clock (left-click toggle).
set -euo pipefail

FLAG="${HOME}/.cache/waybar-clock-date-visible"

if [ ! -f "$FLAG" ]; then
  echo '{"text":""}'
  exit 0
fi

printf '{"text":"%s"}\n' "$(date +"%B %-d  %H:%M")"