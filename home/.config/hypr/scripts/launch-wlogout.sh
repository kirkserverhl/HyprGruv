#!/bin/bash
#
# launch-wlogout.sh
# Smooth live-desktop → blurred background transition for wlogout.
#
# This version is the simplest and most reliable:
#   - Only job: take a live screenshot + generate a blurred version into two fixed /tmp files.
#   - Then launch wlogout pointing at your REAL ~/.config/wlogout/style.css and layout.
#   - 100% of your original icons, text labels ("Lock", "Shutdown"...), fonts,
#     button styling, hover effects, and any centering rules you have live in your style.css
#     are used exactly as written. Nothing is stripped or regenerated.
#
# The transition effect is done with CSS inside your style.css (see the window + ::before rules below).
#

set -euo pipefail

# Toggle: if already open, just close it
if pgrep -x wlogout >/dev/null 2>&1; then
    pkill -x wlogout
    exit 0
fi

# These two fixed files are what your style.css will reference for the transition
SHARP="/tmp/wlogout-live-sharp.png"
BLURRED="/tmp/wlogout-live-blurred.png"

rm -f "$SHARP" "$BLURRED" 2>/dev/null || true

# Capture the exact current screen state on the focused monitor
FOCUSED_MONITOR=$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused==true) | .name' || echo "")

if [[ -n "$FOCUSED_MONITOR" ]]; then
    grim -o "$FOCUSED_MONITOR" -t png "$SHARP" 2>/dev/null || grim -t png "$SHARP"
else
    grim -t png "$SHARP"
fi

if [[ ! -f "$SHARP" ]]; then
    cp "$HOME/.config/settings/cache/blurred_wallpaper_full.png" "$SHARP" 2>/dev/null || true
    cp "$SHARP" "$BLURRED"
else
    # Nice fast blur (adjust 0x13 if you want stronger/weaker final blur)
    magick "$SHARP" -resize 22% -blur 0x13 -resize 455% "$BLURRED" 2>/dev/null || cp "$SHARP" "$BLURRED"
fi

# Launch with your real files — all original formatting, icons and text are preserved
exec wlogout \
    --protocol layer-shell \
    -b 6 \
    -c 0 -r 0 -m 0 \
    --layout "$HOME/.config/wlogout/layout" \
    --css "$HOME/.config/wlogout/style.css" \
    "$@"
