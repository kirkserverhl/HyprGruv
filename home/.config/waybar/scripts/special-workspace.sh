#!/usr/bin/env bash
# Scratchpad status for Waybar — detect visible special workspace via monitors.
set -euo pipefail

NOTEPAD_ICON='󰎞'

# Visible when any monitor has special:scratchpad open
visible=0
if hyprctl monitors -j 2>/dev/null | jq -e \
    '.[] | select((.specialWorkspace.name // "") == "special:scratchpad")' \
    >/dev/null 2>&1; then
    visible=1
fi

# Windows parked on scratchpad (even if hidden)
has_windows=0
if hyprctl clients -j 2>/dev/null | jq -e \
    '.[] | select(.workspace.name == "special:scratchpad")' \
    >/dev/null 2>&1; then
    has_windows=1
fi

if [[ $visible -eq 1 ]]; then
    echo "{\"text\": \" ${NOTEPAD_ICON} \", \"tooltip\": \"Scratchpad open — click to hide\\nRight-click: focus\", \"class\": \"special active\"}"
elif [[ $has_windows -eq 1 ]]; then
    echo "{\"text\": \" ${NOTEPAD_ICON} \", \"tooltip\": \"Scratchpad has windows — click to show\", \"class\": \"special occupied\"}"
else
    echo "{\"text\": \" ${NOTEPAD_ICON} \", \"tooltip\": \"Scratchpad empty — click to open\", \"class\": \"special\"}"
fi
