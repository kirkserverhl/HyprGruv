#!/usr/bin/env bash
# Custom Waybar module: Simplified 3-slot workspace view
# Shows:
#   - Left group (workspaces 1-2)
#   - Right group (workspaces 3-4)  [or more groups if you have 4 monitors]
#   - Special workspace (scratchpad)
#
# Click behavior:
#   Left group  -> switch to workspace 1
#   Right group -> switch to workspace 3
#   Special     -> toggle special workspace

set -euo pipefail

# Get current active workspace
ACTIVE_WS=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.id // 1')

# Check if special workspace is active
SPECIAL_ACTIVE=$(hyprctl workspaces -j 2>/dev/null | jq -r '.[] | select(.name | startswith("special:")) | .name' | head -1)

# Determine which group is active
LEFT_ACTIVE=""
RIGHT_ACTIVE=""
SPECIAL_STATE=""

if [[ "$ACTIVE_WS" -ge 1 && "$ACTIVE_WS" -le 2 ]]; then
    LEFT_ACTIVE="active"
elif [[ "$ACTIVE_WS" -ge 3 && "$ACTIVE_WS" -le 4 ]]; then
    RIGHT_ACTIVE="active"
fi

if [[ -n "$SPECIAL_ACTIVE" ]]; then
    SPECIAL_STATE="active"
fi

# Output JSON for Waybar custom module
cat <<EOF
{
  "text": "1-2   3-4   S",
  "tooltip": "Left Monitor (1-2) | Next Monitor (3-4) | Scratchpad",
  "class": "workspaces-group",
  "alt": "groups"
}
EOF
