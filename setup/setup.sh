#!/bin/bash
##  SETUP  ##
#################################################################
RESET="\e[0m"                	# Reset  ##  Notes:
GREEN="\e[38;2;142;192;124m" 	# 8ec07c ##
CYAN="\e[38;2;69;133;136m"   	# 458588 ##
YELLOW="\e[38;2;215
;153;33m" 	# d79921 ##
RED="\e[38;2;204;36;29m"     	# cc241d ##
GRAY="\e[38;2;60;56;54m"     	# 3c3836 ##
BOLD="\e[1m"                 	# Bold   ##
clear #####################################

declare -A checklist
checklist=(
    [packages]=false
    [config]=false
    [post]=false
)a

# Function to print status messages
log_status() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}
# Function to print success messages
log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $1"
}
# Function to print warning messages
log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}
# Function to print error messages
log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}


# Function to print the checklist

    print_checklist_tte() {
        checklist_file="/tmp/checklist.txt"
        echo -e "\\n  📜   Installation Summary:\\n" > "$checklist_file"
        for section in "${!checklist[@]}"; do
            if [ "${checklist[$section]}" = true ]; then
                echo " ✔️ $section" >> "$checklist_file"
            else
                echo " ✖️ $section" >> "$checklist_file"
            fi
        
    # done


# Display the checklist using tte beams
{
    if  command -v tte &>/dev/null; then
        cat "$checklist_file" | tte beams
    else
        cat "$checklist_file"
        fi
    	# Clean up temporary file
    rm "$checklist_file"
}


##### Section 1: Installing Packages #####
# yay -Syu stow lsd-print-git figlet  --noconfirm
# cp -f ~/.dotfiles/assets/hyrland.conf /.config/hypr
# clear

echo -e "\n  🫠   Welcome to Hyprland Gruvbox Installation !!   🚀
            Sit back and enjoy the ride !!   \n"  #| lsd-print
{
    echo -e "   📦️     Installing Essential Packages..." #| lsd-print
        sudo pacman -S --noconfirm git || log_error "Failed to install git"
        git  clone https://aur.archlinux.org/yay.git || log_success "Git installed successfully"
        cd yay &&  makepkg -si --noconfirm ||   log_success "YAY installed successfully"
        yay -Syu || log_error "Failed to update yay"
	yay -Syu stow figlet  --noconfirm || log_error "Failed to install stow and figlet"
	yay -Syu lsd-print-git --noconfirm || log_error "Failed to install lsd-print-git"
	PACKAGES1=(
            eza fastfetch figlet ghostty gsettings-qt gum hyprgraphics hyprlang hyprpaper hyprpolkitagent hyprutil hyprwayland-scanner imagemagick lsd-print-git neovim nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 python-pywalfox python-terminaltexteffects qt5-base qt5-declarative qt5-x11extras qt5ct-kde qt6-base qt6-declarative qt6ct-kde starship stow xorg-xinit wlogout yazi xsettingsd zsh --noconfirm
            )
     yay -S --noconfirm "${PACKAGES1[@]}"
     checklist[packages]=true
} || checklist[packages]=false
clear

# List of essential packages
ESSENTIAL_PACKAGES=("eza" "fastfetch" "figlet" "ghostty" "gum" "hyprlang" "hyprpaper" "waypaper" "hyprpolkitagent" "hyprutils" "hyprwayland-scanner" "imagemagick" "lsd-print-git" "neovim" "nwg-dock-hyprland" "nwg-drawer" "nwg-look" "pacseek" "python-pywal16" "python-pywalfox" "python-terminaltexteffects" "qt5-base" "qt5-declarative" "qt5-x11extras" "qt5ct-kde" "qt6-base" "qt6-declarative" "qt6ct-kde" "starship" "stow" "xorg-xinit" "yazi" "xsettingsd" "wlogout" "zsh")

# Check for missing packages
MISSING_PACKAGES=()

for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
    if ! pacman -Qq "$pkg" &>/dev/null; then
        MISSING_PACKAGES+=("$pkg")
    fi
done

# Install missing packages
if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "Installing missing essential packages: ${MISSING_PACKAGES[*]}"
    sudo pacman -Sy --noconfirm "${MISSING_PACKAGES[@]}"
else
    echo "All essential packages are already installed."
fi

# Proceed with the installation script
echo "Continuing with the installation process..."


##### Section 2: Shell-Configuration  #####
{
	log_status "󰯂  Running post-configuration scripts..."
        cd ~/.hyprgruv/setup || { log_error "Failed to navigate to ~/scripts"; exit 1; }
        ./shell.sh || { log_error "Failed to run shell.sh"; exit 1; }
     checklist[shell]=true
} || checklist[shell]=false
clear

# Display a final message:
echo "🎉 All theming packages have been installed!"
echo "Your system is now ready for the next phase."
echo "Press Enter when you're ready to proceed..."
read -r  # Wait for user to press Enter

# Notify the user about the delay
echo "Opening the next installation script in 10 seconds..."

# Wait for 10 seconds before launching the next script
sleep 10

# Launch the next script in a new terminal window.
# Switch for ghostty
kitty -hold -e "/.hyprgruv/setup/install.sh" &

# Optionally exit this script
exit 0
