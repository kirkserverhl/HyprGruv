#!/bin/bash
# 03-setup.sh


# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

display_header "SETUP"

# Check if gum is installed, install it if not
if ! command_exists gum; then
    log_status "gum not found. Installing with yay..."
    if command_exists yay; then
        if run_command "yay -S --noconfirm gum" "Installing gum"; then
            log_success "gum installed successfully"
        else
            log_error "Failed to install gum. Please install it manually and run this script again."
            exit 1
        fi
    else
        log_error "yay is not installed. Please install gum manually and run this script again."
        exit 1
    fi
fi

# Define scripts to run with descriptions
declare -A SETUP_SCRIPTS=(
    ["$SCRIPTS/hard_copy.sh"]="Hard Copy Files in Root Directory"
    ["$SCRIPTS/default_wp.sh"]="Loading default wallpaper"
    ["$SCRIPTS/chatoic.sh"]="Configuring Chaotic Pacman mirrors"
    ["$SCRIPTS/hyprpm.sh"]="Installing Hyprpm plugins"
)

# Run each script in sequence
for script in "${!SETUP_SCRIPTS[@]}"; do
    description="${SETUP_SCRIPTS[$script]}"

    log_status "Starting: $description"
    if gum spin -- "$script"; then
        log_success "$description completed"
    else
        log_error "$description failed"
    fi

    # Sleep between scripts
    sleep 2
done
clear

log_success "Setup completed successfully"

