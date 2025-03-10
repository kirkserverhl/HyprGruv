#!/bin/bash

# Log file for debugging
LOG_FILE="$HOME/scripts/update_wallpaper.log"

# Path to the file containing the wallpaper path
CURRENT_WALLPAPER_FILE="$HOME/.config/settings/cache/current_wallpaper"

echo "Running update_wallpaper.sh on $(date)" >> "$LOG_FILE"

# Ensure the current_wallpaper file exists
if [[ ! -f "$CURRENT_WALLPAPER_FILE" ]]; then
    echo "Error: current_wallpaper file not found." >> "$LOG_FILE"
    exit 1
fi

# Read the wallpaper path from the file
CURRENT_WALLPAPER=$(cat "$CURRENT_WALLPAPER_FILE")

# Ensure the wallpaper file exists (it should be symlinked)
if [[ ! -f "$CURRENT_WALLPAPER" ]]; then
    echo "Error: Wallpaper file not found: $CURRENT_WALLPAPER" >> "$LOG_FILE"
    exit 1
fi

# Update the wallpaper using waypaper
echo "Setting wallpaper to: $CURRENT_WALLPAPER" >> "$LOG_FILE"
waypaper --wallpaper "$CURRENT_WALLPAPER" >> "$LOG_FILE" 2>&1

# If you use pywal, you can regenerate the colorscheme as well
# Uncomment the following line if you want to use pywal
# pywal -i "$CURRENT_WALLPAPER" >> "$LOG_FILE" 2>&1

echo "Wallpaper update complete." >> "$LOG_FILE"

