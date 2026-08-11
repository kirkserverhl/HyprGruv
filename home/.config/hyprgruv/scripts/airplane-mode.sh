#!/usr/bin/env bash
# airplane-mode.sh — toggle airplane mode (Wi‑Fi + Bluetooth via rfkill / nmcli)
set -euo pipefail

notify() {
    local title="$1" body="$2" icon="${3:-network-wireless-offline}"
    notify-send -e -u low -i "$icon" \
        -h string:x-canonical-private-synchronous:airplane \
        "$title" "$body" 2>/dev/null || true
}

wifi_blocked() {
    if command -v nmcli >/dev/null 2>&1; then
        nmcli -t -f WIFI general 2>/dev/null | grep -qi 'disabled\|off' && return 0
        nmcli radio wifi 2>/dev/null | grep -qi 'disabled\|off' && return 0
    fi
    if command -v rfkill >/dev/null 2>&1; then
        rfkill list wifi 2>/dev/null | grep -q 'Soft blocked: yes' && return 0
    fi
    return 1
}

if wifi_blocked; then
    # Leave airplane mode
    command -v rfkill >/dev/null 2>&1 && rfkill unblock wifi bluetooth 2>/dev/null || true
    if command -v nmcli >/dev/null 2>&1; then
        nmcli radio wifi on 2>/dev/null || true
        nmcli radio all on 2>/dev/null || true
    fi
    if command -v bluetoothctl >/dev/null 2>&1; then
        bluetoothctl power on 2>/dev/null || true
    fi
    notify "Airplane mode" "Off — Wi‑Fi / Bluetooth enabled" "network-wireless"
else
    # Enter airplane mode
    if command -v nmcli >/dev/null 2>&1; then
        nmcli radio wifi off 2>/dev/null || true
    fi
    if command -v bluetoothctl >/dev/null 2>&1; then
        bluetoothctl power off 2>/dev/null || true
    fi
    command -v rfkill >/dev/null 2>&1 && rfkill block wifi bluetooth 2>/dev/null || true
    notify "Airplane mode" "On — radios off" "network-wireless-offline"
fi
