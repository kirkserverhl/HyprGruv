#!/bin/bash

# Restart Hyprpaper
hyprpaper &

# Wait for 5 seconds to ensure Hyprpaper is fully activated
sleep 5

# Restore the wallpaper using Waypaper
waypaper --restore

