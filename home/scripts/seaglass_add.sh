#!/bin/bash

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
# sudo nvim pacman.conf
sudo cp ~/.dotfiles/assets/pacman.conf /etc/pacman.conf
yay -Syyu lightly-qt python-haishoku
yay -Syu ungoogled-chromium powerpill -Su && paru -Su
yay -Syu plasma-desktop kvantum-qt6-git kvantum-qt4-git nx-plaxma-look-and-feel-git
sudo git clone https://github.com/nx-desktop/nx-plasma-look-and-feel.git /usr/share/plasma/look-and-feel/
sudo cp -r -f ~/.dotfiles/assets/sddm /usr/share/sddm/themes/  
sudo cp -r -f ~/.dotfiles/assets/color-schemes /usr/share/color-schemes/
sudo cp -r -f ~/.dotfiles/assets/konsole /usr/share/konsole/  

