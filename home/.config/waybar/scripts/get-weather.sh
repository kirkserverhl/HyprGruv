#!/usr/bin/env bash
# Weather for Waybar via wttr.in — city comes from weather-location.sh
# (pin / IP detect / Raleigh, NC). Do not pass a city on the command line;
# theme configs used to hardcode Bengaluru / Bangalore.
set -euo pipefail

LOCATE="${HOME}/.config/hyprgruv/scripts/weather-location.sh"
FALLBACK_CITY="Raleigh,NC"

if [[ -x "$LOCATE" ]]; then
    city="$("$LOCATE" query)"
    label="$("$LOCATE" label)"
    source_kind="$("$LOCATE" status)"
else
    city="$FALLBACK_CITY"
    label="Raleigh, NC"
    source_kind="fallback:${label}"
fi
city="${city:-$FALLBACK_CITY}"

cachedir="${XDG_CACHE_HOME:-$HOME/.cache}/rbn"
cachefile="get-weather.sh-$(printf '%s' "$city" | tr -c 'A-Za-z0-9._-' '_')"
mkdir -p "$cachedir"
[[ -f "$cachedir/$cachefile" ]] || : >"$cachedir/$cachefile"

json_escape() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e ':a;N;$!ba;s/\n/\\n/g'
}

emit() {
    local text="$1" alt="$2" tooltip="$3"
    printf '{"text":"%s","alt":"%s","tooltip":"%s"}\n' \
        "$(json_escape "$text")" \
        "$(json_escape "$alt")" \
        "$(json_escape "$tooltip")"
}

icon_for() {
    local condition_lc
    condition_lc="$(printf '%s' "${1:-}" | tr '[:upper:]' '[:lower:]')"
    case "$condition_lc" in
        "clear"|"sunny") printf '%s' "" ;;
        "partly cloudy") printf '%s' "" ;;
        "cloudy") printf '%s' "" ;;
        "overcast") printf '%s' "" ;;
        "haze") printf '%s' "" ;;
        "fog"|"freezing fog") printf '%s' "" ;;
        "patchy rain possible"|"patchy light drizzle"|"light drizzle"|"patchy light rain"|"light rain"|"light rain shower"|"mist"|"rain")
            printf '%s' "" ;;
        "moderate rain at times"|"moderate rain"|"heavy rain at times"|"heavy rain"|"moderate or heavy rain shower"|"torrential rain shower"|"rain shower")
            printf '%s' "" ;;
        "patchy snow possible"|"patchy sleet possible"|"patchy freezing drizzle possible"|"freezing drizzle"|"heavy freezing drizzle"|"light freezing rain"|"moderate or heavy freezing rain"|"light sleet"|"ice pellets"|"light sleet showers"|"moderate or heavy sleet showers")
            printf '%s' "" ;;
        "blowing snow"|"moderate or heavy sleet"|"patchy light snow"|"light snow"|"light snow showers")
            printf '%s' "" ;;
        "blizzard"|"patchy moderate snow"|"moderate snow"|"patchy heavy snow"|"heavy snow"|"moderate or heavy snow with thunder"|"moderate or heavy snow showers")
            printf '%s' "" ;;
        "thundery outbreaks possible"|"patchy light rain with thunder"|"moderate or heavy rain with thunder"|"patchy light snow with thunder")
            printf '%s' "" ;;
        *) printf '%s' "" ;;
    esac
}

cacheage=$(($(date +%s) - $(stat -c '%Y' "$cachedir/$cachefile")))
if [[ $cacheage -gt 1740 || ! -s $cachedir/$cachefile ]]; then
    # %l location | %C condition text | %t temperature | %c emoji
    data="$(curl -fsS --max-time 8 "https://wttr.in/${city}?format=%l|%C|%t|%c" 2>/dev/null || true)"
    if [[ -n "$data" && "$data" == *"|"* ]]; then
        printf '%s\n' "$data" >"$cachedir/$cachefile"
    fi
fi

if [[ ! -s $cachedir/$cachefile ]]; then
    emit "" "$label" "Weather unavailable (${label})"
    exit 0
fi

IFS='|' read -r place condition_raw temperature _emoji < "$cachedir/$cachefile"
place="${place:-$label}"
temperature="${temperature#+}"
condition="$(icon_for "$condition_raw")"

tooltip="${place}: ${temperature} ${condition_raw}"
tooltip+=$'\n'"${source_kind}"
tooltip+=$'\n'"Left: forecast   Right: set location"

if [[ "$condition" == "" && -z "$temperature" ]]; then
    emit "" "$place" "$tooltip"
else
    emit "${condition} ${temperature}" "$place" "$tooltip"
fi

printf '%s\n' " ${temperature}  \n${condition} ${condition_raw}" >"${HOME}/.cache/.weather_cache"
