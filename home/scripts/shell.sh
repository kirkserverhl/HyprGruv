./#!/bin/bash
clear

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

#display_header() {
#	# clear
#	figlet -f ~/.fonts/Graffiti.flf "$1"
#}

display_header "Shell Setup" | lsd-print
sleep 1
_isInstalledYay() {
	package="$1"
	check="$(yay -Qs --color always "${package}" | grep "local" | grep "\." | grep "${package} ")"
	if [ -n "${check}" ]; then
		echo 0 #'0' means 'true' in Bash
		return #true
	fi
	echo 1 #'1' means 'false' in Bash
	return #false
}
echo ":: Please select your preferred shell" | lsd-print
echo ""
echo ":: For best install and setup use Zsh !!" | lsd-print

shell=$(gum choose "zsh" "bash" "Cancel")

# -----------------------------------------------------
# Activate bash
# -----------------------------------------------------

if [[ $shell == "bash" ]]; then

	# Change shell to bash
	while ! chsh -s $(which bash); do
		echo "ERROR: Authentication failed. Please enter the correct password."
		sleep 1
	done
	echo ":: Shell is now bash." | lsd-print

	gum spin --spinner dot --title "Please reboot your system." -- sleep 3

# -----------------------------------------------------
# Activate zsh
# -----------------------------------------------------

elif [[ $shell == "zsh" ]]; then

	# Change shell to zsh
	while ! chsh -s $(which zsh); do
		echo "ERROR: Authentication failed. Please enter the correct password."
		sleep 1
	done
	echo ":: Shell is now zsh." | lsd-print

	# Installing fast-syntax-highlighting

	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
		echo ":: Installing fast-syntax-highlighting"
		git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
	else
		echo ":: fast-syntax-highlighting already installed" | lsd-print
	fi

	gum spin --spinner dot --title "Please reboot your system." -- sleep 3

# -----------------------------------------------------
# Cancel
# -----------------------------------------------------

else
	echo ":: Changing shell canceled" | lsd-print
	exit
fi
