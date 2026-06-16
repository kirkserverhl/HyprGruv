#!/usr/bin/env bash
# Shows special workspace (scratchpad) status for Waybar

SPECIAL=$(hyprctl workspaces -j 2>/dev/null | jq -r '.[] | select(.name | startswith("special:")) | .name' | head -1)

if [[ -n "$SPECIAL" ]]; then
    echo '{"text": "󰖯", "tooltip": "Scratchpad — active (click to hide)", "class": "special active"}'
else
    echo '{"text": "󰖯", "tooltip": "Scratchpad (click to toggle)", "class": "special"}'
fi