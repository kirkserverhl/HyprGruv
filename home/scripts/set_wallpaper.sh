#!/bin/bash

# Path to the configuration file
config_file="~/" # Ct:qhange:qhange this to the actual path of your config file

# Path to the wallpaper directory
wallpaper_dir="$HOME/wallpaper"

# Default fallback image path
default_image="$HOME/default.png"

# Last known wallpaper image (persistent across script runs)
last_wallpaper="$HOME/.config/last_wallpaper.txt"

# Read the current wallpaper path from the config file
#current_wallpaper=$(grep -E "^wallpaper" "$" | cut -d' ' -f3)
current_wallpaper=$(cat /home/kirk/.cache/wal/wal)

# Resolve tilde (~) to full path
current_wallpaper=$(echo $current_wallpaper | sed "s|^~|$HOME|")

# Check if the wallpaper is set or if it's blank
if [[ -z "$current_wallpaper" || ! -f "$current_wallpaper" ]]; then
	# If no image is set or the image file doesn't exist, use the last known wallpaper
	if [[ -f "$last_wallpaper" ]]; then
		current_wallpaper=$(cat "$last_wallpaper")
	fi

	# If there is still no valid wallpaper, fallback to the default image
	if [[ ! -f "$current_wallpaper" ]]; then
		current_wallpaper="$default_image"
	fi
fi

# Update the wallpaper using swww or another wallpaper setter
# swww img "$current_wallpaper"
source $HOME/scripts/wallpaper.sh
# Save the current wallpaper path for future reference
echo "$current_wallpaper" >"$last_wallpaper"
