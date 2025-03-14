#!/bin/bash
# 03-setup.sh

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

# Copy Local Plugins (Nvim, Hyprpm, Zinit, etc)
cp -r $CONFIG_DIR/.local $HOME
sleep 1

# Copy bashrc
cp -r $CONFIG_DIR/.bashrc $HOME
sleep 1

# Pacman setup
sudo cp -r $CONFIG_DIR/pacman.conf /etc/ &
progress -mp $!
sleep 1

# Load Wallpaper
gum spin -- $CONFIG_DIR/scripts/default_wp.sh
sleep 1

# Chaotic Pacman Mirrors
sudo $CONFIG_DIR/scripts/chatoic.sh
sleep 1

# Hyprpm plugs
$CONFIG_DIR/scripts/hyprpm.sh
sleep 1

# Screenshot & Photo Folder
gum spin -- $CONFIG_DIR/scripts/screenshot_folder.sh
sleep 1

# Eza-Preview for Yazi
git clone https://github.com/sharklasers996/eza-preview.yazi ~/.config/yazi/plugins/eza-preview.yazi
sleep 1

clear
