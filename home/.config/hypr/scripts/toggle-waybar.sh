#!/bin/bash

# Toggle Waybar visibility on Hyprland
# Uses SIGUSR1 which Waybar natively supports for show/hide

if pgrep -x waybar >/dev/null; then
    # Waybar is running → send toggle signal
    pkill -SIGUSR1 waybar
else
    # Waybar is not running → start it
    waybar &
fi
