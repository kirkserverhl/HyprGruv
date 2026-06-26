#!/bin/bash
#  ____
# |  _ \ _____      _____ _ __
# | |_) / _ \ \ /\ / / _ \ '__|
# |  __/ (_) \ V  V /  __/ |
# |_|   \___/ \_/\_/ \___|_|
#

FAREWELL="${HOME}/.config/hyprgruv/scripts/farewell-fish.sh"

if [[ "$1" == "exit" ]]; then
	echo ":: Exit"
	# Close wlogout before compositor teardown (avoids blur/render races on layer-shell).
	pkill -x wlogout 2>/dev/null || true
	sleep 0.3
	# Farewell prints on the session TTY after Hyprland exits (start-hyprland-lua wrapper).
	hyprctl dispatch exit
	exit 0
fi

if [[ "$1" == "lock" ]]; then
	echo ":: Lock"
	sleep 0.5
	hyprlock -c ~/.config/hypr/hyprlock/hyprlock.conf
fi

if [[ "$1" == "reboot" ]]; then
	echo ":: Reboot"
	if [[ -f "$FILE" ]]; then
		rm $FILE
	fi
	pkill -x wlogout 2>/dev/null || true
	[[ -x "$FAREWELL" ]] && "$FAREWELL" || true
	sleep 0.5
	systemctl reboot
fi

if [[ "$1" == "shutdown" ]]; then
	echo ":: Shutdown"
	if [[ -f "$FILE" ]]; then
		rm $FILE
	fi
	pkill -x wlogout 2>/dev/null || true
	[[ -x "$FAREWELL" ]] && "$FAREWELL" || true
	sleep 0.5
	systemctl poweroff
fi

if [[ "$1" == "suspend" ]]; then
	echo ":: Suspend"
	sleep 0.5
	systemctl suspend
fi

if [[ "$1" == "hibernate" ]]; then
	echo ":: Hibernate"
	sleep 1
	systemctl hibernate
fi
