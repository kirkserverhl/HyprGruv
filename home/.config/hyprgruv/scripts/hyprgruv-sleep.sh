#!/usr/bin/env bash
# hyprgruv-sleep.sh — lock, then suspend or hibernate.
# Hibernate falls back to suspend when resume= is missing or systemd refuses.
#
#   hyprgruv-sleep.sh            # auto from profile (HYPRIDLE_SLEEP_ACTION)
#   hyprgruv-sleep.sh suspend
#   hyprgruv-sleep.sh hibernate
set -uo pipefail

PROFILE="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/profile.env"
ACTION="${1:-auto}"

lock_session() {
    loginctl lock-session 2>/dev/null || true
    sleep 0.4
}

hibernate_ready() {
    local resume
    resume="$(tr -d '[:space:]' </sys/power/resume 2>/dev/null || echo 0:0)"
    [[ "$resume" != "0:0" ]] || return 1
    grep -qw disk /sys/power/state 2>/dev/null || return 1
    return 0
}

if [[ "$ACTION" == "auto" ]]; then
    ACTION="suspend"
    if [[ -f "$PROFILE" ]]; then
        # shellcheck disable=SC1090
        ACTION="$(grep -E '^HYPRIDLE_SLEEP_ACTION=' "$PROFILE" | tail -1 | cut -d= -f2- | tr -d '[:space:]')"
        [[ -n "$ACTION" ]] || ACTION="suspend"
    fi
fi

lock_session

if [[ "$ACTION" == "hibernate" ]]; then
    if hibernate_ready && systemctl hibernate; then
        exit 0
    fi
    logger -t hyprgruv-sleep "hibernate unavailable or failed — suspending"
    systemctl suspend
    exit $?
fi

systemctl suspend
exit $?
