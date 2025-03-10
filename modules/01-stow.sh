#!/bin/bash
# Stow configuration files module

# Pywal Cache
sudo -r $ASSETS_DIR/wal ~/.cache

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

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

# Navigate to repo directory
cd "$REPO_DIR" || {
	log_error "Failed to change directory to $REPO_DIR"
	exit 1
}

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

# Stow home directory configs
log_status "Applying configurations with stow"
if ! stow -t "$USER_HOME" home --adopt; then
	log_error "Stow failed to apply configurations"
	exit 1
fi

# Update from default Wallpaper
waypaper --wallpaper ~/wallpaper/space_walk.png >/dev/null 2>&1 || true

# Log Status of Stow
log_success "Configuration files stowed successfully"
log_status "Backup saved to: $BACKUP_DIR"
save_choice "last_backup" "$BACKUP_DIR"
exit 0
