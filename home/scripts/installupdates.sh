#!/bin/bash
#  .___                 __         .__  .__
#  |   | ____   _______/  |______  |  | |  |
#  |   |/    \ /  ___/\   __\__  \ |  | |  |
#  |   |   |  \\___ \  |  |  / __ \|  |_|  |__
#  |___|___|  /____  > |__| (____  /____/____/
#           \/     \/            \/
#  ____ ___            .___       __
# |    |   \______   __| _/____ _/  |_  ____   ______
# |    |   /\____ \ / __ |\__  \\   __\/ __ \ /  ___/
# |    |  / |  |_> > /_/ | / __ \|  | \  ___/ \___ \
# |______/  |   __/\____ |(____  /__|  \___  >____  >
#          |__|        \/     \/          \/     \/
#
sleep 1
clear
install_platform="$(cat ~/scripts/platform.sh)"
figlet -f smslant "Updates"
echo

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

# ------------------------------------------------------
# Confirm Start
# ------------------------------------------------------
if gum confirm "DO YOU WANT TO START THE UPDATE NOW?"; then
	echo
	echo ":: Update started." | lsd-print
elif [ $? -eq 130 ]; then
	exit 130
else
	echo
	echo ":: Update canceled."  | lsd-print
	exit
fi

# Check if platform is supported
case $install_platform in
arch)
	aur_helper="$(cat ~/scripts/aur.sh)"

	_isInstalledAUR() {
		package="$1"
		check="$($aur_helper -Qs --color always "${package}" | grep "local" | grep "${package} ")"
		if [ -n "${check}" ]; then
			echo 0 #'0' means 'true' in Bash
			return #true
		fi
		echo 1 #'1' means 'false' in Bash
		return #false
	}

	if [[ $(_isInstalledAUR "timeshift") == "0" ]]; then
		echo
		if gum confirm "DO YOU WANT TO CREATE A SNAPSHOT?"; then
			echo
			c=$(gum input --placeholder "Enter a comment for the snapshot...")
			sudo timeshift --create --comments "$c"
			sudo timeshift --list
			sudo grub-mkconfig -o /boot/grub/grub.cfg
			echo ":: DONE. Snapshot $c created!"
			echo
		elif [ $? -eq 130 ]; then
			echo ":: Snapshot skipped." | lsd-print
			exit 130
		else
			echo ":: Snapshot skipped." | lsd-print
		fi
		echo
	fi

	$aur_helper

	if [[ $(_isInstalledAUR "flatpak") == "0" ]]; then
		flatpak upgrade
	fi
	;;
fedora)
	sudo dnf upgrade
	;;
*)
	echo ":: ERROR - Platform not supported"  | lsd-print
	echo "Press [ENTER] to close."
	read
	;;
esac

notify-send "Update complete"  | lsd-print
echo
echo ":: Update complete"  | lsd-print
echo
echo
echo "Press [ENTER] to close."  | lsd-print
read
