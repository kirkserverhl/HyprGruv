#!/bin/bash
# Waybar Theme Switcher - Fixed

THEMES_DIR="$HOME/.config/waybar/themes"

# Get themes
themes=($(find "$THEMES_DIR" -mindepth 1 -maxdepth 1 -type d ! -name "assets" -exec basename {} \; | sort))

if [ ${#themes[@]} -eq 0 ]; then
    notify-send "Error" "No themes found!"
    exit 1
fi

# Show Rofi
chosen=$(printf '%s\n' "${themes[@]}" | rofi -dmenu -i \
    -config ~/.config/rofi/config-themes.rasi \
    -no-show-icons \
    -width 40 \
    -p "Waybar Theme")

if [[ -n "$chosen" ]]; then
    echo "Switching to: $chosen"

    STATE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/last_layout"
    mkdir -p "$(dirname "$STATE_FILE")"
    echo "$chosen" >"$STATE_FILE"

    "$HOME/.config/waybar/scripts/launch.sh"

    notify-send "Waybar" "Theme switched to: $chosen"
fi
