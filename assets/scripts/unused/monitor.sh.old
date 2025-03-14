#!/bin/bash
# monitor.sh

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

# Path to the monitor.conf file that we want to modify
monitor_conf="~/.config/hypr/conf/monitor.conf"

# Expand the ~ symbol to the full home directory path
monitor_conf=$(eval echo $monitor_conf)

# Dynamically list all available configuration files in the monitors directory
monitor_dir="$HOME/.hyprgruv/home/.config/hypr/conf/monitors"
configs=($(find "$monitor_dir" -type f -name "*.conf"))

if gum confirm " Do you want to ignore monitor.conf in Git ?  "; then
	echo "Ignore Git ..." | lsd-print
	echo " Marking monitor.conf as assume-unchanged in Git..."
	git update-index --assume-unchanged "$monitor_conf"
	echo " monitor.conf is now ignored by Git."
	echo ""
else
	echo " Ensuring monitor.conf is tracked by Git..." | lsd-print
	git update-index --no-assume-unchanged "$monitor_conf"
	echo " monitor.conf is now being tracked by Git." | lsd-print
fi

# Display available configurations to the user
echo ""
echo " Available monitor configurations:" | lsd-print
for i in "${!configs[@]}"; do
	config_name=$(basename "${configs[$i]}")
	echo "$((i + 1)). $config_name"
done

# Prompt user to select a configuration
echo ""
read -p " Enter the number of your choice: " choice | lsd-print
echo ""

# Validate the choice
if [[ "$choice" -ge 1 && "$choice" -le "${#configs[@]}" ]]; then
	selected_conf="${configs[$((choice - 1))]}"
	selected_name=$(basename "$selected_conf")
	echo " You selected: $selected_name" | lsd-print
else
	echo " Invalid choice. Exiting." | lsd-print
	exit 1
fi

# Update the monitor.conf file with the selected configuration
echo " Updating monitor.conf to use $selected_conf..."
sed -i "s|source = .*|source = $selected_conf|" "$monitor_conf"

# Send a dunst notification
notify-send -u normal -t 3000 "Monitor Configuration Updated" "Selected: $selected_name"

echo " monitor.conf has been updated successfully!" | lsd-print
