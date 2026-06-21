#!/usr/bin/env bash
# scratchpad.sh — toggle scratchpad; spawn terminal if opened empty
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

scratchpad_visible() {
    hyprctl monitors -j | jq -e \
        '.[] | select((.specialWorkspace.name // "") == "special:scratchpad")' \
        >/dev/null
}

scratchpad_has_windows() {
    hyprctl clients -j | jq -e '.[] | select(.workspace.name == "special:scratchpad")' >/dev/null
}

hide_scratchpad() {
    # Toggle once per monitor where scratchpad is visible (Hyprland is per-monitor).
    local attempts=0
    while scratchpad_visible && [[ $attempts -lt 8 ]]; do
        local mon
        mon="$(hyprctl monitors -j | jq -r \
            '.[] | select((.specialWorkspace.name // "") == "special:scratchpad") | .name' | head -1)"
        [[ -n "$mon" && "$mon" != "null" ]] || break
        hyprctl dispatch "hl.dsp.focus({ monitor = '$mon' })" >/dev/null
        hyprctl dispatch "hl.dsp.workspace.toggle_special('scratchpad')" >/dev/null
        attempts=$((attempts + 1))
        sleep 0.1
    done
}

if scratchpad_visible; then
    hide_scratchpad
    exit 0
fi

if scratchpad_has_windows; then
    hyprctl dispatch "hl.dsp.workspace.toggle_special('scratchpad')"
    exit 0
fi

hyprctl dispatch "hl.dsp.exec_cmd('$SCRIPT_DIR/terminal.sh', { workspace = 'special:scratchpad silent' })"
sleep 0.15
hyprctl dispatch "hl.dsp.workspace.toggle_special('scratchpad')"