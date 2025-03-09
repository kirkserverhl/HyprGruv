#!/bin/bash
source ~/.hyprgruv/lib/common.sh

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

# Display header with figlet
#display_header() {
#	figlet -f "$HOME/.hyprgruv/home/.fonts/Graffiti.flf" "$1" | lsd-print
#	echo ""
#}

# Ask user for confirmation SDDM
display_header "SDDM"

if gum confirm "  🍬     Would you like to install Sugar-Candy SDDM theme?  "; then
	echo "Configuring Shell..." | lsd-print

	# Check if SDDM script exists
	if [ -f ~/.hyprgruv/assets/scripts/sddm_candy_install.sh ]; then
		# Make sure the script is executable
		chmod +x ~/.hyprgruv/assets/scripts/sddm_candy_install.sh

		# Run the SDDM script
		~/.hyprgruv/assets/scripts/sddm_candy_install.sh
	else
		echo "Error:  Sugar-Candy script not found at ~/.hyprgruv/assets/scripts/sddm_candy_install.sh"
		exit 1
	fi
else
	echo "SDDM configuration cancelled." | lsd-print
fi
sleep 1

# Ask user for confirmation Monitors
display_header "Monitors"

if gum confirm "  🖥️    Would you like to configure monitor setup? "; then
	echo "Starting monitor setup..." | lsd-print

	# Check if monitor script exists
	if [ -f ~/.hyprgruv/assets/scripts/monitor.sh ]; then
		# Make sure the script is executable
		chmod +x ~/.hyprgruv/assets/scripts/monitor.sh

		# Run the monitor script
		~/.hyprgruv/assets/scripts/monitor.sh
	else
		echo "Error: Monitor script not found at ~/.hyprgruv/assets/scripts/monitor.sh"
		exit 1
	fi
else
	echo "Monitor setup cancelled." | lsd-print
fi
clear

# Ask user for confirmation grub setup
display_header "Grub"

if gum confirm "  🪱    Would you like to configure GRUB theme? "; then
	echo "Starting grub setup ..." | lsd-print

	# Check if grub script exists
	if [ -f ~/.hyprgruv/assets/scripts/sddm_candy_install.sh ]; then
		# Make sure the grub is executable
		chmod +x ~/.hyprgruv/assets/scripts/sddm_candy_install.sh

		# Run the grub script
		~/.hyprgruv/assets/scripts/grub.sh
	else
		echo "Error: grub script not found at ~/.hyprgruv/assets/scripts/grub.sh"
		exit 1
	fi
else
	echo "Grub setup cancelled." | lsd-print
fi
clear

# Ask user for confirmation cleanup
display_header "Shell"

if gum confirm "  🐚    Would you like configure the Shell? "; then
	echo "Starting Shell setup..." | lsd-print

	# Check if shell script exists
	if [ -f ~/scripts/shell.sh ]; then
		# Make sure the script is executable
		chmod +x ~/scripts/shell.sh

		# Run the shell script
		~/scripts/shell.sh
	else
		echo "Error:  Shell script not found at ~/scripts/shell.sh"
		exit 1
	fi
else
	echo "Shell setup cancelled." | lsd-print
fi
clear

# Ask user for confirmation cleanup
display_header "Cleanup"

if gum confirm "  🧹    Would you like to perform a system cleanup? "; then
	echo "Starting system cleanup..." | lsd-print

	# Check if cleanup script exists
	if [ -f ~/scripts/cleanup.sh ]; then
		# Make sure the script is executable
		chmod +x ~/scripts/cleanup.sh

		# Run the cleanup script
		~/scripts/cleanup.sh
	else
		echo "Error: Cleanup script not found at ~/scripts/cleanup.sh"
		exit 1
	fi
else
	echo "System cleanup cancelled." | lsd-print
fi
clear
