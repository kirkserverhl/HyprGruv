#!/bin/bash
# Dynamic workspace reassignment on monitor hotplug.
# HyprLab: also re-pins the work-dock left/right layout.
#
# Hyprland 0.40+ puts the event socket under $XDG_RUNTIME_DIR/hypr/, not /tmp/hypr/.

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_LAPTOP="$SCRIPTS/apply-laptop-monitors.sh"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/laptop-monitors.log"
DEBOUNCE_SEC=2
DEBOUNCE_PID_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-monitor-apply.pid"
CN65_SEEN="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-24cn65-seen"

log() {
    mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG" 2>/dev/null || true
}

find_socket2() {
    local sig="${HYPRLAND_INSTANCE_SIGNATURE:-}"
    local runtime="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local p
    if [[ -n "$sig" ]]; then
        for p in \
            "${runtime}/hypr/${sig}/.socket2.sock" \
            "/tmp/hypr/${sig}/.socket2.sock"; do
            [[ -S "$p" ]] && { printf '%s\n' "$p"; return 0; }
        done
    fi
    # Last resort: the only live hypr event socket for this user.
    for p in "${runtime}"/hypr/*/.socket2.sock /tmp/hypr/*/.socket2.sock; do
        [[ -S "$p" ]] && { printf '%s\n' "$p"; return 0; }
    done
    return 1
}

apply_laptop_layout() {
    # Debounce already waited for a quiet window; do not sleep again here.
    if [[ -x "$APPLY_LAPTOP" ]]; then
        "$APPLY_LAPTOP" || true
    fi
}

cancel_scheduled_apply() {
    local pid
    if [[ -f "$DEBOUNCE_PID_FILE" ]]; then
        pid="$(tr -d '[:space:]' <"$DEBOUNCE_PID_FILE" 2>/dev/null || true)"
        rm -f "$DEBOUNCE_PID_FILE"
        if [[ "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
        fi
    fi
}

# One apply after DEBOUNCE_SEC of no add/remove events.
schedule_apply() {
    cancel_scheduled_apply
    (
        sleep "$DEBOUNCE_SEC"
        rm -f "$DEBOUNCE_PID_FILE"
        reassign_workspaces
    ) &
    echo $! >"$DEBOUNCE_PID_FILE"
}

reassign_workspaces() {
    apply_laptop_layout

    local machine
    machine="$(tr -d '[:space:]' <"${HOME}/.config/settings/machine.sh" 2>/dev/null || true)"
    # Laptop docked layout + 2-per-monitor pins are handled by apply-laptop-monitors.sh.
    if [[ "$machine" == "laptop" ]]; then
        echo ":: Laptop profile — workspace pairs applied by apply-laptop-monitors.sh"
        return 0
    fi

    local count
    count="$(hyprctl monitors -j 2>/dev/null | jq 'length' 2>/dev/null || echo 0)"
    echo ":: Monitor change detected. Reassigning workspaces for $count monitor(s)..."
}

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" && ! -S "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"/*/.socket2.sock ]]; then
    echo "Not running under Hyprland"
    exit 1
fi

# Dock is usually already up at login — pin left/right before waiting on events.
if [[ -x "$APPLY_LAPTOP" ]]; then
    "$APPLY_LAPTOP" || true
fi

# Stay up across compositor socket reuse (reload / crash-restart).
while true; do
    sock="$(find_socket2 || true)"
    if [[ -z "$sock" ]]; then
        log "monitor-workspaces: no socket2; retry"
        sleep 2
        continue
    fi
    log "monitor-workspaces: listen $sock"
    socat - "UNIX-CONNECT:${sock}" | while read -r line; do
        if [[ $line == monitoradded* ]] || [[ $line == monitorremoved* ]]; then
            log "event $line"
            # Stamp last-seen on add so apply-desktop grace works even if
            # debounce never ran while the 24CN65 was still connected.
            if [[ $line == monitoradded* && $line == *24CN65* ]]; then
                date +%s >"$CN65_SEEN" 2>/dev/null || true
            fi
            schedule_apply
        fi
    done
    log "monitor-workspaces: socket closed; reconnect"
    sleep 1
done
