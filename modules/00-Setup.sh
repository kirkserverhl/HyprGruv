#!/bin/bash


# Remove original Hyprland Configuration and Wallpaper, replace
cp -r ~/.hyprgruv/home/.config/hypr ~/.config

# Remove Default Config
sudo rm -rf /usr/share/hypr

# Doanload Pacman
sudo pacman -S --noconfirm git

# Download Git
git clone https://aur.archlinux.org/yay.git

# Download YAY
cd yay && makepkg -si --noconfirm
cd ~/.hyprgruv

# Update Packages
yay -Syu || update packages

# Doanload Packages needed for Install
yay -S stow figlet powerpill hyprpaper waypaper gum lsd-print-git --noconfirm
