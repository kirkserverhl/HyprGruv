#!/bin/bash

# Display header
figlet -f slant "Optional Software Installer"

# Initialize checklist
checklist=()

# Function to install Ghossty Terminal
ghossty_terminal() {
    figlet -f slant "Ghossty Terminal"
    echo "Installing Ghossty Terminal packages..."
    yay -S --noconfirm ghostty ghostty-shell-integration ghostty-terminfo
    checklist+=("Ghossty Terminal")
    echo "Ghossty Terminal installation completed."
}

# Function to install Surfshark VPN
surfshark_vpn() {
    figlet -f slant "Surfshark VPN"
    echo "Installing Surfshark VPN..."
    yay -S --noconfirm surfshark-client
    checklist+=("Surfshark VPN")
    echo "Surfshark VPN installation completed."
}

# Function to install qBittorrent Enhanced
qbittorrent() {
    figlet -f slant "qBittorrent Enhanced"
    echo "Installing qBittorrent Enhanced..."
    yay -S --noconfirm qbittorrent-enhanced
    checklist+=("qBittorrent Enhanced")
    echo "qBittorrent Enhanced installation completed."
}

# Function to install Disk Utility
disk_utility() {
    figlet -f slant "Disk Utility"
    echo "Installing Disk Utility..."
    yay -S --noconfirm gnome-disk-utility
    checklist+=("Disk Utility")
    echo "Disk Utility installation completed."
}

# Function to install Game Package
game_package() {
    figlet -f slant "Game Package"
    echo "Installing Game Package..."
    yay -S --noconfirm wolfenstein3d
    echo "# Uncomment the following line and add your Git repository when ready" >> ~/install_notes.txt
    echo "# git clone <your_git_repo_url> ~/games" >> ~/install_notes.txt
    checklist+=("Game Package")
    echo "Game Package installation completed."
}

# Main script logic
while true; do
    clear
    figlet -f slant "Optional Software"
    echo "Select an option to install or Exit:"
    echo "1) Ghossty Terminal"
    echo "2) Surfshark VPN"
    echo "3) qBittorrent Enhanced"
    echo "4) Disk Utility"
    echo "5) Game Package"
    echo "6) Exit"
    read -rp "Enter your choice [1-6]: " choice

    case $choice in
        1)
            ghossty_terminal
            ;;
        2)
            surfshark_vpn
            ;;
        3)
            qbittorrent
            ;;
        4)
            disk_utility
            ;;
        5)
            game_package
            ;;
        6)
            break
            ;;
        *)
            echo "Invalid choice, please try again."
            ;;
    esac
    echo "Press Enter to continue..."
    read
done

# Display checklist
figlet -f slant "Summary"
echo "Installed Software Checklist:"
for item in "${checklist[@]}"; do
    echo "- $item"
done

# Clean exit
figlet -f slant "Goodbye!"

