#!/bin/bash
# chaotic.sh

#   Chaotic Pacman Mirrors
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

#  Transfer Pacman Configuration
sudo cp -r $HYPRGRUV_DIR/assets/pacman.conf /etc/pacman.conf
