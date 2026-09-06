#!/usr/bin/env bash
# tv-mode-common.sh — LG TV desk/video profiles (sourced, not executed).
#
#   monitor  1920x1080@120  scale 1   — 4-wide desk, TV as the right-hand panel
#   video    3840x2160@60   scale 1   — desk panels off, TV only (movie night)
#
# Super+Alt+M toggles. Never use 4096x2160 (DCI) — that is why the picture
# looks side-barred and vertically squished on a 16:9 LG. Force SDR so the
# TV does not flip into a cinema picture mode (wrong aspect).
#
# Video used to switch the TV to 4K *while the three desk panels stayed on*.
# The APU cannot drive 4K HDMI + 3×1080p; the TV went black. Movie mode now
# blanks the desk first, then gives the TV the only CRTC.

TV_DESC_MATCH="LG Electronics LG TV"
TV_OUTPUT="desc:${TV_DESC_MATCH}"
TV_SETTING="tv_mode"
TV_DEFAULT="monitor"
TV_POS_DESK="4102x0"
TV_POS_VIDEO="0x0"

# desc|mode|scale|transform  — left → right on the desk, matching monitors.lua
DESK_SPECS=(
    "LG Electronics 24CN65|1920x1080@60.00|1.2|1"
    "LG Electronics LG FULL HD|1920x1080@60.00|1.2|0"
    "LG Electronics LG Monitor|1920x1080@60.00|1.2|0"
)

# Missing machine/monitors_mode settings mean desktop — same default as
# conf/settings.lua. Only an explicit "laptop" value is the other machine.
tv_is_desktop_profile() {
    local mode="" machine=""
    if [[ -n "${READ_SETTING:-}" && -x "${READ_SETTING}" ]]; then
        mode="$("$READ_SETTING" monitors_mode "")"
        machine="$("$READ_SETTING" machine "")"
    fi
    [[ "$mode" != "laptop" && "$machine" != "laptop" ]]
}

tv_mode_normalize() {
    case "${1:-}" in
        video|4k|uhd|cinema|movie) printf '%s\n' video ;;
        *) printf '%s\n' monitor ;;
    esac
}

tv_mode_current() {
    local raw=""
    if [[ -n "${READ_SETTING:-}" && -x "${READ_SETTING}" ]]; then
        raw="$("$READ_SETTING" "$TV_SETTING" "$TV_DEFAULT")"
    elif [[ -f "${HOME}/.config/settings/${TV_SETTING}.sh" ]]; then
        raw="$(tr -d '[:space:]' <"${HOME}/.config/settings/${TV_SETTING}.sh")"
    fi
    tv_mode_normalize "$raw"
}

tv_mode_write() {
    local mode
    mode="$(tv_mode_normalize "$1")"
    mkdir -p "${HOME}/.config/settings"
    printf '%s\n' "$mode" >"${HOME}/.config/settings/${TV_SETTING}.sh"
}

# Sets TV_MODE TV_RES TV_SCALE TV_POS TV_LABEL
tv_mode_spec() {
    TV_MODE="$(tv_mode_current)"
    if [[ "$TV_MODE" == "video" ]]; then
        # 60Hz is the TV's preferred 4K timing. 24Hz trips cinema-mode
        # aspect bugs; 30Hz was the old dual-layout compromise and judders.
        TV_RES="3840x2160@60.00"
        TV_SCALE="1"
        TV_POS="$TV_POS_VIDEO"
        TV_LABEL="movie · 4K 60Hz, desk off"
    else
        TV_RES="1920x1080@120.00"
        TV_SCALE="1"
        TV_POS="$TV_POS_DESK"
        TV_LABEL="desk · 1080p 120Hz, 4-wide"
    fi
}

tv_connected() {
    command -v hyprctl >/dev/null 2>&1 || return 1
    command -v jq >/dev/null 2>&1 || return 1
    hyprctl monitors all -j 2>/dev/null | jq -e --arg d "$TV_DESC_MATCH" '
        any(.[]; (.description // "") | contains($d))
    ' >/dev/null 2>&1
}

# SDR-only extras: some LG TVs switch to a cinema picture mode (wrong
# aspect, side bars + vertical squash) when they see HDR/wide metadata.
tv_mode_eval() {
    local res="$1" pos="$2" scale="$3"
    hyprctl eval "hl.monitor({ output = [[${TV_OUTPUT}]], mode = [[${res}]], position = [[${pos}]], scale = ${scale}, cm = [[srgb]], bitdepth = 8, supports_hdr = -1, supports_wide_color = -1, disabled = false })"
}

tv_desk_eval() {
    local output="$1" mode="$2" position="$3" scale="$4" transform="${5:-0}"
    if [[ "$transform" != "0" ]]; then
        hyprctl eval "hl.monitor({ output = [[${output}]], mode = [[${mode}]], position = [[${position}]], scale = ${scale}, transform = ${transform}, disabled = false })"
    else
        hyprctl eval "hl.monitor({ output = [[${output}]], mode = [[${mode}]], position = [[${position}]], scale = ${scale}, disabled = false })"
    fi
}

# Blank the three desk panels. Call *before* the 4K modeset so the APU
# has a free CRTC for HDMI. Never disable the TV here.
tv_desk_disable() {
    local desc
    for spec in "${DESK_SPECS[@]}"; do
        IFS='|' read -r desc _ <<<"$spec"
        hyprctl eval "hl.monitor({ output = [[desc:${desc}]], disabled = true })" >/dev/null || true
    done
}

tv_focus() {
    hyprctl dispatch focusmonitor "$TV_OUTPUT" >/dev/null 2>&1 || true
}
