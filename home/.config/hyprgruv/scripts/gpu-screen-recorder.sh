#!/usr/bin/env bash
# Toggle GPU Screen Recorder overlay (Alt+Z).
# Hyprland owns the hotkey so it appears in rofi-keybinds.sh.
# In gsr-ui Settings, set keyboard grab to "don't grab devices"
# so it does not steal keys from Hyprland.
set -euo pipefail

if ! command -v gsr-ui-cli >/dev/null 2>&1; then
    hyprctl notify 3 4000 0 "fontsize:13,Install gpu-screen-recorder-ui (sync-packages.sh)"
    exit 1
fi

if ! pgrep -x gsr-ui >/dev/null 2>&1; then
    if systemctl --user start gpu-screen-recorder-ui.service 2>/dev/null; then
        :
    else
        gsr-ui >/dev/null 2>&1 &
    fi
    for _ in 1 2 3 4 5 6 7 8; do
        pgrep -x gsr-ui >/dev/null 2>&1 && break
        sleep 0.15
    done
fi

exec gsr-ui-cli toggle-show
