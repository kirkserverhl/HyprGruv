#!/bin/bash

# Find the next empty workspace
#NEXT_WORKSPACE=$(hyprctl workspaces | grep -oP '\d+' | sort -n | tail -n 1)
#NEXT_WORKSPACE=$((NEXT_WORKSPACE + 1))

# Switch to the new workspace
#hyprctl dispatch workspace $NEXT_WORKSPACE

# Run the doom command in that workspace
cd ~/terminal-doom && zig-out/bin/terminal-doom

