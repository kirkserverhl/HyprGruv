#!/usr/bin/env bash
# Hitchhiker's sendoff on the session TTY (toilet graffiti → lsd-print).
set -euo pipefail

readonly FAREWELL_MSG='So long and Thanks for all the FISH!'
readonly STAMP="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hyprgruv-farewell.stamp"

[[ "${HYPRGRUV_SKIP_FAREWELL:-}" == "1" ]] && exit 0
[[ -f "$STAMP" ]] && exit 0

toilet_bin() {
    command -v toilet 2>/dev/null || true
}

lsd_print_bin() {
    if command -v lsd-print >/dev/null 2>&1; then
        command -v lsd-print
    elif [[ -x "$HOME/.local/bin/lsd-print" ]]; then
        echo "$HOME/.local/bin/lsd-print"
    elif [[ -x "$HOME/.hyprgruv/assets/bin/lsd-print" ]]; then
        echo "$HOME/.hyprgruv/assets/bin/lsd-print"
    fi
}

resolve_tty_dev() {
    local tty_name=""

    if [[ -n "${XDG_SESSION_ID:-}" ]] && command -v loginctl >/dev/null 2>&1; then
        tty_name=$(loginctl show-session "$XDG_SESSION_ID" -p TTY --value 2>/dev/null || true)
    fi

    if [[ -z "$tty_name" ]] && command -v loginctl >/dev/null 2>&1; then
        tty_name=$(loginctl show-user "$(id -u)" -p TTY --value 2>/dev/null | head -n1 || true)
    fi

    if [[ -z "$tty_name" ]] && command -v fgconsole >/dev/null 2>&1; then
        local vt
        vt=$(fgconsole 2>/dev/null || true)
        [[ -n "$vt" ]] && tty_name="tty${vt}"
    fi

    [[ -z "$tty_name" ]] && tty_name="tty2"
    tty_name="${tty_name#/dev/}"
    echo "/dev/${tty_name}"
}

show_on_tty() {
    local tty_dev="$1"
    local toilet lsd_print vt

    toilet=$(toilet_bin)
    lsd_print=$(lsd_print_bin)
    [[ -z "$toilet" || -z "$lsd_print" ]] && return 0
    [[ ! -e "$tty_dev" ]] && return 0

    vt="${tty_dev#/dev/tty}"
    if command -v chvt >/dev/null 2>&1 && [[ "$vt" =~ ^[0-9]+$ ]]; then
        chvt "$vt" 2>/dev/null || true
    fi

    {
        printf '\033[2J\033[H'
        echo "$FAREWELL_MSG" | "$toilet" -f graffiti --gay | "$lsd_print"
        sleep 2
    } >"$tty_dev" 2>/dev/null || true

    touch "$STAMP"
}

show_on_tty "$(resolve_tty_dev)"