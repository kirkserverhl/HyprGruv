./#!/bin/bash
clear

# Load theming (matugen colors + reliable headers)
source "$HOME/.config/hypr/scripts/colors.sh"
source "$HOME/.config/hypr/scripts/header.sh"
gum_apply_matugen_theme
export GUM_CONFIRM_PROMPT="? Would you like to change your default shell? "

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
