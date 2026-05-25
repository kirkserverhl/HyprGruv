#!/bin/bash
# Reload / restore wallpaper using the active Waypaper + awww backend.
# (hyprpaper removed to avoid conflicts with waypaper-engine / awww-daemon)

waypaper --restore 2>/dev/null || true

# If you need to restart the daemon:
# killall waypaper-daemon awww-daemon 2>/dev/null || true
# waypaper-engine daemon &

