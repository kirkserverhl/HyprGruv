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

    # --- Style switching (clean, non-destructive) ---
    # We maintain a symlink so the root style.css can @import "themes/current/style.css"
    rm -f "$THEMES_DIR/current"
    ln -s "$THEMES_DIR/$chosen" "$THEMES_DIR/current"

    # --- Config switching (optional per-theme layouts) ---
    if [ -f "$THEMES_DIR/$chosen/config.jsonc" ]; then
        cp "$THEMES_DIR/$chosen/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    fi

    # Reload waybar gracefully
    pkill -SIGUSR2 waybar 2>/dev/null || waybar &

    notify-send "Waybar" "Theme switched to: $chosen"
fi
