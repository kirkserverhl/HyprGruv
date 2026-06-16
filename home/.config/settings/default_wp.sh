#!/bin/bash
# ~/.config/settings/default_wp.sh
#
# Canonical "default wallpaper" for this system.
# - SDDM themes (sugar-candy and any others) are configured once to point here:
#     Background="/home/kirk/.config/settings/default_wp.png"
# - Waypaper (via set_wallpaper.sh) keeps this file up-to-date whenever you
#   select a new desktop wallpaper.
# - The actual pixels live in the sibling default_wp.png (always normalized to PNG).
#
# Usage in other scripts:
#   source "$HOME/.config/settings/default_wp.sh"
#   echo "Using default: $DEFAULT_WALLPAPER"
#
# For dotfiles (hyprgruv etc.):
#   Keep this .sh (and optionally a seed default_wp.png) in your repo at
#   home/.config/settings/default_wp.sh
#   The live .png is usually .gitignore'd because it changes often and is large.
#   On a fresh deploy you can either let the first wallpaper change populate it,
#   or copy a "seed" image you commit as default_wp.png.seed or similar.

DEFAULT_WALLPAPER="$HOME/.config/settings/default_wp.png"

# Also expose the *source* path (the original chosen file) if you want it.
# This is the last desktop wallpaper you explicitly picked.
CURRENT_SOURCE_WALLPAPER_FILE="$HOME/.config/last_wallpaper.txt"
if [ -f "$CURRENT_SOURCE_WALLPAPER_FILE" ]; then
    CURRENT_SOURCE_WALLPAPER=$(cat "$CURRENT_SOURCE_WALLPAPER_FILE")
else
    CURRENT_SOURCE_WALLPAPER=""
fi

export DEFAULT_WALLPAPER
export CURRENT_SOURCE_WALLPAPER
