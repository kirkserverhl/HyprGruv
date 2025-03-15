#!/bin/bash
# Stow configuration files module

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

#RESET="\e[0m"
#GREEN="\e[38;2;142;192;124m"
#CYAN="\e[38;2;69;133;136m"
#YELLOW="\e[38;2;215;153;33m"
#RED="\e[38;2;204;36;29m"
#GRAY="\e[38;2;60;56;54m"
#BOLD="\e[1m"

log_status "Starting configuration stowing process"

# Create a timestamped backup directory
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_DIR="$HOME/.local/backup/hyprgruv_$TIMESTAMP"

# Create backup directory
mkdir -p "$BACKUP_DIR"
log_status "Created backup directory: $BACKUP_DIR"

# Set repo directory
REPO_DIR="$HOME/.hyprgruv"
USER_HOME="$HOME"

# Clone repository if it doesn't exist
if [ ! -d "$REPO_DIR" ]; then
    log_status "Cloning repository"
    if ! git clone https://github.com/kirkserverhl/hyorgruv "$REPO_DIR"; then
        log_error "Failed to clone repository"
        exit 1
    fi
fi
sleep 1

# Check if stow is installed, install it if not
if ! command_exists stow; then
    log_status "stow not found. Installing with yay..."
    if command_exists yay; then
        if run_command "yay -S --noconfirm stow" "Installing stow"; then
            log_success "stow installed successfully"
        else
            log_error "Failed to install stow. Please install it manually and run this script again."
            exit 1
        fi
    else
        log_error "yay is not installed. Please install stow manually and run this script again."
        exit 1
    fi
fi

# Navigate to repo directory
cd "$REPO_DIR" || { log_error "Failed to change directory to $REPO_DIR"; exit 1; }

# Backup existing files
log_status "Backing up existing files"
for file in $(ls -A "$REPO_DIR/home"); do
    if [ -e "$USER_HOME/$file" ]; then
        # Create subdirectories in backup folder to maintain structure
        PARENT_DIR=$(dirname "$BACKUP_DIR/${file}")
        mkdir -p "$PARENT_DIR"

        # Copy the file to backup directory (preserving structure)
        log_status "Backing up: $file"
        cp -r "$USER_HOME/$file" "$BACKUP_DIR/${file}"
    fi
done

# Remove Default Hyprland Configuration
rm -rf $USER_HOME/.config/hypr/hyprland.conf
sleep .5

# Stow home directory configs
log_status "Applying configurations with stow"
if ! stow -t "$USER_HOME" home --adopt; then
	log_error "Stow failed to apply configurations"
	exit 1
fi

log_success "Configuration files stowed successfully"
log_status "Backup saved to: $BACKUP_DIR"
save_choice "last_backup" "$BACKUP_DIR"
sleep 2
clear

exit 0
