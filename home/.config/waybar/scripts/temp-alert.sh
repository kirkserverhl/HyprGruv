#!/usr/bin/env bash
# Flame next to the Waybar notification bell.
# Hidden until CPU/GPU temp crosses a watch threshold.
#   watch     (orange) — warm enough to keep an eye on
#   critical  (red)    — shut the machine down / stop the load
#   recover   (green)  — stay visible 2 minutes after the last warning
set -euo pipefail

WATCH="${WATCH:-}"
CRITICAL="${CRITICAL:-}"
RECOVER_SECS="${RECOVER_SECS:-120}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
STATE_FILE="${STATE_DIR}/temp-alert-last"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/settings"

read_setting() {
    local file="$1" fallback="$2" value=""
    if [[ -f "$file" ]]; then
        value="$(tr -d '[:space:]' <"$file")"
    fi
    printf '%s' "${value:-$fallback}"
}

[[ -n "$WATCH" ]] || WATCH="$(read_setting "${SETTINGS}/temp_watch.sh" 85)"
[[ -n "$CRITICAL" ]] || CRITICAL="$(read_setting "${SETTINGS}/temp_critical.sh" 95)"

json_escape() {
    printf '%s' "${1:-}" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

emit() {
    local text="$1" class="$2" tooltip="$3"
    printf '{"text":"%s","alt":"%s","class":"%s","tooltip":"%s"}\n' \
        "$(json_escape "$text")" \
        "$(json_escape "$class")" \
        "$(json_escape "$class")" \
        "$(json_escape "$tooltip")"
}

read_temp_c() {
    local namefile dir name input raw max=0
    shopt -s nullglob
    for namefile in /sys/class/hwmon/hwmon*/name; do
        name="$(<"$namefile")"
        dir="$(dirname "$namefile")"
        case "$name" in
            k10temp|coretemp|zenpower|amdgpu|cpu|acpitz|pch_*)
                for input in "$dir"/temp*_input; do
                    raw="$(<"$input")"
                    [[ "$raw" =~ ^[0-9]+$ ]] || continue
                    raw=$((raw / 1000))
                    ((raw > 20 && raw < 125)) || continue
                    ((raw > max)) && max=$raw
                done
                ;;
        esac
    done
    shopt -u nullglob
    if ((max == 0)) && command -v sensors >/dev/null 2>&1; then
        max="$(sensors 2>/dev/null | awk '
            /Tctl:|Tdie:|Package id 0:|^[[:space:]]+edge:/ {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /^\+?[0-9]+(\.[0-9]+)?°C/) {
                        gsub(/[+°C]/, "", $i)
                        if ($i + 0 > m) m = $i + 0
                    }
                }
            }
            END { if (m > 0) printf "%.0f\n", m }
        ')"
        max="${max:-0}"
    fi
    printf '%s' "$max"
}

now="$(date +%s)"
temp="$(read_temp_c)"
[[ "$temp" =~ ^[0-9]+$ ]] || temp=0

last=0
if [[ -f "$STATE_FILE" ]]; then
    last="$(tr -d '[:space:]' <"$STATE_FILE" || true)"
    [[ "$last" =~ ^[0-9]+$ ]] || last=0
fi

class=""
if ((temp >= CRITICAL)); then
    class="critical"
elif ((temp >= WATCH)); then
    class="watch"
elif ((last > 0 && now - last < RECOVER_SECS)); then
    class="recover"
fi

if [[ "$class" == "watch" || "$class" == "critical" ]]; then
    mkdir -p "$STATE_DIR"
    printf '%s\n' "$now" >"$STATE_FILE"
fi

if [[ -z "$class" ]]; then
    emit "" "idle" ""
    exit 0
fi

case "$class" in
    watch)
        tooltip="${temp}°C — watch it (warn ≥${WATCH}°C)"
        tooltip+=$'\n'"Red at ${CRITICAL}°C"
        ;;
    critical)
        tooltip="${temp}°C — cut the load / shut down (crit ≥${CRITICAL}°C)"
        ;;
    recover)
        left=$((RECOVER_SECS - (now - last)))
        ((left < 0)) && left=0
        tooltip="Cooled to ${temp}°C"
        tooltip+=$'\n'"Clearing in ${left}s"
        ;;
esac
tooltip+=$'\n'"Click: auto-cpufreq"

emit "󰈸" "$class" "$tooltip"
