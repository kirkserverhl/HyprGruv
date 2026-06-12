#!/bin/bash

# Toggle Waybar visibility on Hyprland.
# Uses SIGUSR1 which Waybar natively supports for show/hide.
#
# When (re)starting, it uses launch.sh so you get the last theme chosen via CTRL+W.

if pgrep -x waybar >/dev/null; then
    # Waybar is running → toggle visibility
    pkill -SIGUSR1 waybar
else
    # Waybar not running → start with last chosen theme (also kills nothingless if it was up)
    pkill -x nothingless 2>/dev/null || true
    pkill -x waybar 2>/dev/null || true
    sleep 0.15
    ~/.config/waybar/scripts/launch.sh
fi
