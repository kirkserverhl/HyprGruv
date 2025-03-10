#!/bin/bash

cp -rf $ASSETS_DIR/.mozilla ~/
cp -rf $ASSETS_DIR/nvim ~/.local

#   Chaotic Pacman Mirrors
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

#  Transfer Pacman Configuration
sudo cp -r $ASSETS_DIR/pacman.conf /etc/pacman.conf

#  Hyprpm plugins for seaglass theme
hyprpm add https://github.com/hyprwm/hyprland-plugins # hyprwm
hyprpm add https://github.com/alexhulbert/Hyprchroma  # hyprchroma
hyprpm add https://github.com/DreamMaoMao/hycov       #hycov
hyprpm enable hyprchroma
hyprpm enable hycov
hyprpm update
clear
