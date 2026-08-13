#!/usr/bin/env bash
# apply-laptop-monitors.sh
# HyprLab / laptop-profile only.
#
# When the work-dock LG FULL HD (serial 103MXTC4F409) is present:
#   LG LEFT   1920x1080@60     0x0    scale 1.2
#   eDP RIGHT 1920x1080@60.02  1600x0 scale 1.2  (flush: 1920/1.2)
#
# Never move the built-in panel to 0x0 from a single early snapshot.
# Login/hotplug often lists eDP first; slamming it to 0x0 then lets the
# dock land on top of it (cursor drawn on both screens).

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_SETTING="$SCRIPTS/read-setting.sh"

WORK_SERIAL="103MXTC4F409"
WORK_DESC="desc:LG Electronics LG FULL HD ${WORK_SERIAL}"
LAPTOP_DESC="desc:LG Display 0x061F"

DOCK_MODE="1920x1080@60.00"
DOCK_POS="0x0"
DOCK_SCALE="1.2"

LAPTOP_MODE="1920x1080@60.02"
LAPTOP_DOCKED_POS="1600x0"
LAPTOP_SOLO_POS="0x0"
LAPTOP_SCALE="1.2"

LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-laptop-monitors.lock"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/laptop-monitors.log"

log() {
    mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG" 2>/dev/null || true
}

is_laptop_profile() {
    local mode machine
    mode="$("$READ_SETTING" monitors_mode "")"
    machine="$("$READ_SETTING" machine "")"
    [[ "$mode" == "laptop" || "$machine" == "laptop" ]]
}

# Desktop uses the same login/hotplug/reload hooks; pack whatever is plugged in.
if ! is_laptop_profile; then
    exec "$SCRIPTS/apply-desktop-monitors.sh"
fi

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Serialize overlapping start/hotplug/reload calls. Wait; do not drop.
exec 9>"$LOCK_FILE"
if ! flock -w 12 9; then
    log "lock timeout; skip"
    exit 0
fi

json=""
dock_present="false"

refresh_json() {
    json="$(hyprctl monitors -j 2>/dev/null || true)"
}

dock_in_json() {
    jq -r --arg s "$WORK_SERIAL" '
        any(.[];
            (.serial // "") == $s
            or ((.description // "") | contains($s))
        )
    ' <<<"$json"
}

# DP/HDMI already enumerated, or more than the built-in — dock is attaching.
has_external() {
    jq -e '
        any(.[];
            (.name // "" | test("^(DP-|HDMI-|DVI-)"))
            or ((.description // "") | test("LG Electronics"))
        )
        or (length > 1)
    ' <<<"$json" >/dev/null 2>&1
}

# Poll before concluding "undocked". A 1s login snapshot is not proof.
wait_for_stable() {
    local i dock
    for i in $(seq 1 12); do
        refresh_json
        if [[ -z "$json" || "$json" == "null" ]]; then
            sleep 0.35
            continue
        fi
        dock="$(dock_in_json)"
        if [[ "$dock" == "true" ]]; then
            dock_present=true
            return 0
        fi
        if has_external; then
            sleep 0.4
            continue
        fi
        # Only the built-in so far. Give login a few extra looks.
        if (( i < 5 )); then
            sleep 0.35
            continue
        fi
        dock_present=false
        return 0
    done
    dock_present=false
}

# Lua config ignores `hyprctl keyword monitor` ("use eval").
apply_monitor() {
    local output="$1" mode="$2" position="$3" scale="$4"
    hyprctl eval "hl.monitor({ output = [[${output}]], mode = [[${mode}]], position = [[${position}]], scale = ${scale} })" >/dev/null
}

already_docked() {
    jq -e --arg s "$WORK_SERIAL" '
        (map(select((.serial // "") == $s or ((.description // "") | contains($s)))) | first
            | .x == 0 and .y == 0)
        and
        (map(select((.description // "") | test("LG Display 0x061F"))) | first
            | .x == 1600 and .y == 0)
    ' <<<"$json" >/dev/null 2>&1
}

already_solo() {
    jq -e '
        (length == 1)
        and (.[0].description // "" | test("LG Display 0x061F"))
        and .[0].x == 0 and .[0].y == 0
    ' <<<"$json" >/dev/null 2>&1
}

# Rule uses desc: (stable). Move uses the connector name (hl.dsp.workspace.move).
pin_ws() {
    local id="$1" desc="$2" name="$3"
    hyprctl eval "hl.workspace_rule({ workspace = ${id}, monitor = [[${desc}]], persistent = true })" >/dev/null
    hyprctl dispatch "hl.dsp.workspace.move({ workspace = ${id}, monitor = [[${name}]] })" >/dev/null 2>&1 || true
}

# 2 persistent workspaces per output (desktop rule), left-to-right: 1-2, 3-4, …
apply_two_per_monitor() {
    local i=0 name desc a b
    while IFS=$'\t' read -r name desc; do
        [[ -n "$name" ]] || continue
        a=$((i * 2 + 1))
        b=$((i * 2 + 2))
        pin_ws "$a" "desc:${desc}" "$name"
        pin_ws "$b" "desc:${desc}" "$name"
        i=$((i + 1))
    done < <(jq -r 'sort_by(.x) | .[] | "\(.name)\t\(.description)"' <<<"$json")
}

wait_for_stable
[[ -n "$json" && "$json" != "null" ]] || exit 0

if [[ "$dock_present" == "true" ]]; then
    if ! already_docked; then
        log "pin docked: LG ${DOCK_POS} + laptop ${LAPTOP_DOCKED_POS}"
        # Dock first (left), laptop second (right). Never the reverse.
        apply_monitor "$WORK_DESC" "$DOCK_MODE" "$DOCK_POS" "$DOCK_SCALE"
        apply_monitor "$LAPTOP_DESC" "$LAPTOP_MODE" "$LAPTOP_DOCKED_POS" "$LAPTOP_SCALE"
        refresh_json
    fi
    apply_two_per_monitor
    exit 0
fi

# Still more than the built-in, but not the known work serial — do not
# collapse the laptop onto 0x0 (that is what stacked the cursors).
if jq -e 'length > 1' <<<"$json" >/dev/null 2>&1; then
    log "multiple outputs, work serial absent; leave geometry"
    apply_two_per_monitor
    exit 0
fi

if ! already_solo; then
    log "pin solo laptop ${LAPTOP_SOLO_POS}"
    apply_monitor "$LAPTOP_DESC" "$LAPTOP_MODE" "$LAPTOP_SOLO_POS" "$LAPTOP_SCALE"
fi
laptop_name="$(jq -r '
    [.[] | select((.description // "") | test("LG Display 0x061F"))]
    | first | .name // "eDP-1"
' <<<"$json")"
pin_ws 1 "$LAPTOP_DESC" "$laptop_name"
pin_ws 2 "$LAPTOP_DESC" "$laptop_name"
