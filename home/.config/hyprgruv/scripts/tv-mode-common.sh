#!/usr/bin/env bash
# tv-mode-common.sh — LG TV desk/video profiles (sourced, not executed).
#
#   monitor  1920x1080@120  scale 1   — low-lag desk use
#   video    3840x2160@30   scale 2   — native 4K for watching
#
# Same 1920x1080 logical size either way, so the desk layout does not jump.
# Never use 4096x2160 (DCI) — that is why the picture looks side-barred
# and vertically squished on a 16:9 LG.

TV_DESC_MATCH="LG Electronics LG TV"
TV_OUTPUT="desc:${TV_DESC_MATCH}"
TV_SETTING="tv_mode"
TV_DEFAULT="monitor"

tv_mode_normalize() {
    case "${1:-}" in
        video|4k|uhd|cinema) printf '%s\n' video ;;
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

# Sets TV_MODE TV_RES TV_SCALE TV_LABEL
tv_mode_spec() {
    TV_MODE="$(tv_mode_current)"
    if [[ "$TV_MODE" == "video" ]]; then
        TV_RES="3840x2160@30.00"
        TV_SCALE="2"
        TV_LABEL="video · 4K 30Hz"
    else
        TV_RES="1920x1080@120.00"
        TV_SCALE="1"
        TV_LABEL="monitor · 1080p 120Hz"
    fi
}

# SDR-only extras: some LG TVs switch to a cinema picture mode (wrong
# aspect, side bars + vertical squash) when they see HDR/wide metadata.
tv_mode_eval() {
    local res="$1" pos="$2" scale="$3"
    hyprctl eval "hl.monitor({ output = [[${TV_OUTPUT}]], mode = [[${res}]], position = [[${pos}]], scale = ${scale}, cm = [[srgb]], bitdepth = 8, supports_hdr = -1, supports_wide_color = -1 })"
}
