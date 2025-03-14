#!/bin/bash
# hyprpm.sh

#  Hyprpm plugins for seaglass theme

hyprpm add https://github.com/hyprwm/hyprland-plugins  # hyprwm
hyprpm add https://github.com/alexhulbert/Hyprchroma   # hyprchroma
hyprpm add https://github.com/DreamMaoMao/hycov        # hycov
hyprpm enable hyprchroma
hyprpm enable hycov

hyprpm update  | lsd-print

clear
