#!/bin/bash
# Reload last wallpaper + re-apply matugen (same logic as login restore).
# Safe to run manually from a keybind or terminal.

~/.config/hyprgruv/scripts/restore_wallpaper.sh

# If you ever need to fully bounce the daemons:
# killall -q waypaper-daemon awww-daemon waypaper-engine 2>/dev/null || true
# waypaper-engine daemon &
# sleep 1 && ~/.config/hyprgruv/scripts/restore_wallpaper.sh &

