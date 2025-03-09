#!/bin/bash

# Remove original Hyprland Configuration and Wallpaper, replace
cp -r ~/.hyprgruv/home/.config/hypr ~/.config

# Remove Default Config
sudo rm -rf /usr/share/hypr
