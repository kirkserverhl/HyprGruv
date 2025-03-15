#!/bin/bash
# SHELL.sh

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
source "$HOME/.hypr/lib/common.sh"
source "$HOME/.hypr/lib/state.sh"

RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"

# display_cdheader "SHELL"
echo ""
echo "Please select your preferred shell" | lsd-print
sleep 1

shell=$(gum choose "zsh" "bash" "CANCEL")
sleep 1

# -----------------------------------------------------
# Activate bash
# -----------------------------------------------------
if [[ $shell == "bash" ]]; then

	# Change shell to bash
	while ! chsh -s $(which bash); do
		echo "ERROR - Authentication failed. Please enter the correct password."
		sleep 1
	done
	echo "Shell is now bash." | lsd-print

	gum spin --spinner dot --title "Please reboot your system." -- sleep 3
	_selectCategory

# -----------------------------------------------------
# Activate zsh
# -----------------------------------------------------
elif [[ $shell == "zsh" ]]; then

	# Change shell to shh
	while ! chsh -s $(which zsh); do
		echo "ERROR - Authentication failed. Please enter the correct password."
		sleep 1
	done
	echo "Shell is now zsh." | lsd-print

	# Installing zsh-autosuggestions
	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
		echo "Installing zsh-autosuggestions" | lsd-print
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	else
		echo "zsh-autosuggestions already installed" | lsd-print
	fi

	# Installing zsh-syntax-highlighting
	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
		echo "Installing zsh-syntax-highlighting" | lsd-print
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	else
		echo "zsh-syntax-highlighting already installed" | lsd-print
	fi

	# Installing fast-syntax-highlighting
	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
		_writeMessage "Installing fast-syntax-highlighting"
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
	else
		echo "fast-syntax-highlighting already installed" | lsd-print
	fi

	gum spin --spinner dot --title "Please reboot your system." -- sleep 3
# _selectCategory
else
	echo "Changing shell canceled" | lsd-print
	exit
fi
