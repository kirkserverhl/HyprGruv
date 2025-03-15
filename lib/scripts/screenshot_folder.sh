#!/bin/bash
# screenshot_folder.sh

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


#  Create Folders for Screenshots and Pictures

mkdir -p ~/Pictures
sleep .2

screenshot_folder="$HOME/Pictures"
sleep .2
clear

log_success "Setup Photo Directory successfully"
