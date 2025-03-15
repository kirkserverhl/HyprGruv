#!/bin/bash
# hyprpm.sh

# Load common functions and state management
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

RESET="\e[0m"
GREEN="\e[38;2;142;192;124m"
CYAN="\e[38;2;69;133;136m"
YELLOW="\e[38;2;215;153;33m"
RED="\e[38;2;204;36;29m"
GRAY="\e[38;2;60;56;54m"
BOLD="\e[1m"

#  Add Hyprpm plugins for seaglass theme
hyprpm add https://github.com/hyprwm/hyprland-plugins  # hyprwm
sleep .5
hyprpm add https://github.com/alexhulbert/Hyprchroma   # hyprchroma
sleep .5
hyprpm add https://github.com/DreamMaoMao/hycov        # hycov
sleep .5

#  Enable Hyprland Plugins
hyprpm enable hyprchroma
hyprpm enable hycov
sleep 1

#  Update Hyprpm and Plugins
hyprpm update  | lsd-print
sleep 1
clear

log_success "Setup Hyprpm successfully"
