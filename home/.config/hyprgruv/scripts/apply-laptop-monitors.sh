#!/usr/bin/env bash
# apply-laptop-monitors.sh
# HyprLab / laptop-profile only.
#
# When the work-dock LG FULL HD (serial 103MXTC4F409) is present:
#   LG LEFT   1920x1080@60     0x0      scale 0.833333
#   eDP RIGHT 1920x1080@60.02  2307x281 scale 1.2
#
# The previous Lua hook flipped this pair: on monitor.added / reload it
# queried monitors before the dock was in the list, assumed "undocked",
# and slammed the laptop to 0x0. Never move the built-in panel to 0x0
# unless that serial is confirmed absent.

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_SETTING="$SCRIPTS/read-setting.sh"

WORK_SERIAL="103MXTC4F409"
WORK_DESC="desc:LG Electronics LG FULL HD ${WORK_SERIAL}"
LAPTOP_DESC="desc:LG Display 0x061F"

DOCK_MODE="1920x1080@60.00"
DOCK_POS="0x0"
DOCK_SCALE="0.833333"

LAPTOP_MODE="1920x1080@60.02"
LAPTOP_DOCKED_POS="2307x281"
LAPTOP_SOLO_POS="0x0"
LAPTOP_SCALE="1.2"

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-laptop-monitors.lock"

is_laptop_profile() {
    local mode machine
    mode="$("$READ_SETTING" monitors_mode "")"
    machine="$("$READ_SETTING" machine "")"
    [[ "$mode" == "laptop" || "$machine" == "laptop" ]]
}

is_laptop_profile || exit 0

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Serialize overlapping start/hotplug/reload calls.
if command -v mkdir >/dev/null 2>&1; then
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        exit 0
    fi
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
fi

json="$(hyprctl monitors -j 2>/dev/null || true)"
[[ -n "$json" && "$json" != "null" ]] || exit 0

dock_present="$(jq -r --arg s "$WORK_SERIAL" '
    any(.[];
        (.serial // "") == $s
        or ((.description // "") | contains($s))
    )
' <<<"$json")"

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
            | .x == 2307 and .y == 281)
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

if [[ "$dock_present" == "true" ]]; then
    if ! already_docked; then
        # Dock first (left), laptop second (right). Never the reverse.
        apply_monitor "$WORK_DESC" "$DOCK_MODE" "$DOCK_POS" "$DOCK_SCALE"
        apply_monitor "$LAPTOP_DESC" "$LAPTOP_MODE" "$LAPTOP_DOCKED_POS" "$LAPTOP_SCALE"
        json="$(hyprctl monitors -j 2>/dev/null || true)"
    fi
    apply_two_per_monitor
else
    if ! already_solo; then
        apply_monitor "$LAPTOP_DESC" "$LAPTOP_MODE" "$LAPTOP_SOLO_POS" "$LAPTOP_SCALE"
    fi
    laptop_name="$(jq -r '
        [.[] | select((.description // "") | test("LG Display 0x061F"))]
        | first | .name // "eDP-1"
    ' <<<"$json")"
    pin_ws 1 "$LAPTOP_DESC" "$laptop_name"
    pin_ws 2 "$LAPTOP_DESC" "$laptop_name"
fi
