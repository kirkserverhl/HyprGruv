#!/bin/bash
# Main installer for Hyprgruv

# Enable error handling
set -e

# Remove original Hyprland Configuration and Wallpaper, replace
sudo rm -rf /usr/share/hyprgruv
sudo cp -r ~/.hyprgruv/assets/hypr /usr/share/hypr


# Load common functions and state management
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

# Setup log file
mkdir -p "$CONFIG_DIR/logs"
LOGFILE="$CONFIG_DIR/logs/install_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$LOGFILE") 2>&1

clear
display_header "Hyprgruv"
log_status "Welcome to Hyprland Gruvbox Installation!"
log_status "Logs will be saved to: $LOGFILE"
echo ""

# Function to run a module if not already completed
run_module() {
	local module="$1"
	local name="$2"

	if is_completed "$name"; then
		log_status "Skipping $name (already completed)"
		return 0
	fi

	display_header "$name"

	if "$SCRIPT_DIR/modules/$module"; then
		mark_completed "$name"
		log_success "$name completed successfully"
		return 0
	else
		log_error "$name failed"
		return 1
	fi
}

# Run essential modules in sequence
run_module "01-packages.sh" "Packages" || exit 1
run_module "02-stow.sh" "Configuration" || exit 1
run_module "03-assets.sh" "Assets" || exit 1

# Run the interactive configuration module
"$SCRIPT_DIR/modules/04-config.sh"

# Show installation summary
display_header "Summary"
log_success "Installation completed successfully!"
echo ""
echo "Completed steps:"
if command_exists jq; then
	jq -r '.completed_steps[]' "$STATE_FILE" | while read step; do
		echo "  ✅ $step"
	done
else
	cat "$CONFIG_DIR/completed_steps.txt" | while read step; do
		echo "  ✅ $step"
	done
fi

echo -e "\n       Hyprland Gruvbox Installation is Complete !! 🫠
        A list of common helpful keybinds is below:" | lsd-print
echo -e "  ⌨️  ▏ 󰖳 + ENTER             👻   Ghostty Terminal
  ⌨️  ▏ 󰖳 + B                     Firefox
  ⌨️  ▏ 󰖳 + F                     Krusader Browser
  ⌨️  ▏ 󰖳 + N                     NeoVim
  ⌨️  ▏ 󰖳 + Q                  󰅙   Close Window
  ⌨️  ▏ 󰖳 + SPACE              󰀻   Rofi App Launcher
  ⌨️  ▏ 󰖳 + CTRL + Q           󰗽   Logout
  ⌨️  ▏ 󰖳 + Mouse Left        🪟   Move Window"

echo -e "\n   Display Full list of keybinds with:  ⌨️  ▏ 󰖳 + SPACE
   or left-click the gear icon    in the Waybar" | lsd-print
echo -e " Restart is required to complete setup !!" | lsd-print
echo ""
echo "What would you like to do next?"
echo "  1. Exit"
echo "  2. Reboot system"
echo "  3. Launch Hyprland"
read -p "Enter your choice [1]: " next_choice
next_choice=${next_choice:-1}

case "$next_choice" in
1)
	log_status "Exiting installer"
	exit 0
	;;
2)
	log_status "Rebooting system"
	sudo reboot
	;;
3)
	log_status "Launching Hyprland"
	exec hyprland
	;;
*)
	log_error "Invalid choice"
	exit 1
	;;
esac
