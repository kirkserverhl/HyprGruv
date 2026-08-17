#!/usr/bin/env bash
# apply-desktop-monitors.sh
# Desktop profile only.
#
# HyprGruv desk only. Packs the known row from whatever is actually connected.
# Connector names (DP-1 vs DP-3) change when cables move; match on description.
#
# Permanent 4-wide row (left → right), captured 2026-08-12:
#   24CN65 vertical 0x59 | LG FULL HD 900x59 | LG Monitor 2501x59 | LG TV 4102x0
# When some panels are unplugged, pack the rest flush at 0x0 so nothing is
# left stranded at the full-row coordinates.
# Exception: the 24CN65 lives on DisplayLink and flaps. If it vanished less
# than CN65_GRACE_SEC ago, keep the full-row coordinates so the other three
# do not jump left.

set -euo pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
READ_SETTING="$SCRIPTS/read-setting.sh"
# shellcheck source=tv-mode-common.sh
source "$SCRIPTS/tv-mode-common.sh"

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-desktop-monitors.lock"
CN65_SEEN="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-24cn65-seen"
CN65_GRACE_SEC=10

is_desktop_profile() {
    local mode machine
    mode="$("$READ_SETTING" monitors_mode "")"
    machine="$("$READ_SETTING" machine "")"
    [[ "$mode" == "desktop" || "$machine" == "desktop" ]]
}

is_desktop_profile || exit 0

command -v hyprctl >/dev/null 2>&1 || exit 0
command -v jq >/dev/null 2>&1 || exit 0

if command -v mkdir >/dev/null 2>&1; then
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        exit 0
    fi
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
fi

json="$(hyprctl monitors -j 2>/dev/null || true)"
[[ -n "$json" && "$json" != "null" ]] || exit 0

# Lua config ignores `hyprctl keyword monitor` ("use eval").
apply_monitor() {
    local output="$1" mode="$2" position="$3" scale="$4" transform="${5:-0}"
    if [[ "$output" == *"$TV_DESC_MATCH"* ]]; then
        tv_mode_eval "$mode" "$position" "$scale" >/dev/null
        return
    fi
    if [[ "$transform" != "0" ]]; then
        hyprctl eval "hl.monitor({ output = [[${output}]], mode = [[${mode}]], position = [[${position}]], scale = ${scale}, transform = ${transform} })" >/dev/null
    else
        hyprctl eval "hl.monitor({ output = [[${output}]], mode = [[${mode}]], position = [[${position}]], scale = ${scale} })" >/dev/null
    fi
}

tv_mode_spec

# desc-substring, mode, scale, transform, logical_w
# Logical width is what the next monitor must sit after (flush).
SPECS=(
    "LG Electronics 24CN65|1920x1080@60.00|1.2|1|900"
    "LG Electronics LG FULL HD|1920x1080@60.00|1.2|0|1600"
    "LG Electronics LG Monitor|1920x1080@60.00|1.2|0|1600"
    "${TV_DESC_MATCH}|${TV_RES}|${TV_SCALE}|0|1920"
)

FULL_POS=(
    "0x59"
    "900x59"
    "2501x59"
    "4102x0"
)

present_mask=()
present_count=0
for spec in "${SPECS[@]}"; do
    IFS='|' read -r desc _rest <<<"$spec"
    hit="$(jq -r --arg d "$desc" '
        any(.[]; (.description // "") | contains($d))
    ' <<<"$json")"
    if [[ "$hit" == "true" ]]; then
        present_mask+=(1)
        present_count=$((present_count + 1))
    else
        present_mask+=(0)
    fi
done

[[ "$present_count" -gt 0 ]] || exit 0

now="$(date +%s)"
cn65_present="${present_mask[0]:-0}"
if [[ "$cn65_present" -eq 1 ]]; then
    printf '%s\n' "$now" >"$CN65_SEEN"
fi

# DisplayLink drop: keep the 900px portrait slot for a few seconds.
cn65_expected=false
if [[ "$cn65_present" -eq 1 ]]; then
    cn65_expected=true
elif [[ -f "$CN65_SEEN" ]]; then
    last="$(tr -d '[:space:]' <"$CN65_SEEN" 2>/dev/null || true)"
    if [[ "$last" =~ ^[0-9]+$ ]] && (( now - last < CN65_GRACE_SEC )); then
        cn65_expected=true
    fi
fi

positions=()
if [[ "$present_count" -eq ${#SPECS[@]} ]] || $cn65_expected; then
    positions=("${FULL_POS[@]}")
else
    x=0
    i=0
    for spec in "${SPECS[@]}"; do
        IFS='|' read -r _desc _mode _scale _transform lw <<<"$spec"
        if [[ "${present_mask[$i]}" -eq 1 ]]; then
            positions+=("${x}x0")
            x=$((x + lw))
        else
            positions+=("")
        fi
        i=$((i + 1))
    done
fi

already_ok=true
i=0
for spec in "${SPECS[@]}"; do
    IFS='|' read -r desc _mode scale transform _lw <<<"$spec"
    if [[ "${present_mask[$i]}" -eq 1 ]]; then
        pos="${positions[$i]}"
        px="${pos%x*}"
        py="${pos#*x}"
        mw="${_mode%%x*}"
        mr="${_mode##*@}"
        mr="${mr%%.*}"
        if ! jq -e --arg d "$desc" --argjson x "$px" --argjson y "$py" --argjson s "$scale" --argjson t "$transform" --argjson w "$mw" --argjson r "$mr" '
            map(select((.description // "") | contains($d))) | first
            | .x == $x and .y == $y
              and ((.scale - $s) | fabs) < 0.001
              and ((.transform // 0) == $t)
              and .width == $w
              and ((.refreshRate - $r) | fabs) < 1.5
        ' <<<"$json" >/dev/null 2>&1; then
            already_ok=false
            break
        fi
    fi
    i=$((i + 1))
done

if $already_ok; then
    exit 0
fi

i=0
for spec in "${SPECS[@]}"; do
    IFS='|' read -r desc mode scale transform _lw <<<"$spec"
    if [[ "${present_mask[$i]}" -eq 1 ]]; then
        apply_monitor "desc:${desc}" "$mode" "${positions[$i]}" "$scale" "$transform"
    fi
    i=$((i + 1))
done
