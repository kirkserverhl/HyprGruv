#!/bin/bash

# Ask user for confirmation SDDM
display_header "SDDM"

if gum confirm "  🍬     Would you like to install Sugar-Candy SDDM theme?  "; then
	echo "Configuring Shell..." | lsd-print

	# Check if SDDM script exists
	if [ -f $CONFIG_DIR/sddm_candy_install.sh ]; then
		# Make sure the script is executable
		chmod +x $CONFIG_DIR/sddm_candy_install.sh

		# Run the SDDM script
		$CONFIG_DIR/sddm_candy_install.sh
	else
		echo "Error:  Sugar-Candy script not found at $CONFIG_DIR/sddm_candy_install.sh"
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
	if [ -f $CONFIG_DIR/monitor.sh ]; then
		# Make sure the script is executable
		chmod +x $CONFIG_DIR/monitor.sh
		# Run the monitor script
		$CONFIG_DIR/monitor.sh
	else
		echo "Error: Monitor script not found at $CONFIG_DIR/monitor.sh"
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
	if [ -f $CONFIG_DIR/grub.sh ]; then
		# Make sure the grub is executable
		chmod +x $CONFIG_DIR/grub.sh

		# Run the grub script
		$CONFIG_DIR/grub.sh
	else
		echo "Error: grub script not found at $CONFIG_DIR/grub.sh"
		exit 1
	fi
else
	echo "Grub setup cancelled." | lsd-print
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

# Ask user for Shell Config
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
