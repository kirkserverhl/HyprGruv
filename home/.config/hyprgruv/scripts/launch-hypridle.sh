#!/usr/bin/env bash
# launch-hypridle.sh — start machine-profile hypridle (state conf, then fallback)
#
#   launch-hypridle.sh              restart via systemd unit, else background
#   launch-hypridle.sh --foreground exec hypridle (systemd ExecStart)
#   launch-hypridle.sh --stop
set -euo pipefail

STATE_CONF="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/hypridle.conf"
FALLBACK_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hypridle.conf"
UNIT="hyprgruv-idle.service"

hypridle_bin() {
    if command -v hypridle >/dev/null 2>&1; then
        command -v hypridle
    elif [[ -x /usr/bin/hypridle ]]; then
        echo /usr/bin/hypridle
    else
        return 1
    fi
}

conf_path() {
    if [[ -f "$STATE_CONF" ]]; then
        printf '%s' "$STATE_CONF"
    elif [[ -f "$FALLBACK_CONF" ]]; then
        printf '%s' "$FALLBACK_CONF"
    else
        return 1
    fi
}

run_foreground() {
    local bin conf
    bin="$(hypridle_bin)" || {
        echo "hypridle not installed" >&2
        exit 1
    }
    if conf="$(conf_path)"; then
        exec "$bin" -c "$conf"
    fi
    exec "$bin"
}

stop_idle() {
    systemctl --user stop "$UNIT" 2>/dev/null || true
    pkill -x hypridle 2>/dev/null || true
}

start_background() {
    local bin
    bin="$(hypridle_bin)" || {
        echo "hypridle not installed" >&2
        return 1
    }
    # Always drop strays (autostart leftover) before the unit claims ScreenSaver.
    pkill -x hypridle 2>/dev/null || true
    sleep 0.15
    if systemctl --user list-unit-files "$UNIT" &>/dev/null; then
        systemctl --user start "$UNIT"
        return
    fi
    if conf="$(conf_path)"; then
        "$bin" -c "$conf" &
    else
        "$bin" &
    fi
    disown || true
}

case "${1:-}" in
--foreground | -f) run_foreground ;;
--stop) stop_idle ;;
--restart)
    stop_idle
    start_background
    ;;
*)
    start_background
    ;;
esac
