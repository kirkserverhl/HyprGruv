#!/bin/bash

# ================================================
# Hyprland Window Layout / Rules Switcher with Rofi
# ================================================

WINDOWS_OPTIONS_DIR="$HOME/.config/hypr/conf/windows"
WINDOW_CONF="$HOME/.config/hypr/conf/window.conf"

# Create directory if it doesn't exist
mkdir -p "$WINDOWS_OPTIONS_DIR"

if [ ! -d "$WINDOWS_OPTIONS_DIR" ]; then
    notify-send "Hyprland Window Switcher" "Error: Could not create windows directory!" -u critical
    exit 1
fi

# Get list of available window configs (without .conf extension)
mapfile -t configs < <(ls -1 "$WINDOWS_OPTIONS_DIR"/*.conf 2>/dev/null | xargs -n1 basename | sed 's/\.conf$//' | sort)

if [ ${#configs[@]} -eq 0 ]; then
    notify-send "Hyprland Window Switcher" "No window configuration files found in\n$WINDOWS_OPTIONS_DIR\n\nAdd some .conf files and try again." -u critical
    exit 1
fi

# Show Rofi menu
chosen=$(printf '%s\n' "${configs[@]}" | rofi -dmenu \
    -i \
    -p "Window Layout" \
    -mesg "Select window rules / formatting to apply" \
    -theme-str 'window {width: 520px;}' )

[ -z "$chosen" ] && exit 0

# Full path to selected file
selected_file="$WINDOWS_OPTIONS_DIR/${chosen}.conf"

if [ ! -f "$selected_file" ]; then
    notify-send "Error" "Selected window config not found!" -u critical
    exit 1
fi

# Backup current window.conf if it exists
if [ -f "$WINDOW_CONF" ]; then
    cp "$WINDOW_CONF" "${WINDOW_CONF}.bak"
fi

# Apply the new window rules
cp "$selected_file" "$WINDOW_CONF"

# Reload Hyprland
hyprctl reload

# Success notification
notify-send "Hyprland Window Switcher" "✅ Applied window layout:\n${chosen}" -u normal -t 4000
