#!/usr/bin/env bash

# Available themes: alchemy, subtle, ultra_minimal, velvetline

waybar_config_dir="/home/$USER/.config/waybar/themes/subtle"

killall -9 waybar
killall -9 dunst

dunst &
waybar -c "$waybar_config_dir"/config.jsonc -s "$waybar_config_dir"/style.css &
