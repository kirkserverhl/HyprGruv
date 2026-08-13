#!/usr/bin/env bash
# system-critical-alert.sh — sticky SwayNC alerts that stay until clicked
#
# Watches temperature, disk, memory, battery, and failed units. When a
# threshold is crossed, a critical notification stays on screen until the
# user clicks it (acknowledgment). After ack, that condition is silent
# until it recovers below the clear threshold and then trips again.
#
# Usage:
#   system-critical-alert              # one check (systemd timer)
#   system-critical-alert --status     # readings vs thresholds
#   system-critical-alert --test       # send a sample sticky alert
#   system-critical-alert --test KEY   # cpu|nvme|disk|memory|battery|units
#   system-critical-alert --ack [KEY]  # record acknowledgment (from click)
#   system-critical-alert --clear      # forget acks and close alerts
#   system-critical-alert --daemon     # loop (if not using the timer)

set -euo pipefail

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
APP_NAME="System"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/system-critical-alert"
CONFIG_FILE="${CONFIG_DIR}/config"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/system-critical-alert"
LOG_FILE="${STATE_DIR}/alert.log"
SOUND_FILE="/usr/share/sounds/freedesktop/stereo/dialog-error.oga"

# Defaults (overridden by config)
CPU_TEMP_CRIT=90
CPU_TEMP_CLEAR=80
NVME_TEMP_CRIT=80
NVME_TEMP_CLEAR=70
GPU_TEMP_CRIT=90
GPU_TEMP_CLEAR=80
DISK_CRIT_PCT=90
DISK_CLEAR_PCT=85
DISK_MOUNTS="/ /home /boot/efi"
MEM_AVAIL_CRIT_PCT=8
MEM_AVAIL_CLEAR_PCT=12
BATTERY_CRIT_PCT=8
BATTERY_CLEAR_PCT=15
BATTERY_ONLY_DISCHARGING=1
CHECK_FAILED_UNITS=1
CHECK_USER_UNITS=0
CHECK_CPU_TEMP=1
CHECK_NVME_TEMP=1
CHECK_GPU_TEMP=1
CHECK_DISK=1
CHECK_MEMORY=1
CHECK_BATTERY=1
DAEMON_INTERVAL=45
PLAY_SOUND=1

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/swaync-persistent-remind.sh"

log() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '%s %s\n' "$ts" "$*" >>"$LOG_FILE"
}

load_config() {
    mkdir -p "$STATE_DIR" "$CONFIG_DIR"
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    fi
    PERSISTENT_NOTIFY_APP_NAME="$APP_NAME"
    persistent_notify_init
}

play_alert_sound() {
    [[ "${PLAY_SOUND:-1}" -eq 1 ]] || return 0
    [[ -f "$SOUND_FILE" ]] || return 0
    if command -v pw-play >/dev/null 2>&1; then
        pw-play "$SOUND_FILE" >/dev/null 2>&1 &
    elif command -v paplay >/dev/null 2>&1; then
        paplay "$SOUND_FILE" >/dev/null 2>&1 &
    elif command -v canberra-gtk-play >/dev/null 2>&1; then
        canberra-gtk-play -f "$SOUND_FILE" >/dev/null 2>&1 &
    fi
}

sanitize_key() {
    local s="$1"
    s="${s//\//-}"
    s="${s// /-}"
    s="${s//[^A-Za-z0-9._-]/_}"
    s="${s#-}"
    printf '%s' "$s"
}

state_path() {
    printf '%s/%s.%s' "$STATE_DIR" "$1" "$2"
}

is_acked() { [[ -f "$(state_path "$1" acked)" ]]; }
is_showing() { [[ -f "$(state_path "$1" id)" ]]; }

mark_ack() {
    local key="$1"
    mkdir -p "$STATE_DIR"
    date -Iseconds >"$(state_path "$key" acked)"
    log "ACK $key"
}

clear_condition() {
    local key="$1"
    local id_file
    id_file="$(state_path "$key" id)"

    if [[ -f "$id_file" ]]; then
        PERSISTENT_NOTIFY_ID_FILE="$id_file"
        persistent_close_notification
    fi

    rm -f "$(state_path "$key" acked)" "$id_file"
}

# Read °C from a hwmon temp*_input (millidegrees).
read_hwmon_c() {
    local path="$1"
    local raw
    [[ -r "$path" ]] || return 1
    raw="$(<"$path")"
    [[ -n "$raw" ]] || return 1
    awk -v n="$raw" 'BEGIN { printf "%.0f", n/1000 }'
}

cpu_package_c() {
    local d label input
    for d in /sys/class/hwmon/hwmon*; do
        [[ -f "$d/name" ]] || continue
        [[ "$(<"$d/name")" == "coretemp" || "$(<"$d/name")" == "k10temp" || "$(<"$d/name")" == "zenpower" ]] || continue
        for label in "$d"/temp*_label; do
            [[ -f "$label" ]] || continue
            if [[ "$(<"$label")" == "Package id 0" || "$(<"$label")" == "Tctl" || "$(<"$label")" == "Tdie" ]]; then
                input="${label%_label}_input"
                read_hwmon_c "$input" && return 0
            fi
        done
        if [[ -f "$d/temp1_input" ]]; then
            read_hwmon_c "$d/temp1_input" && return 0
        fi
    done
    return 1
}

nvme_composite_c() {
    local d label input
    for d in /sys/class/hwmon/hwmon*; do
        [[ -f "$d/name" ]] || continue
        [[ "$(<"$d/name")" == "nvme" ]] || continue
        for label in "$d"/temp*_label; do
            [[ -f "$label" ]] || continue
            if [[ "$(<"$label")" == "Composite" ]]; then
                input="${label%_label}_input"
                read_hwmon_c "$input" && return 0
            fi
        done
        if [[ -f "$d/temp1_input" ]]; then
            read_hwmon_c "$d/temp1_input" && return 0
        fi
    done
    return 1
}

gpu_temp_c() {
    local line
    if command -v nvidia-smi >/dev/null 2>&1; then
        line="$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | head -n1 | tr -d ' ')"
        if [[ "$line" =~ ^[0-9]+$ ]]; then
            printf '%s' "$line"
            return 0
        fi
    fi
    local d label input name
    for d in /sys/class/hwmon/hwmon*; do
        [[ -f "$d/name" ]] || continue
        name="$(<"$d/name")"
        case "$name" in
        amdgpu | i915 | xe | nouveau) ;;
        *) continue ;;
        esac
        for label in "$d"/temp*_label; do
            [[ -f "$label" ]] || continue
            case "$(<"$label")" in
            edge | junction | loc) ;;
            *) continue ;;
            esac
            input="${label%_label}_input"
            read_hwmon_c "$input" && return 0
        done
        if [[ -f "$d/temp1_input" ]]; then
            read_hwmon_c "$d/temp1_input" && return 0
        fi
    done
    return 1
}

mem_available_pct() {
    awk '
        /^MemTotal:/ { t=$2 }
        /^MemAvailable:/ { a=$2 }
        END {
            if (t+0 > 0) printf "%.1f", (a*100)/t
            else exit 1
        }
    ' /proc/meminfo
}

battery_info() {
    local bat cap status
    for bat in /sys/class/power_supply/BAT*; do
        [[ -d "$bat" ]] || continue
        [[ -r "$bat/capacity" ]] || continue
        cap="$(cat "$bat/capacity")"
        status="$(cat "$bat/status" 2>/dev/null || echo Unknown)"
        printf '%s\t%s\t%s\n' "$(basename "$bat")" "$cap" "$status"
        return 0
    done
    return 1
}

failed_unit_lines() {
    local lines="" user_lines=""
    lines="$(systemctl --failed --no-legend --plain --full 2>/dev/null | awk '{print $1}' | sed '/^$/d' || true)"
    if [[ "${CHECK_USER_UNITS:-0}" -eq 1 ]]; then
        user_lines="$(systemctl --user --failed --no-legend --plain --full 2>/dev/null | awk '{print $1}' | sed '/^$/d' || true)"
    fi
    if [[ -n "$lines" && -n "$user_lines" ]]; then
        printf '%s\n%s\n' "$lines" "$user_lines"
    elif [[ -n "$lines" ]]; then
        printf '%s\n' "$lines"
    elif [[ -n "$user_lines" ]]; then
        printf '%s\n' "$user_lines"
    fi
}

# Sticky critical notification. Stays until the user clicks it (default
# action = Acknowledge). Closing the X without clicking is not an ack:
# the next check puts the banner back.
send_sticky() {
    local key="$1" title="$2" body="$3" icon="${4:-dialog-error}"
    local id_file replace_id result new_id first=0

    if is_acked "$key"; then
        return 0
    fi

    persistent_ensure_notification_daemon || {
        log "WARNING: SwayNC unavailable — $key"
        return 1
    }

    id_file="$(state_path "$key" id)"
    replace_id=0
    if [[ -f "$id_file" ]]; then
        replace_id="$(<"$id_file")"
        [[ "$replace_id" =~ ^[0-9]+$ ]] || replace_id=0
    else
        first=1
    fi

    [[ "$first" -eq 1 ]] && play_alert_sound

    body="${body}"$'\n\n'"Click this notification to acknowledge."

    result="$(
        gdbus call --session \
            --dest org.freedesktop.Notifications \
            --object-path /org/freedesktop/Notifications \
            --method org.freedesktop.Notifications.Notify \
            "$APP_NAME" \
            "$replace_id" \
            "$icon" \
            "$title" \
            "$body" \
            "['default', 'Acknowledge']" \
            "{'urgency': <byte 2>, 'category': <'device.error;x-system-critical.${key}'>, 'desktop-entry': <'system-critical-alert'>, 'resident': <true>}" \
            0 2>>"$LOG_FILE"
    )" || {
        log "ERROR: Notify failed for $key"
        return 1
    }

    new_id="$(sed -n 's/.*(uint32 \([0-9]\+\).*/\1/p' <<<"$result")"
    if [[ -z "$new_id" ]]; then
        log "ERROR: could not parse notification id: $result"
        return 1
    fi
    printf '%s\n' "$new_id" >"$id_file"
    mkdir -p "$STATE_DIR/by-id"
    printf '%s\n' "$key" >"$STATE_DIR/by-id/$new_id"
    log "NOTIFIED $key id=$new_id — $title"
}

handle_temp() {
    local key="$1" label="$2" value="$3" crit="$4" clear="$5" icon="$6"

    if [[ -z "$value" ]]; then
        return 0
    fi

    if awk -v v="$value" -v c="$crit" 'BEGIN { exit !(v+0 >= c+0) }'; then
        send_sticky "$key" \
            "Critical: ${label} ${value}°C" \
            "${label} is ${value}°C (threshold ${crit}°C)."$'\n'"The alert stays until you click it." \
            "$icon"
    elif awk -v v="$value" -v c="$clear" 'BEGIN { exit !(v+0 < c+0) }'; then
        if is_acked "$key" || is_showing "$key"; then
            log "recovered $key (${value}°C < ${clear}°C)"
            clear_condition "$key"
        fi
    fi
}

handle_disk() {
    [[ "${CHECK_DISK:-1}" -eq 1 ]] || return 0

    local mount src used_pct avail size key
    declare -A DEVICE_SEEN=()

    # shellcheck disable=SC2086
    for mount in $DISK_MOUNTS; do
        [[ -d "$mount" ]] || continue
        # df -P: filesystem 1024-blocks used available capacity mount
        read -r src _ _ avail used_pct _ < <(df -P -k "$mount" 2>/dev/null | awk 'NR==2 {print $1,$2,$3,$4,$5,$6}')
        [[ -n "$src" ]] || continue
        [[ -n "${DEVICE_SEEN[$src]:-}" ]] && continue
        DEVICE_SEEN[$src]=1

        used_pct="${used_pct%%%}"
        [[ "$used_pct" =~ ^[0-9]+$ ]] || continue

        key="disk-$(sanitize_key "$src")"
        size="$(df -h "$mount" 2>/dev/null | awk 'NR==2 {print $2}')"
        avail="$(df -h "$mount" 2>/dev/null | awk 'NR==2 {print $4}')"

        if ((used_pct >= DISK_CRIT_PCT)); then
            send_sticky "$key" \
                "Critical: disk ${used_pct}% full" \
                "Mount ${mount} (${src}) is ${used_pct}% used."$'\n'"Size ${size} · ${avail} free (threshold ${DISK_CRIT_PCT}%)." \
                "drive-harddisk"
        elif ((used_pct < DISK_CLEAR_PCT)); then
            if is_acked "$key" || is_showing "$key"; then
                log "recovered $key (${used_pct}% < ${DISK_CLEAR_PCT}%)"
                clear_condition "$key"
            fi
        fi
    done
}

handle_memory() {
    [[ "${CHECK_MEMORY:-1}" -eq 1 ]] || return 0
    local avail_pct
    avail_pct="$(mem_available_pct)" || return 0
    local key="memory"

    if awk -v v="$avail_pct" -v c="$MEM_AVAIL_CRIT_PCT" 'BEGIN { exit !(v+0 <= c+0) }'; then
        local pretty
        pretty="$(free -h | awk '/^Mem:/ {print $7 " available of " $2}')"
        send_sticky "$key" \
            "Critical: low memory (${avail_pct}% free)" \
            "Only ${avail_pct}% of RAM is available (threshold ${MEM_AVAIL_CRIT_PCT}%)."$'\n'"${pretty}" \
            "dialog-warning"
    elif awk -v v="$avail_pct" -v c="$MEM_AVAIL_CLEAR_PCT" 'BEGIN { exit !(v+0 >= c+0) }'; then
        if is_acked "$key" || is_showing "$key"; then
            log "recovered $key (${avail_pct}% >= ${MEM_AVAIL_CLEAR_PCT}%)"
            clear_condition "$key"
        fi
    fi
}

handle_battery() {
    [[ "${CHECK_BATTERY:-1}" -eq 1 ]] || return 0
    local info name cap status key="battery"
    info="$(battery_info)" || return 0
    IFS=$'\t' read -r name cap status <<<"$info"
    [[ "$cap" =~ ^[0-9]+$ ]] || return 0

    local discharging=0
    case "${status,,}" in
    discharging | not\ charging) discharging=1 ;;
    esac

    if ((cap <= BATTERY_CRIT_PCT)); then
        if [[ "${BATTERY_ONLY_DISCHARGING:-1}" -eq 1 && "$discharging" -eq 0 ]]; then
            return 0
        fi
        send_sticky "$key" \
            "Critical: battery ${cap}%" \
            "${name} is at ${cap}% (${status})."$'\n'"Threshold ${BATTERY_CRIT_PCT}%." \
            "battery-caution"
    elif ((cap >= BATTERY_CLEAR_PCT)); then
        if is_acked "$key" || is_showing "$key"; then
            log "recovered $key (${cap}% >= ${BATTERY_CLEAR_PCT}%)"
            clear_condition "$key"
        fi
    fi
}

handle_units() {
    [[ "${CHECK_FAILED_UNITS:-1}" -eq 1 ]] || return 0
    local key="units" list count
    list="$(failed_unit_lines || true)"
    if [[ -z "$list" ]]; then
        if is_acked "$key" || is_showing "$key"; then
            log "recovered $key (no failed units)"
            clear_condition "$key"
        fi
        return 0
    fi
    count="$(printf '%s\n' "$list" | sed '/^$/d' | wc -l | tr -d ' ')"
    send_sticky "$key" \
        "Critical: ${count} failed systemd unit(s)" \
        "$(printf '%s\n' "$list" | head -n 8)" \
        "dialog-error"
}

run_checks() {
    local value
    if [[ "${CHECK_CPU_TEMP:-1}" -eq 1 ]]; then
        value="$(cpu_package_c || true)"
        handle_temp cpu "CPU" "$value" "$CPU_TEMP_CRIT" "$CPU_TEMP_CLEAR" "temperature-normal"
    fi
    if [[ "${CHECK_NVME_TEMP:-1}" -eq 1 ]]; then
        value="$(nvme_composite_c || true)"
        handle_temp nvme "NVMe" "$value" "$NVME_TEMP_CRIT" "$NVME_TEMP_CLEAR" "drive-harddisk"
    fi
    if [[ "${CHECK_GPU_TEMP:-1}" -eq 1 ]]; then
        value="$(gpu_temp_c || true)"
        handle_temp gpu "GPU" "$value" "$GPU_TEMP_CRIT" "$GPU_TEMP_CLEAR" "video-display"
    fi
    handle_disk
    handle_memory
    handle_battery
    handle_units
}

cmd_status() {
    local value
    echo "Config:  ${CONFIG_FILE}"
    echo "State:   ${STATE_DIR}"
    echo "SwayNC:  timeout-critical must be 0 (never expire)"
    echo

    printf '%-12s %-10s %-10s %s\n' "CHECK" "VALUE" "CRIT" "STATE"
    value="$(cpu_package_c || echo n/a)"
    printf '%-12s %-10s %-10s %s\n' "CPU °C" "$value" "$CPU_TEMP_CRIT" "$(cond_state cpu "$value" ge "$CPU_TEMP_CRIT")"
    value="$(nvme_composite_c || echo n/a)"
    printf '%-12s %-10s %-10s %s\n' "NVMe °C" "$value" "$NVME_TEMP_CRIT" "$(cond_state nvme "$value" ge "$NVME_TEMP_CRIT")"
    value="$(gpu_temp_c || echo n/a)"
    printf '%-12s %-10s %-10s %s\n' "GPU °C" "$value" "$GPU_TEMP_CRIT" "$(cond_state gpu "$value" ge "$GPU_TEMP_CRIT")"
    value="$(mem_available_pct || echo n/a)"
    printf '%-12s %-10s %-10s %s\n' "Mem avail%" "$value" "<=${MEM_AVAIL_CRIT_PCT}" "$(cond_state memory "$value" le "$MEM_AVAIL_CRIT_PCT")"

    local mount src used_pct
    # shellcheck disable=SC2086
    for mount in $DISK_MOUNTS; do
        [[ -d "$mount" ]] || continue
        read -r src _ _ _ used_pct _ < <(df -P -k "$mount" 2>/dev/null | awk 'NR==2 {print $1,$2,$3,$4,$5,$6}')
        used_pct="${used_pct%%%}"
        printf '%-12s %-10s %-10s %s\n' "disk $mount" "${used_pct}%" "$DISK_CRIT_PCT" "$(cond_state "disk-$(sanitize_key "$src")" "$used_pct" ge "$DISK_CRIT_PCT")"
    done

    local info name cap status
    if info="$(battery_info)"; then
        IFS=$'\t' read -r name cap status <<<"$info"
        printf '%-12s %-10s %-10s %s\n' "battery" "${cap}% ${status}" "$BATTERY_CRIT_PCT" "$(cond_state battery "$cap" le "$BATTERY_CRIT_PCT")"
    else
        printf '%-12s %-10s %-10s %s\n' "battery" "n/a" "$BATTERY_CRIT_PCT" "—"
    fi

    local units
    units="$(failed_unit_lines || true)"
    if [[ -n "$units" ]]; then
        printf '%-12s %-10s %-10s %s\n' "units" "$(printf '%s\n' "$units" | wc -l | tr -d ' ') failed" "any" "$(cond_state units 1 ge 1)"
        printf '%s\n' "$units" | sed 's/^/  - /'
    else
        printf '%-12s %-10s %-10s %s\n' "units" "none" "any" "ok"
    fi
}

cond_state() {
    local key="$1" value="$2" op="$3" crit="$4"
    if [[ "$value" == "n/a" ]]; then
        echo "n/a"
        return
    fi
    local over=0
    case "$op" in
    ge) awk -v v="$value" -v c="$crit" 'BEGIN { exit !(v+0 >= c+0) }' && over=1 ;;
    le) awk -v v="$value" -v c="$crit" 'BEGIN { exit !(v+0 <= c+0) }' && over=1 ;;
    esac
    if is_acked "$key"; then
        echo "acknowledged"
    elif is_showing "$key"; then
        echo "on screen (click to ack)"
    elif [[ "$over" -eq 1 ]]; then
        echo "CRITICAL"
    else
        echo "ok"
    fi
}

cmd_test() {
    local kind="${1:-demo}"
    case "$kind" in
    cpu | temp)
        send_sticky cpu "Critical: CPU 97°C (test)" \
            "Test alert — CPU would be 97°C (threshold ${CPU_TEMP_CRIT}°C)." \
            "temperature-normal"
        ;;
    nvme)
        send_sticky nvme "Critical: NVMe 84°C (test)" \
            "Test alert — NVMe would be 84°C (threshold ${NVME_TEMP_CRIT}°C)." \
            "drive-harddisk"
        ;;
    disk)
        send_sticky "disk-test" "Critical: disk 96% full (test)" \
            "Test alert — / would be 96% used (threshold ${DISK_CRIT_PCT}%)." \
            "drive-harddisk"
        ;;
    memory | mem)
        send_sticky memory "Critical: low memory (test)" \
            "Test alert — only 4% of RAM would be available." \
            "dialog-warning"
        ;;
    battery)
        send_sticky battery "Critical: battery 5% (test)" \
            "Test alert — battery would be at 5% (Discharging)." \
            "battery-caution"
        ;;
    units)
        send_sticky units "Critical: 1 failed systemd unit(s) (test)" \
            "example-failed.service" \
            "dialog-error"
        ;;
    demo | test | "")
        send_sticky demo "Critical: system alert (test)" \
            "This is a sticky SwayNC alert."$'\n'"It stays until you click it."$'\n'"Temperature, disk, memory, battery, and failed units use this same path." \
            "dialog-error"
        ;;
    *)
        echo "Unknown test key: $kind (cpu|nvme|disk|memory|battery|units|demo)" >&2
        exit 1
        ;;
    esac
    echo "Sent sticky test alert. Click the notification to acknowledge."
}

lookup_key_from_swaync() {
    local cat="${SWAYNC_CATEGORY:-}" nid
    if [[ "$cat" == *x-system-critical.* ]]; then
        printf '%s' "${cat##*x-system-critical.}" | cut -d';' -f1
        return 0
    fi
    for nid in "${SWAYNC_ID:-}" "${SWAYNC_REPLACES_ID:-}"; do
        [[ -n "$nid" && -f "$STATE_DIR/by-id/$nid" ]] || continue
        cat "$STATE_DIR/by-id/$nid"
        return 0
    done
    return 1
}

cmd_ack() {
    local key="${1:-}"
    if [[ -z "$key" ]]; then
        key="$(lookup_key_from_swaync || true)"
    fi
    if [[ -z "$key" ]]; then
        echo "[ERROR] --ack needs a key (or SWAYNC_* env from SwayNC)" >&2
        log "ack missing key category=${SWAYNC_CATEGORY:-} id=${SWAYNC_ID:-}"
        exit 1
    fi
    mark_ack "$key"
    local id_file
    id_file="$(state_path "$key" id)"
    if [[ -f "$id_file" ]]; then
        PERSISTENT_NOTIFY_ID_FILE="$id_file"
        persistent_close_notification
    fi
}

cmd_clear() {
    local f key
    declare -A seen=()
    for f in "$STATE_DIR"/*.acked "$STATE_DIR"/*.id; do
        [[ -e "$f" ]] || continue
        key="$(basename "$f")"
        key="${key%.*}"
        [[ -n "${seen[$key]:-}" ]] && continue
        seen[$key]=1
        clear_condition "$key"
    done
    echo "Cleared acknowledgments and closed system-critical alerts."
    log "cleared all"
}

cmd_daemon() {
    log "daemon start interval=${DAEMON_INTERVAL}s"
    while true; do
        run_checks || true
        sleep "$DAEMON_INTERVAL"
    done
}

usage() {
    cat <<'EOF'
Usage: system-critical-alert [command]

Commands:
  (none)         Check thresholds once (used by the systemd timer)
  status         Print current readings vs thresholds
  test [kind]    Send a sample sticky alert (demo|cpu|nvme|disk|memory|battery|units)
  ack [key]      Record acknowledgment (also run when you click the banner)
  clear          Forget acks and close any open system-critical alerts
  daemon         Loop checks (optional; prefer the user timer)
  help           Show this help

Critical alerts stay on screen until you click them. After a click, that
condition stays silent until it recovers, then it can fire again.

Config: ~/.config/system-critical-alert/config
Logs:   ~/.local/state/system-critical-alert/alert.log
EOF
}

main() {
    load_config
    local cmd="${1:-check}"
    shift || true

    case "$cmd" in
    check | run | "") run_checks ;;
    status) cmd_status ;;
    test) cmd_test "${1:-demo}" ;;
    ack | --ack) cmd_ack "${1:-}" ;;
    --ack=*) cmd_ack "${cmd#--ack=}" ;;
    clear) cmd_clear ;;
    daemon) cmd_daemon ;;
    -h | --help | help) usage ;;
    *)
        echo "Unknown command: $cmd" >&2
        usage
        exit 1
        ;;
    esac
}

main "$@"
