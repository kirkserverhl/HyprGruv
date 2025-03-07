#!/bin/bash

# Move Grub Package
sudo ln -s ~/.hyprgruv/tartarus /usr/share/grub/themes/tartarus

# Move Grub Config
cp -r ~/.hyprgruv/assets/grub /etc/default/grub

# Compile Grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
