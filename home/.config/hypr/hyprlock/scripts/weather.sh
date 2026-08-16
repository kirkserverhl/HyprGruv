#!/usr/bin/env bash
# Lock-screen weather. Location is shared with Waybar via weather-location.sh
# (pinned city, IP detect, or Raleigh, NC).
set -euo pipefail

LOCATE="${HOME}/.config/hyprgruv/scripts/weather-location.sh"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock-weather"
CACHE_MAX_AGE=900
FALLBACK="Raleigh,NC"

if [[ -x "$LOCATE" ]]; then
    CITY="$("$LOCATE" query)"
else
    CITY="$(grep -oP '^\s*\$CITY\s*=\s*\K.+' "${HOME}/.config/hypr/hyprlock/hyprlock.conf" 2>/dev/null | xargs || true)"
fi
CITY="${CITY:-$FALLBACK}"

mkdir -p "$(dirname "$CACHE")"

if [[ -s "$CACHE" ]]; then
    age=$(($(date +%s) - $(stat -c '%Y' "$CACHE")))
    if ((age <= CACHE_MAX_AGE)); then
        cat "$CACHE"
        exit 0
    fi
fi

weather_info="$(curl -fsS --max-time 6 --fail "https://en.wttr.in/${CITY}?format=%c+%t" 2>/dev/null || true)"
if [[ -z "$weather_info" ]]; then
    if [[ -s "$CACHE" ]]; then
        cat "$CACHE"
        exit 0
    fi
    exit 0
fi

printf '%s\n' "$weather_info" | tee "$CACHE"
