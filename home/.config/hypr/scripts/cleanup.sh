#!/bin/bash

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOME/.hyprgruv/lib/common.sh"
source "$HOME/.hyprgruv/lib/state.sh"

# Load current matugen colors and apply to gum
source "$HOME/.config/hypr/scripts/colors.sh"
gum_apply_matugen_theme
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
###########
RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"                 # Bold   ##

sleep 1
aur_helper="$(bat ~/.config/hypr/scripts/aur.sh)"
echo ""
sleep1
$aur_helper -Scc
yay -Rsn $(pacman -Qdtq)
sleep 1
clear

duf -theme ansi
sleep 2
