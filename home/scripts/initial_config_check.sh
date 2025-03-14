#!/bin/bash

CONFIG_FILE="$HOME/config_check.sh"
CONFIG_SCRIPT="$HOME/.dotfiles/assets/set_script/config.sh"

# Ensure the config_check.sh file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "run" > "$CONFIG_FILE"
    STATUS="run"
else
    STATUS=$(cat "$CONFIG_FILE")
fi

# If status is "off", exit the script
if [[ "$STATUS" == "off" ]]; then
    exit 0
fi

# Open a terminal (Ghostty or default) and prompt the user
TERMINAL="ghostty"
if ! command -v $TERMINAL &>/dev/null; then
    TERMINAL="x-terminal-emulator" # Fallback to default terminal
fi

$TERMINAL -e bash -c '
    echo "It appears the desktop has not been fully optimized."
    read -p "Complete setup? (Y/N): " choice
    if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
        bash "'"$CONFIG_SCRIPT"'"
        echo "The configuration script has completed!! For BEST effects please REBOOT."
        read -p "Would you like to reboot now? (Y/N): " reboot_choice
        if [[ "$reboot_choice" == "Y" || "$reboot_choice" == "y" ]]; then
            echo "Thank you! Rebooting in:"
            for i in {10..1}; do
                echo -n "$i "
                sleep 1
            done
            echo
            systemctl reboot
        fi
    else
        echo "Press WIN + Q to close this window."
        read -p "If you would like to not show this upon startup again, enter 'x' + ENTER: " disable_choice
        if [[ "$disable_choice" == "x" || "$disable_choice" == "X" ]]; then
            echo "off" > "'"$CONFIG_FILE"'"
            echo "Startup check disabled."
        fi
    fi
    read -p "Press ENTER to exit..."
'
