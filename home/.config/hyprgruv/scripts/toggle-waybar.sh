#!/bin/bash

# Toggle Waybar visibility on Hyprland.
# Uses SIGUSR1 which Waybar natively supports for show/hide.
#
# When (re)starting, it uses launch.sh so you get the last theme chosen via the layout switcher.

if killall -0 waybar 2>/dev/null; then
    # Waybar is running → toggle visibility
    pkill -SIGUSR1 waybar
else
    # Waybar not running → start with last chosen theme
    killall -9 waybar 2>/dev/null || true
    sleep 0.15
    ~/.config/waybar/scripts/launch.sh
fi
