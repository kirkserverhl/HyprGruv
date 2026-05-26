#!/bin/bash
# Dynamic workspace reassignment on monitor hotplug
# Supports 2 workspaces per monitor groups (1-2, 3-4, 5-6, 7-8)

reassign_workspaces() {
    local monitors=$(hyprctl monitors -j | jq -r '.[].name')
    local count=$(echo "$monitors" | wc -l)

    echo ":: Monitor change detected. Reassigning workspaces for $count monitor(s)..."

    # Move focus away temporarily
    hyprctl dispatch workspace 99 >/dev/null 2>&1

    if [[ $count -ge 4 ]]; then
        # 4 monitors: ideal 2-per-monitor layout
        echo "  → 4-monitor mode (2 workspaces each)"
        # Workspaces should already be pinned correctly via workspaces.conf

    elif [[ $count -eq 3 ]]; then
        # 3 monitors: distribute 8 workspaces across 3 screens (e.g. 3+3+2 or 2+3+3)
        echo "  → 3-monitor mode"
        # Example: move 7-8 to the last remaining monitor
        # You can customize this logic

    elif [[ $count -eq 2 ]]; then
        echo "  → 2-monitor mode (4 workspaces each recommended)"
        # Move workspaces 5-8 to the second monitor
        for ws in 5 6 7 8; do
            hyprctl dispatch moveworkspacetomonitor "$ws" "$(echo "$monitors" | tail -1)" 2>/dev/null
        done

    elif [[ $count -eq 1 ]]; then
        echo "  → Single monitor fallback (all workspaces collapsed)"
        local single_monitor=$(echo "$monitors" | head -1)
        for ws in {1..8}; do
            hyprctl dispatch moveworkspacetomonitor "$ws" "$single_monitor" 2>/dev/null
        done
    fi

    # Return focus to workspace 1
    sleep 0.2
    hyprctl dispatch workspace 1
}

# Listen for monitor events via Hyprland socket
if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    echo "Not running under Hyprland"
    exit 1
fi

socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == monitoradded* ]] || [[ $line == monitorremoved* ]]; then
        sleep 0.8
        reassign_workspaces
    fi
done
