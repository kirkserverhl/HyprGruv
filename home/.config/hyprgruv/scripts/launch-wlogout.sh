#!/bin/bash
#
# launch-wlogout.sh
#
# Launcher for wlogout.
#
# Follows the strict rule: wlogout does *not* source any static wallpaper image.
# Background blur is handled 100% by Hyprland layerrules (real-time, no pre-rendered images).
# Only SDDM and the rofi 50x30 generator are permitted to load wallpaper files.
#

set -euo pipefail

# Toggle: if already open, just close it
if pgrep -x wlogout >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

# Small delay to let any in-progress wallpaper transition settle on screen.
# This prevents the common "blurred background is one wallpaper behind" issue.
sleep 0.3

# Launch wlogout.
# Heavy "security lens" blur (unreadable background) comes from the layerrule in conf/layerrules.lua.
# The menu itself is now a compact centered floating grid (Rofi/Waypaper style).
exec wlogout \
    --protocol layer-shell \
    -b 3 \                    # 3 buttons per row → nice 2x3 grid, compact
    --margin 280 \            # pulls the whole menu inward from screen edges (makes it smaller/centered)
    --layout "$HOME/.config/wlogout/layout" \
    --css "$HOME/.config/wlogout/style.css" \
    "$@"
