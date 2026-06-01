#!/bin/bash

# Toggle Waybar visibility on Hyprland
# Uses SIGUSR1 which Waybar natively supports for show/hide.
#
# When starting, it uses the normal `waybar` command.
# This now correctly picks up the active theme because:
#   ~/.config/waybar/style.css  imports  "themes/current/style.css"
# (maintained by the theme switcher via symlink).

if pgrep -x waybar >/dev/null; then
    # Waybar is running → toggle visibility
    pkill -SIGUSR1 waybar
else
    # Waybar is not running → start fresh with current theme
    pkill waybar 2>/dev/null || true
    sleep 0.2
    waybar &
fi
