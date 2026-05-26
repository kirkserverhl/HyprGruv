#!/bin/bash
# Power menu entry point (called from waybar, etc.)
# Delegates to the fancy blur-transition launcher.
exec "$HOME/.config/hypr/scripts/launch-wlogout.sh" "$@"
