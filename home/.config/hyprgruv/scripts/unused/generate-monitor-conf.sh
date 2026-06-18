#!/usr/bin/env bash
# generate-monitor-conf.sh
# Run this AFTER arranging monitors in wdisplays (or any GUI).
# It will output clean monitor= lines you can paste into monitor.conf

echo "# Generated monitor configuration"
echo "# Copy this into ~/.config/hypr/conf/monitor.conf"
echo ""

hyprctl monitors -j | jq -r '
  .[] |
  "monitor = \(.name), \(.width)x\(.height)@\(.refreshRate | floor), \(.x)x\(.y), \(.scale)" +
  (if .transform != 0 then ", transform, \(.transform)" else "" end)
' | sort -t'x' -k2 -n   # rough left-to-right sort by x position

echo ""
echo "# If you want to use descriptions for more stability (recommended), run this instead:"
echo "# hyprctl monitors -j | jq -r '.[] | \"monitor = desc:\(.description | @sh), preferred, \(.x)x\(.y), \(.scale)\"'"

echo ""
echo "# After pasting, run: hyprctl reload"
