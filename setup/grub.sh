#!/bin/bash

git clone https://github.com/AllJavi/tartarus-grub.git
cd tartarus-grub
sudo cp tartarus -r /usr/share/grub/themes/


cp -r ~/.hyprgruv/assets/ /etc/default/grub

sudo grub-mkconfig -o /boot/grub/grub.cfg
