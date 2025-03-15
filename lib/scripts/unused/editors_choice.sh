#!/bin/bash
clear
###############################################################################################
### Gruvbox colors ############################################################################
RESET="\e[0m"                 	 # Reset ##
GREEN="\e[38;2;142;192;124m"  	 #8ec07c ##
CYAN="\e[38;2;69;133;136m"    	 #458588 ##
YELLOW="\e[38;2;215;153;33m"  	 #d79921 ##
RED="\e[38;2;204;36;29m"      	 #cc241d ##
GRAY="\e[38;2;60;56;54m"      	 #3c3836 ##
BOLD="\e[1m"                  	 # Bold  ##

##############################################################################################
# Function to display headers with figlet ####################################################
##############################################################################################

display_header() {
    # clear
    figlet -f ~/.fonts/Graffiti.flf "$1"
}
##############################################################################################
# Initialize Editors Choice Script  ##########################################################
##############################################################################################
echo -e "\n     Running Editors Choice Installer..." | lsd-print

# Function to keep sudo active
keep_sudo_alive() {
    while true; do
        sudo -v
        sleep 50
    done
}

# Start sudo in the background
if ! sudo -v; then
    echo  " 󰟵 Sudo credentials required to continue." | lsd-print
    exit 1
fi

keep_sudo_alive &
sudo_pid=$!

# Function to clean up the background sudo process
cleanup_sudo() {
    kill "$sudo_pid"
}
trap cleanup_sudo EXIT

# Initialize checklist
checklist=()

# Function to install Surfshark VPN
echo ""
display_header "Surfshark" | lsd-print
read -p "  🦈   Do you want to install Surfshark VPN (y/n) ? " install_surfshark
echo ""
if [[ "$install_surfshark" =~ ^[Yy]$ ]]; then
    echo -e"  🛠️   Installing Surfshark VPN...\n"
    yay -S --noconfirm surfshark-client
    checklist+=("Surfshark VPN")
    echo "  ✔️   Surfshark VPN installation completed." | lsd-print
fi
clear

# Function to install qBittorrent Enhanced
display_header "qBittorrent" | lsd-print
echo ""
read -p "  👿     Do you want to install qBittorrent (y/n) ? " install_qbittorent
echo ""
if [[ "$install_qbittorent" =~ ^[Yy]$ ]]; then
    echo -e "  🛠️   Installing qBittorrent Enhanced...\n"
    yay -S --noconfirm qbittorrent-enhanced
    checklist+=("qBittorrent Enhanced")
    echo "  ✔️   qBittorrent Enhanced installation completed." | lsd-print
fi
clear

# Function to install Disk Utility
display_header "Disk  Utility" | lsd-print
echo ""
read -p "  💽   Do you want to install Disk Utility (y/n) ? " install_disk
echo ""
if [[ "$install_disk" =~ ^[Yy]$ ]]; then
    echo -e "     Installing Disk Utility...\n"
    yay -S --noconfirm gnome-disk-utility
    checklist+=("Disk Utility")
    echo "  ✔️   Disk Utility installation completed." | lsd-print
fi
clear

# Function to install Game Package
display_header "Games" | lsd-print
echo ""
read -p "  🕹️   Do you want to install Game Package (y/n) ? " install_game
echo ""
if [[ "$install_game" =~ ^[Yy]$ ]]; then
    echo -e "  🛠️   Installing Game Package...\n"
    yay -S --noconfirm wolfenstein3d
    checklist+=("Game Package")
    echo "  ✔️   Game Package installation completed." | lsd-print
fi
clear

# Display checklist summary with tte beams
print_checklist_tte() {
    checklist_file="/tmp/package_checklist.txt"
    echo -e "\\n Configuration Summary:\\n" > "$checklist_file"

    if [[ ${#checklist[@]} -eq 0 ]]; then
        echo "  ⛔️   No Packages Installed" >> "$checklist_file"
    else
        # Add each installed section with its respective icon
        for section in "${checklist[@]}"; do
            case $section in
                "Surfshark VPN") echo "  🦈  Surfshark VPN" >> "$checklist_file" ;;
                "qBittorrent Enhanced") echo "  👿  qBittorrent" >> "$checklist_file" ;;
                "Disk Utility") echo "  💽  Disk Utility" >> "$checklist_file" ;;
                "Game Package") echo "  🕹️  Game Package" >> "$checklist_file" ;;
            esac
        done
    fi

    if command -v tte &>/dev/null; then
        cat "$checklist_file" | tte beams
    else
        cat "$checklist_file"
    fi
    rm "$checklist_file"
}

clear
print_checklist_tte

###############################################################################################
# Options for reboot, rerun, or exit ##########################################################
###############################################################################################

echo -e "  ✔️   Installation is complete.\n"
echo -e " Choose an option:"                | lsd-print
echo -e " 1.  🔙  Rerun this script \n"
echo -e " 2.  🚀   Exit \n"

read -p "Enter your choice: " choice
echo -e ""
# Check the user's input or proceed to the default action
case $choice in
    1)
        echo -e"  🔙  Rerunning the script..." | lsd-print
        exec "$0"  # Reruns the current script
        ;;
    2)
        echo -e "  🚀    Exiting Configuration.\n"
        echo -e " To close this terminal use:  󰌓  ▏ 󰖳 + Q" | lsd-print
        exit 0
        ;;
    *)
        echo -e "  ⛔️   No input detected.\n"
        echo -e "Close terminal windows with keybind:  󰌓  ▏ 󰖳 + Q" | lsd-print
        ;;
esac
