#!/bin/bash

clear                        ###########
RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"                 # Bold   ##

display_header() {
	clear
	figlet -f ~/.fonts/Graffiti.flf "$1"
}

aur_helper="$(cat ~/scripts/aur.sh)"
clear
display_header "Cleanup" | lsd-print
echo
$aur_helper -Scc
yay -Rsn $(pacman -Qdtq)
