#!/usr/bin/env bash
# lid-watch.sh — laptop lid grace, then lock + hibernate
#
# Close lid:
#   • screens off immediately (internal panel only when an external is active)
#   • first GRACE seconds: reopen stays unlocked
#   • after GRACE, if still closed and not a docked workstation: lock + hibernate
#
# Docked workstation = at least one enabled non-laptop output. Closing the lid
# at a desk must not hibernate a session that is still on the external monitor.
set -uo pipefail

GRACE_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/settings/lid_grace_sec.sh"
SLEEP_SH="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/scripts/hyprgruv-sleep.sh"
GRACE=300
[[ -f "$GRACE_FILE" ]] && GRACE="$(tr -d '[:space:]' <"$GRACE_FILE")"
[[ "$GRACE" =~ ^[0-9]+$ ]] || GRACE=300

lid_closed() {
    local raw
    raw="$(busctl get-property org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager LidClosed 2>/dev/null | awk '{print $2}')"
    if [[ "$raw" == "true" ]]; then
        return 0
    fi
    local st
    for st in /proc/acpi/button/lid/*/state; do
        [[ -f "$st" ]] || continue
        grep -qi 'closed' "$st" 2>/dev/null && return 0
    done
    return 1
}

is_docked_workstation() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    sys.exit(1)
n = 0
for m in monitors:
    if m.get("disabled"):
        continue
    name = (m.get("name") or "").upper()
    if name.startswith(("EDP", "LVDS", "DSI")):
        continue
    n += 1
sys.exit(0 if n else 1)
'
}

internal_names() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    sys.exit(0)
for m in monitors:
    name = m.get("name") or ""
    if name.upper().startswith(("EDP", "LVDS", "DSI")):
        print(name)
'
}

dpms_off_for_lid() {
    if is_docked_workstation; then
        local name
        while read -r name; do
            [[ -n "$name" ]] || continue
            hyprctl dispatch dpms off "$name" >/dev/null 2>&1 || true
        done < <(internal_names)
        return
    fi
    hyprctl dispatch dpms off >/dev/null 2>&1 || true
}

dpms_on() {
    hyprctl dispatch dpms on >/dev/null 2>&1 || true
}

closed_at=0
acted=0

logger -t hyprgruv-lid "watching lid (grace=${GRACE}s)"

while true; do
    sleep 1
    if lid_closed; then
        now="$(date +%s)"
        if ((closed_at == 0)); then
            closed_at="$now"
            acted=0
            dpms_off_for_lid
            logger -t hyprgruv-lid "lid closed (docked=$(is_docked_workstation && echo yes || echo no))"
        elif ((acted == 0 && now - closed_at >= GRACE)); then
            acted=1
            if is_docked_workstation; then
                logger -t hyprgruv-lid "grace elapsed — docked, leaving session on external"
                continue
            fi
            logger -t hyprgruv-lid "grace elapsed — lock + hibernate"
            bash "$SLEEP_SH" hibernate
        fi
    else
        if ((closed_at != 0)); then
            dpms_on
            logger -t hyprgruv-lid "lid open — cancelled (held $(($(date +%s) - closed_at))s)"
        fi
        closed_at=0
        acted=0
    fi
done
