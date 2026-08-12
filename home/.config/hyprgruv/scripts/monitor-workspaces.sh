#!/bin/bash
# Dynamic workspace reassignment on monitor hotplug
# Supports 2 workspaces per monitor groups (1-2, 3-4, 5-6, 7-8)

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APPLY_LAPTOP="$SCRIPTS/apply-laptop-monitors.sh"

apply_laptop_layout() {
    # Wait until hyprctl sees the new set. The old Lua hook ran too early,
    # treated the dock as missing, and flipped LG onto the right.
    sleep 1.2
    if [[ -x "$APPLY_LAPTOP" ]]; then
        "$APPLY_LAPTOP" || true
    fi
}

reassign_workspaces() {
    apply_laptop_layout

    local machine
    machine="$(tr -d '[:space:]' <"${HOME}/.config/settings/machine.sh" 2>/dev/null || true)"
    # Laptop docked layout + 2-per-monitor pins are handled by apply-laptop-monitors.sh.
    if [[ "$machine" == "laptop" ]]; then
        echo ":: Laptop profile — workspace pairs applied by apply-laptop-monitors.sh"
        return 0
    fi

    local monitors=$(hyprctl monitors -j | jq -r '.[].name')
    local count=$(echo "$monitors" | wc -l)

    echo ":: Monitor change detected. Reassigning workspaces for $count monitor(s)..."
}

# Listen for monitor events via Hyprland socket
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    echo "Not running under Hyprland"
    exit 1
fi

# Dock is usually already up at login — pin left/right before waiting on events.
if [[ -x "$APPLY_LAPTOP" ]]; then
    "$APPLY_LAPTOP" || true
fi

socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == monitoradded* ]] || [[ $line == monitorremoved* ]]; then
        reassign_workspaces
    fi
done
