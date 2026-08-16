#!/usr/bin/env bash
# Single weather location for Waybar, hyprlock, and helpers.
#
# Resolution:
#   1. Pin in ~/.config/settings/weather_location.sh (user-set)
#   2. Cached IP detect in ~/.local/state/hyprgruv/weather-detected (24h)
#   3. Fresh IP lookup (ip-api / ipinfo / wttr)
#   4. Raleigh, NC
#
# Commands:
#   query|get   wttr path (default)     e.g. Raleigh,NC
#   label       human label             e.g. Raleigh, NC
#   city        city only
#   country     country name
#   status      source + label
#   detect      force network lookup and cache it
#   set <loc>   pin a city (Raleigh, NC / Raleigh+NC / …)
#   ask         rofi: home / detect / type a city
#   open        open wttr.in for the resolved city
#   clear       drop the pin (auto-detect + Raleigh fallback)
set -euo pipefail

DEFAULT_CITY="Raleigh"
DEFAULT_REGION="NC"
DEFAULT_COUNTRY="United States"
DEFAULT_QUERY="Raleigh,NC"
DEFAULT_LABEL="Raleigh, NC"

SETTINGS_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/settings/weather_location.sh"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
CACHE_FILE="${STATE_DIR}/weather-detected"
CACHE_MAX_AGE="${WEATHER_DETECT_MAX_AGE:-86400}"
HYPRLOCK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/hyprlock.conf"
WAYBAR_SIGNAL="${WEATHER_WAYBAR_SIGNAL:-5}"
ROFI_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config-compact.rasi"

mkdir -p "$(dirname "$SETTINGS_FILE")" "$STATE_DIR"

trim() {
    local s="${1:-}"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s' "$s"
}

# "Raleigh, NC" / "Raleigh+NC" / "Raleigh NC" → "Raleigh,NC"
normalize_query() {
    local raw
    raw="$(trim "${1:-}")"
    [[ -n "$raw" ]] || return 1
    raw="${raw//+/ }"
    raw="${raw//;/ }"
    raw="$(printf '%s' "$raw" | tr -s '[:space:]' ' ')"
    raw="${raw//, /,}"
    if [[ "$raw" != *","* ]]; then
        raw="${raw// /,}"
    else
        raw="${raw// /}"
    fi
    printf '%s' "$raw"
}

query_to_label() {
    local q
    q="$(normalize_query "${1:-}")" || return 1
    printf '%s' "${q//,/, }"
}

query_city() {
    local q
    q="$(normalize_query "${1:-}")" || return 1
    printf '%s' "${q%%,*}"
}

query_region() {
    local q rest
    q="$(normalize_query "${1:-}")" || return 1
    rest="${q#*,}"
    if [[ "$rest" == "$q" ]]; then
        return 1
    fi
    printf '%s' "${rest%%,*}"
}

is_us_region() {
    local r="${1:-}"
    [[ "$r" =~ ^[A-Za-z]{2}$ ]]
}

guess_country() {
    local region="${1:-}"
    if is_us_region "$region"; then
        printf '%s' "$DEFAULT_COUNTRY"
        return 0
    fi
    printf '%s' ""
}

read_one_line() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    local line
    line="$(trim "$(head -n1 "$file" 2>/dev/null || true)")"
    [[ -n "$line" ]] || return 1
    printf '%s' "$line"
}

file_age() {
    local file="$1"
    [[ -f "$file" ]] || { printf '%s' "999999"; return 0; }
    printf '%s' "$(($(date +%s) - $(stat -c '%Y' "$file")))"
}

pin_get() {
    local raw
    raw="$(read_one_line "$SETTINGS_FILE")" || return 1
    normalize_query "$raw"
}

pin_set() {
    local query
    query="$(normalize_query "${1:-}")" || return 1
    printf '%s\n' "$query" >"$SETTINGS_FILE"
}

pin_clear() {
    rm -f "$SETTINGS_FILE"
}

cache_get() {
    local raw age
    raw="$(read_one_line "$CACHE_FILE")" || return 1
    age="$(file_age "$CACHE_FILE")"
    if ((age > CACHE_MAX_AGE)); then
        return 1
    fi
    normalize_query "$raw"
}

cache_set() {
    local query
    query="$(normalize_query "${1:-}")" || return 1
    printf '%s\n' "$query" >"$CACHE_FILE"
}

json_field() {
    local json="$1" key="$2"
    command -v jq >/dev/null 2>&1 || return 1
    jq -r --arg k "$key" '.[$k] // empty' <<<"$json" 2>/dev/null
}

json_field_loose() {
    local json="$1" key="$2" val=""
    val="$(json_field "$json" "$key" || true)"
    if [[ -n "$val" && "$val" != "null" ]]; then
        printf '%s' "$val"
        return 0
    fi
    # Fallback when jq is missing: "key":"value"
    val="$(printf '%s' "$json" | sed -n "s/.*\"${key}\"[[:space:]]*:[[:space:]]*\"\\([^\"]*\\)\".*/\\1/p" | head -n1)"
    [[ -n "$val" ]] || return 1
    printf '%s' "$val"
}

detect_from_ip_api() {
    local json city region country
    json="$(curl -fsS --max-time 4 "http://ip-api.com/json/?fields=status,city,region,country" 2>/dev/null || true)"
    [[ -n "$json" ]] || return 1
    if command -v jq >/dev/null 2>&1; then
        [[ "$(jq -r '.status // empty' <<<"$json")" == "success" ]] || return 1
    else
        printf '%s' "$json" | grep -q '"status":"success"' || return 1
    fi
    city="$(json_field_loose "$json" "city" || true)"
    region="$(json_field_loose "$json" "region" || true)"
    country="$(json_field_loose "$json" "country" || true)"
    [[ -n "$city" ]] || return 1
    if [[ -n "$region" ]]; then
        normalize_query "${city},${region}"
    else
        normalize_query "$city"
    fi
    if [[ -n "$country" ]]; then
        DETECTED_COUNTRY="$country"
    fi
}

detect_from_ipinfo() {
    local json city region country
    json="$(curl -fsS --max-time 4 "https://ipinfo.io/json" 2>/dev/null || true)"
    [[ -n "$json" ]] || return 1
    city="$(json_field_loose "$json" "city" || true)"
    region="$(json_field_loose "$json" "region" || true)"
    country="$(json_field_loose "$json" "country" || true)"
    [[ -n "$city" ]] || return 1
    if [[ -n "$region" ]]; then
        # ipinfo region is often "North Carolina" — keep city only + country later
        if is_us_region "$region"; then
            normalize_query "${city},${region}"
        else
            normalize_query "$city"
        fi
    else
        normalize_query "$city"
    fi
    case "${country^^}" in
        US|USA) DETECTED_COUNTRY="$DEFAULT_COUNTRY" ;;
        *) [[ -n "$country" ]] && DETECTED_COUNTRY="$country" ;;
    esac
}

detect_from_wttr() {
    local loc
    loc="$(curl -fsS --max-time 4 "https://wttr.in/?format=%l" 2>/dev/null || true)"
    loc="$(trim "$loc")"
    [[ -n "$loc" && "$loc" != "Unknown location" ]] || return 1
    normalize_query "$loc"
}

detect_query() {
    DETECTED_COUNTRY=""
    detect_from_ip_api && return 0
    detect_from_ipinfo && return 0
    detect_from_wttr && return 0
    return 1
}

sync_hyprlock() {
    local city="$1" country="$2"
    [[ -f "$HYPRLOCK_CONF" ]] || return 0
    local tmp
    tmp="$(mktemp)"
    awk -v city="$city" -v country="$country" '
        BEGIN { done_city=0; done_country=0 }
        /^[[:space:]]*\$CITY[[:space:]]*=/ {
            printf "$CITY         \t\t= %s \n", city
            done_city=1
            next
        }
        /^[[:space:]]*\$COUNTRY[[:space:]]*=/ {
            printf "$COUNTRY      \t\t= %s\n", country
            done_country=1
            next
        }
        { print }
        END {
            if (!done_city) printf "$CITY         \t\t= %s \n", city
            if (!done_country) printf "$COUNTRY      \t\t= %s\n", country
        }
    ' "$HYPRLOCK_CONF" >"$tmp"
    mv "$tmp" "$HYPRLOCK_CONF"
}

refresh_consumers() {
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/rbn/get-weather.sh-"* \
          "${XDG_CACHE_HOME:-$HOME/.cache}/hyprlock-weather" \
          "${HOME}/.cache/.weather_cache" 2>/dev/null || true
    if pgrep -x waybar >/dev/null 2>&1; then
        pkill -RTMIN+"$WAYBAR_SIGNAL" waybar 2>/dev/null || pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
}

resolve() {
    local query country city region
    SOURCE="fallback"
    QUERY="$DEFAULT_QUERY"
    LABEL="$DEFAULT_LABEL"
    CITY="$DEFAULT_CITY"
    COUNTRY="$DEFAULT_COUNTRY"

    if query="$(pin_get)"; then
        SOURCE="pinned"
        QUERY="$query"
    elif query="$(cache_get)"; then
        SOURCE="detected"
        QUERY="$query"
    elif query="$(detect_query)"; then
        SOURCE="detected"
        QUERY="$query"
        cache_set "$QUERY" || true
        if [[ -n "${DETECTED_COUNTRY:-}" ]]; then
            COUNTRY="$DETECTED_COUNTRY"
        fi
    fi

    LABEL="$(query_to_label "$QUERY")"
    CITY="$(query_city "$QUERY")"
    region="$(query_region "$QUERY" || true)"
    if [[ "$SOURCE" != "detected" || -z "${DETECTED_COUNTRY:-}" ]]; then
        country="$(guess_country "$region")"
        [[ -n "$country" ]] && COUNTRY="$country"
    elif [[ -n "${DETECTED_COUNTRY:-}" ]]; then
        COUNTRY="$DETECTED_COUNTRY"
    fi
}

notify_location() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -a Weather -i weather-few-clouds "Weather location" "$msg"
    fi
}

rofi_pick_line() {
    local prompt="$1"
    shift
    printf '%s\n' "$@" | rofi -dmenu -i -p "$prompt" -config "$ROFI_CFG" 2>/dev/null
}

cmd_ask() {
    resolve
    local choice typed query
    if ! command -v rofi >/dev/null 2>&1; then
        notify_location "rofi not found — pin ${DEFAULT_LABEL} in Settings"
        pin_set "$DEFAULT_QUERY"
        sync_hyprlock "$DEFAULT_CITY" "$DEFAULT_COUNTRY"
        refresh_consumers
        return 1
    fi

    choice="$(rofi_pick_line "Weather (${LABEL} · ${SOURCE})" \
        "Raleigh, NC (home)" \
        "Detect from network" \
        "Enter city…" \
        "Clear pin (auto + Raleigh fallback)")" || true
    [[ -n "${choice:-}" ]] || return 0

    case "$choice" in
        "Raleigh, NC (home)")
            pin_set "$DEFAULT_QUERY"
            sync_hyprlock "$DEFAULT_CITY" "$DEFAULT_COUNTRY"
            refresh_consumers
            notify_location "Pinned ${DEFAULT_LABEL}"
            ;;
        "Detect from network")
            if query="$(detect_query)"; then
                cache_set "$query"
                pin_clear
                resolve
                sync_hyprlock "$CITY" "$COUNTRY"
                refresh_consumers
                notify_location "Detected ${LABEL}"
            else
                pin_set "$DEFAULT_QUERY"
                sync_hyprlock "$DEFAULT_CITY" "$DEFAULT_COUNTRY"
                refresh_consumers
                notify_location "Detect failed — using ${DEFAULT_LABEL}"
            fi
            ;;
        "Enter city…")
            typed="$(rofi_pick_line "City (e.g. Raleigh, NC)" "$LABEL")" || true
            typed="$(trim "${typed:-}")"
            if [[ -z "$typed" ]]; then
                return 0
            fi
            pin_set "$typed"
            resolve
            sync_hyprlock "$CITY" "$COUNTRY"
            refresh_consumers
            notify_location "Pinned ${LABEL}"
            ;;
        "Clear pin (auto + Raleigh fallback)")
            pin_clear
            resolve
            sync_hyprlock "$CITY" "$COUNTRY"
            refresh_consumers
            notify_location "Using ${LABEL} (${SOURCE})"
            ;;
    esac
}

cmd_open() {
    resolve
    local url="https://wttr.in/${QUERY}"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
        return 0
    fi
    local browser="${BROWSER:-}"
    if [[ -n "$browser" ]]; then
        "$browser" "$url" >/dev/null 2>&1 &
        return 0
    fi
    notify_location "$url"
}

cmd="${1:-query}"
shift || true

case "$cmd" in
    query|get|"")
        resolve
        printf '%s\n' "$QUERY"
        ;;
    label)
        resolve
        printf '%s\n' "$LABEL"
        ;;
    city)
        resolve
        printf '%s\n' "$CITY"
        ;;
    country)
        resolve
        printf '%s\n' "$COUNTRY"
        ;;
    status)
        resolve
        printf '%s:%s\n' "$SOURCE" "$LABEL"
        ;;
    detect)
        if query="$(detect_query)"; then
            cache_set "$query"
            pin_clear
            resolve
            sync_hyprlock "$CITY" "$COUNTRY"
            refresh_consumers
            printf '%s\n' "$QUERY"
        else
            echo "detect failed" >&2
            exit 1
        fi
        ;;
    set)
        pin_set "${1:-}"
        resolve
        sync_hyprlock "$CITY" "$COUNTRY"
        refresh_consumers
        printf '%s\n' "$QUERY"
        ;;
    ask)
        cmd_ask
        ;;
    open)
        cmd_open
        ;;
    clear)
        pin_clear
        resolve
        sync_hyprlock "$CITY" "$COUNTRY"
        refresh_consumers
        printf '%s\n' "$QUERY"
        ;;
    *)
        echo "usage: $0 {query|label|city|country|status|detect|set|ask|open|clear}" >&2
        exit 2
        ;;
esac
