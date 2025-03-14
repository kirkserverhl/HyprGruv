#!/bin/bash
# paclist - creates list of all installed packages
# reinstall with pacman -S $(cat pkglist)

USER=kirk

pacman -Qqet | grep -v "$(pacman -Qqg)" | grep -v "$(pacman -Qqm)" >/home/$USER/.dotfiles/pkglist

# A list of local packages (includes AUR and locally installed)
pacman -Qm >/home/$USER/.hyprgruv/home/pkglocallist
