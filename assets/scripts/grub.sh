#!/bin/bash
# grub.sh

# Set gum theme based on colors.css variables
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"   # Using --color5 (teal)
export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"   # Using --background
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010" # Using --background
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#c3c3c3" # Using --foreground

# Set other gum colors for consistency
export GUM_INPUT_CURSOR_FOREGROUND="#c3c3c3" # Using --cursor
export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B" # Using --color3 (green)
export GUM_SPIN_SPINNER_FOREGROUND="#749D91" # Using --color6 (cyan)

RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HOME/.hyprgruv/lib/common.sh"
source "$HOME/.hyprgruv/lib/state.sh"

# Move Grub file
sudo cp -r ~/.hyprgruv/assets/tartarus/grub /etc/default/grub

# Move Grub Assets
sudo cp -r ~/.hyprgruv/assets/tartarus /usr/share/grub/themes/tartarus

# Compile Grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
