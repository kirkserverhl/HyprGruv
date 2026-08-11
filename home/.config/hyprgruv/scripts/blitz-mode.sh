#!/usr/bin/env bash
# blitz-mode.sh — WORK-focus performance toggle (not laptop vs desktop).
#
# Device profile (apply-machine-profile laptop|desktop) sets baseline blur/shadow.
# Blitz goes further for deep work: kill animations, blur, shadows, gaps.
#
# Toggle: run again, or hyprctl reload to restore config baseline.
set -euo pipefail

# Hyprland 0.5x+ reports animations:enabled as int 0/1
blitz_mode=$(hyprctl getoption animations:enabled 2>/dev/null | awk 'NR==1{print $2}')

if [[ "$blitz_mode" == "1" || "$blitz_mode" == "true" ]]; then
    # Enter Blitz — strip compositor cosmetics for max responsiveness
    hyprctl --batch "\
        keyword animations:enabled 0;\
        keyword decoration:shadow:enabled 0;\
        keyword decoration:blur:enabled 0;\
        keyword decoration:rounding 0;\
        keyword decoration:inactive_opacity 1.0;\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 1;\
        keyword general:allow_tearing 1;\
        keyword misc:disable_hyprland_logo 1;\
        keyword misc:disable_splash_rendering 1"
    notify-send -e -u low "Blitz Mode" "On — blur/anim/gaps off (work focus)" 2>/dev/null || true
    exit 0
fi

# Leave Blitz — full reload restores laptop/desktop decoration profile
hyprctl reload
notify-send -e -u low "Blitz Mode" "Off — restored machine decoration profile" 2>/dev/null || true
