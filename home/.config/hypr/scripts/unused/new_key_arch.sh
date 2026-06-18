#!/bin/bash
# new_key_arch.sh
source "$HOME/.hypr/lib/common.sh"

echo ""
sudo rm -rf /etc/pacman.d/gnupg
echo "Removed /etc/pacman.d/gnupg"
echo ""
sleep 1

sudo pacman-key --init
echo "Init new Pacman-key"
echo ""
sleep 1

sudo pacman-key --populate
echo "Populate new Pacman-key"
sleep 1
echo ""

echo "Updating Pacman Packages"
sudo pacman -Syu


echo "Pacman Keys Cleaned and Updated  🔑"
sleep 1
