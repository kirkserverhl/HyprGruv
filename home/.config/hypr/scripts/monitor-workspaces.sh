#!/bin/bash
# Hyprland dynamic workspace reassignment on monitor hotplug

reassign_workspaces() {
    # Get currently connected monitors
    local monitors=$(hyprctl monitors -j | jq -r '.[].name')

    # Default to safe high-number workspace while we rearrange
    hyprctl dispatch workspace 99 >/dev/null 2>&1

    if echo "$monitors" | grep -q "DVI-I-2" && echo "$monitors" | grep -q "HDMI-A-1"; then
        # Full setup: already handled by the static workspace= rules above
        echo "Full three-monitor setup active"
    elif echo "$monitors" | grep -q "DVI-I-2" && ! echo "$monitors" | grep -q "HDMI-A-1"; then
        # HDMI gone → move 7-9 to DP-1 (or DVI-I-1, your choice)
        hyprctl dispatch moveworkspacetomonitor 7 DVI-I-2
        hyprctl dispatch moveworkspacetomonitor 8 DVI-I-2
        hyprctl dispatch moveworkspacetomonitor 9 DVI-I-2
        # 6-10 now all on DP-1 (combined)
    elif ! echo "$monitors" | grep -q "DP-1" && echo "$monitors" | grep -q "HDMI-A-1"; then
        # DP-1 gone → move 1-3+10 to HDMI-A-1 and combine 6-10 there too if you want
        hyprctl dispatch moveworkspacetomonitor 1 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 2 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 3 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 10 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 6 HDMI-A-1 # combine 6-10
        hyprctl dispatch moveworkspacetomonitor 7 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 8 HDMI-A-1
        hyprctl dispatch moveworkspacetomonitor 9 HDMI-A-1
    else
        # Neither DP-1 nor HDMI-A-1 present → only DVI-I-1 left
        # Collapse to 6 workspaces total
        for ws in 1 2 3 4 5 6; do
            hyprctl dispatch moveworkspacetomonitor "$ws" DVI-I-1
        done
        # Workspaces 7-10 are still alive but hidden on the single monitor
        # You can ignore them or move them too if you want
        echo "Single-monitor fallback: only 6 workspaces"
    fi

    # Return to workspace 1 on the focused monitor
    hyprctl dispatch workspace 1
}

# Listen for monitor events
socat - UNIX-CONNECT:/tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while read -r line; do
    if [[ $line == monitoradded* ]] || [[ $line == monitorremoved* ]]; then
        sleep 1 # give Hyprland a moment to update
        reassign_workspaces
    fi
done
