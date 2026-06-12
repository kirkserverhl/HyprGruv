#!/bin/bash

# Log file for debugging
LOG_FILE="$HOME/.config/hypr/scripts/update_wallpaper.log"

# Path to the file containing the wallpaper path
CURRENT_WALLPAPER_FILE="$HOME/.config/settings/cache/current_wallpaper"
DEFAULT_WALLPAPER_FILE="$HOME/.config/settings/default"

echo "Running update_wallpaper.sh on $(date)" >>"$LOG_FILE"

# Ensure the current_wallpaper file exists
if [[ ! -f "$CURRENT_WALLPAPER_FILE" && ! -f "$DEFAULT_WALLPAPER_FILE" ]]; then
    echo "Error: current_wallpaper file not found." >>"$LOG_FILE"
    exit 1
fi

# Read the wallpaper path from the file (prefer cache, fallback to default)
if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
    CURRENT_WALLPAPER=$(cat "$CURRENT_WALLPAPER_FILE")
else
    CURRENT_WALLPAPER=$(cat "$DEFAULT_WALLPAPER_FILE")
fi

# Ensure the wallpaper file exists (it should be symlinked)
if [[ ! -f "$CURRENT_WALLPAPER" ]]; then
    echo "Error: Wallpaper file not found: $CURRENT_WALLPAPER" >>"$LOG_FILE"
    exit 1
fi

# Update the wallpaper using waypaper (this will run post_command which does matugen + palette chooser)
echo "Setting wallpaper to: $CURRENT_WALLPAPER" >>"$LOG_FILE"
SKIP_PALETTE_CHOOSER=0 waypaper --wallpaper "$CURRENT_WALLPAPER" >>"$LOG_FILE" 2>&1 || true

# If you want a non-interactive re-apply (matugen only, no palette popup), use:
# SKIP_PALETTE_CHOOSER=1 waypaper --wallpaper "$CURRENT_WALLPAPER" ... 
# or just call: ~/.config/hypr/scripts/restore_wallpaper.sh

# If you use pywal, you can regenerate the colorscheme as well
# Uncomment the following line if you want to use pywal
# pywal -i "$CURRENT_WALLPAPER" >> "$LOG_FILE" 2>&1

echo "Wallpaper update complete." >>"$LOG_FILE"
