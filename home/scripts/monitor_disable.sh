#!/usr/bin/env bash

# Define Rofi configuration file and icons
roconf="$HOME/.config/rofi/config-compact.rasi"
enabled_icon="󰹑"
disabled_icon=""

# Function to get the list of monitors and their states
get_monitors() {
    hyprctl monitors | awk -F ' ' '/Monitor/ {getline; if ($NF == "1") print $2 " " "'$enabled_icon'"; else print $2 " " "'$disabled_icon'"}'
}

# Function to toggle monitor state
toggle_monitor() {
    local monitor_name="$1"
    local state="$2"
    local total_monitors enabled_count
    total_monitors=$(hyprctl monitors | grep -c "Monitor")
    enabled_count=$(hyprctl monitors | grep "active: 1" | wc -l)

    if [[ "$state" == "$enabled_icon" ]]; then
        # Prevent disabling the last active monitor
        if [[ "$enabled_count" -le 1 ]]; then
            notify-send "Cannot disable the last active monitor!" -u critical
            return
        fi
        hyprctl output "$monitor_name" disable
    else
        hyprctl output "$monitor_name" enable
    fi
}

# Display the menu and get the selected monitor
monitor=$(get_monitors | rofi -dmenu -theme "$roconf" -p "Monitors")
if [[ -n "$monitor" ]]; then
    monitor_name=$(echo "$monitor" | awk '{print $1}')
    monitor_state=$(echo "$monitor" | awk '{print $2}')
    toggle_monitor "$monitor_name" "$monitor_state"
fi

            




