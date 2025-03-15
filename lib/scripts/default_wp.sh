#!/bin/bash
# default_wp.sh

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

# Check if Hyprpaper is installed, install it if not
if ! command_exists waypaper; then
    log_status "waypaper not found. Installing with yay..."
    if command_exists yay; then
        if run_command "yay -S --noconfirm waypaper" "Installing waypaper"; then
            log_success "waypaper installed successfully"
        else
            log_error "Failed to install waypaper. Please install it manually and run this script again."
            exit 1
        fi
    else
        log_error "yay is not installed. Please install waypaper manually and run this script again."
        exit 1
    fi
fi

# Check if Waypaper is installed, install it if not
if ! command_exists waypaper; then
    log_status "waypaper not found. Installing with yay..."
    if command_exists yay; then
        if run_command "yay -S --noconfirm waypaper" "Installing waypaper"; then
            log_success "waypaper installed successfully"
        else
            log_error "Failed to install waypaper. Please install it manually and run this script again."
            exit 1
        fi
    else
        log_error "yay is not installed. Please install waypaper manually and run this script again."
        exit 1
    fi
fi


# Update from default Wallpaper
waypaper --wallpaper $HYPR_DIR/home/wallpaper/space_walk.png >/dev/null 2>&1 || true
sleep 1

clear
log_success "Setup Wallpaper successfully"
