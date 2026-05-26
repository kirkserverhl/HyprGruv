#!/usr/bin/env bash
# Shows special workspace (scratchpad) status for Waybar

SPECIAL=$(hyprctl workspaces -j 2>/dev/null | jq -r '.[] | select(.name | startswith("special:")) | .name' | head -1)

if [[ -n "$SPECIAL" ]]; then
    echo '{"text": "S", "tooltip": "Scratchpad (Special Workspace) - Active", "class": "special active"}'
else
    echo '{"text": "S", "tooltip": "Scratchpad (Special Workspace)", "class": "special"}'
fi
