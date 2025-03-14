#!/bin/bash
#04-config.sh

# Set gum theme based on colors.css variables
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"   # Using --color5 (teal)
export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"   # Using --background
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010" # Using --background
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#282828" # Using --foreground

# Set other gum colors for consistency
export GUM_INPUT_CURSOR_FOREGROUND="#282828" # Using --cursor
export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B" # Using --color3 (green)
export GUM_SPIN_SPINNER_FOREGROUND="#749D91" # Using --color6 (cyan)

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"                 # Bold   ##

# Ask user for confirmation SDDMu
sleep .5
echo ""
display_header "SDDM"
sleep .5

if gum confirm "  🍬     Would you like to install Sugar-Candy SDDM theme?  "; then
	sleep 1
	echo "Configuring Shell..." | lsd-print
	sleep 1

	# Check if SDDM script exists
	if [ -f "$CONFIG_DIR/scripts/sddm_candy_install.sh" ]; then

		# Run the SDDM script
		$CONFIG_DIR/scripts/sddm_candy_install.sh
	else
		echo "Error:  Sugar-Candy script not found at $CONFIG_DIR/scripts/sddm_candy_install.sh"
		exit 1
	fi
else
	echo "SDDM configuration cancelled." | lsd-print
fi
sleep 2
clear

# Ask user for confirmation Monitors
sleep .5
echo " "
display_header "Monitors"
sleep .5
if gum confirm "  🖥️    Would you like to configure monitor setup? "; then
	echo "Starting monitor setup..." | lsd-print
	sleep 1

	# Check if monitor script exists
	if [ -f $CONFIG_DIR/scripts/monitor.sh ]; then
		# Run the monitor script
		$CONFIG_DIR/scripts/monitor.sh
	else
		echo "Error: Monitor script not found at $CONFIG_DIR/scripts/monitor.sh"
		exit 2
	fi
else
	echo "Monitor setup cancelled." | lsd-print
fi
sleep 2
clear

# Ask user for confirmation grub setup
echo ""
display_header "Grub"
sleep .5

if gum confirm "  🪱    Would you like to configure GRUB theme? "; then
	echo "Starting grub setup ..." | lsd-print
	sleep 1

	# Check if grub script exists
	if [ -f $CONFIG_DIR/scripts/grub.sh ]; then

		# Run the grub script
		$CONFIG_DIR/scripts/grub.sh
	else
		echo "Error: grub script not found at $CONFIG_DIR/scripts/grub.sh"
		exit 1
	fi
else
	echo "Grub setup cancelled." | lsd-print
fi
sleep 2
clear

# Ask user for confirmation cleanup
echo ""
sleep .5
display_header "Cleanup"
sleep .5

if gum confirm "  🧹    Would you like to perform a system cleanup? "; then
	echo ""
	echo "Starting system cleanup..." | lsd-print
	sleep 1

	# Check if cleanup script exists
	if [ -f $HOME/scripts/cleanup.sh ]; then

		# Run the cleanup script
		$HOME/scripts/cleanup.sh
	else
		echo "Error: Cleanup script not found at $HOME/scripts/cleanup.sh"
		exit 1
	fi
else
	echo "System cleanup cancelled." | lsd-print
fi
sleep 1.5
clear

# Ask user for Shell Config
sleep .5
echo ""
display_header "Shell"
sleep 1

if gum confirm "  🐚    Would you like configure the Shell? "; then
	echo "Starting Shell setup..." | lsd-print
	sleep 1

	# Check if shell script exists
	if [ -f $CONFIG_DIR/scripts/shell.sh ]; then

		# Run the shell script
		$CONFIG_DIR/scripts/shell.sh
	else
		echo "Error:  Shell script not found at $CONFIG_DIR/scripts/shell.sh"
		exit 1
	fi
else
	echo "Shell setup cancelled." | lsd-print
fi
sleep 1
clear
