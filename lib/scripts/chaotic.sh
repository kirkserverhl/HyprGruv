#!/bin/bash
# chaotic.sh

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

#   Chaotic Pacman Keys
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sleep .5
sudo pacman-key --lsign-key 3056513887B78AEB
sleep .5

#   Chaotic Pacman Mirrors
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
sleep .5

#  Transfer Pacman Configuration
sudo cp -r $ASSET_DIR/pacman.conf /etc
sleep .5
clear

log_success "Setup Chaotic AUR successfully"
