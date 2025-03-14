#!/bin/bash

cd ~/.dotfiles || exit
touch ~/.config/hypr/hyprland.conf > /dev/null 2>&1
rm ~/.config/hypr/hyprland.conf > /dev/null 2>&1
stow hypr --adopt > /dev/null 2>&1
waypaper --random > /dev/null 2>&1
touch ~/.config/hypr/hyprland.conf > /dev/null 2>&1



