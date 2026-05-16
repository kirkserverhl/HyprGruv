#!/bin/bash

# ================================================
# Hyprland Personal ↔ Work Mode Toggle
# One key switches between Personal (3 monitors + waybar) and Work (2 monitors + minimal + no waybar)
# ================================================

# === Paths (updated to your exact structure) ===
MONITOR_DIR="$HOME/.config/hypr/conf/monitors"
WINDOW_DIR="$HOME/.config/hypr/conf/windows"

MONITOR_CONF="$HOME/.config/hypr/conf/monitor.conf"
WINDOW_CONF="$HOME/.config/hypr/conf/window.conf"

STATE_FILE="$HOME/.config/hypr/.current_mode"

# Ensure directories exist
mkdir -p "$MONITOR_DIR" "$WINDOW_DIR" "$HOME/.config/hypr/conf"

# Read current mode (default to Personal if first run)
if [ -f "$STATE_FILE" ]; then
    CURRENT_MODE=$(cat "$STATE_FILE")
else
    CURRENT_MODE="personal"
fi

# === Toggle Logic ===
if [ "$CURRENT_MODE" = "personal" ]; then
    # Switch TO Work mode
    NEW_MODE="work"
    
    # Apply monitor config
    if [ -f "$MONITOR_DIR/2_monitors.conf" ]; then
        cp "$MONITOR_DIR/2_monitors.conf" "$MONITOR_CONF"
    else
        notify-send "Toggle Error" "Missing: 2_monitors.conf" -u critical
        exit 1
    fi

    # Apply window rules
    if [ -f "$WINDOW_DIR/minimal-work.conf" ]; then
        cp "$WINDOW_DIR/minimal-work.conf" "$WINDOW_CONF"
    else
        notify-send "Toggle Error" "Missing: minimal-work.conf" -u critical
        exit 1
    fi

    # Kill Waybar
    pkill -x waybar

    notify-send "Work Mode Activated" "2 monitors + minimal layout\nWaybar hidden" -t 3000

else
    # Switch TO Personal mode
    NEW_MODE="personal"

    # Apply monitor config
    if [ -f "$MONITOR_DIR/default.conf" ]; then
        cp "$MONITOR_DIR/default.conf" "$MONITOR_CONF"
    else
        notify-send "Toggle Error" "Missing: default.conf" -u critical
        exit 1
    fi

    # Apply window rules
    if [ -f "$WINDOW_DIR/default.conf" ]; then
        cp "$WINDOW_DIR/default.conf" "$WINDOW_CONF"
    else
        notify-send "Toggle Error" "Missing: default.conf in windows folder" -u critical
        exit 1
    fi

    # Restart Waybar
    #pkill -x waybar
    #sleep 0.5
    #waybar &
    ~/scripts/launch.sh

    notify-send "Personal Mode Activated" "3 monitors + default layout\nWaybar visible" -t 3000
fi

# Save new mode
echo "$NEW_MODE" > "$STATE_FILE"

# Reload Hyprland to apply monitor + window changes
hyprctl reload
