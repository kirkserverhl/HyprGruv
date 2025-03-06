#!/bin/bash
##  SETUP  ##
#################################################################
RESET="\e[0m"                # Reset  ##  Notes:
GREEN="\e[38;2;142;192;124m" # 8ec07c ##
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215
;153;33m"                # d79921 ##
RED="\e[38;2;204;36;29m" # cc241d ##
GRAY="\e[38;2;60;56;54m" # 3c3836 ##
BOLD="\e[1m"             # Bold   ##
clear                    #####################################

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

# Function to track actions and their completion state
track_action() {
  local action="$1"
  local status="$2" # "✔" for completed, "x" for not completed
  checklist+=("$action,$status")
}

# Initialize checklist
checklist=()

##### Section 1: Installing Packages #####
echo -e "\n  🫠   Welcome to Hyprland Gruvbox Installation !!   🚀
            Sit back and enjoy the ride !!   \n"
{
  echo -e "   📦️     Installing Essential Packages..."
  echo ""
  sudo pacman -S --noconfirm git || log_error "Failed to install git"
  git clone https://aur.archlinux.org/yay.git || log_success "Git installed successfully"
  cd yay && makepkg -si --noconfirm || log_success "YAY installed successfully"
  yay -Syu || log_error "Failed to update yay"
  yay -Syu stow figlet --noconfirm || log_error "Failed to install stow and figlet"
  yay -Syu lsd-print-git --noconfirm || log_error "Failed to install lsd-print-git"
  yay -Syu powerpill --noconfirm || log_error "Failed to install powerpill"

  PACKAGES1=(
    eza fastfetch ghostty gsettings-qt gum hyprgraphics hyprlang hyprpaper hyprpolkitagent hyprutil hyprwayland-scanner imagemagick neovim nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 python-pywalfox python-terminaltexteffects qt5-base qt5-declarative qt5-x11extras qt5ct-kde qt6-base qt6-declarative qt6ct-kde starship stow xorg-xinit waypaper wlogout yazi xsettingsd zsh --noconfirm
  )
  yay -S --noconfirm "${PACKAGES1[@]}"
}
# List of essential packages
# ESSENTIAL_PACKAGES=("eza" "fastfetch" "figlet" "ghostty" "gum" "hyprlang" "hyprpaper" "waypaper" "hyprpolkitagent" "hyprutils" "hyprwayland-scanner" "imagemagick" "lsd-print-git" "neovim" "nwg-dock-hyprland" "nwg-drawer" "nwg-look" "pacseek" "python-pywal16" "python-pywalfox" "python-terminaltexteffects" "qt5-base" "qt5-declarative" "qt5-x11extras" "qt5ct-kde" "qt6-base" "qt6-declarative" "qt6ct-kde" "starship" "stow" "xorg-xinit" "yazi" "xsettingsd" "wlogout" "zsh")
# Check for missing packages
# MISSING_PACKAGES=()
# for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
#   if ! pacman -Qq "$pkg" &>/dev/null; then
#     MISSING_PACKAGES+=("$pkg")
#   fi
# done
# Install missing packages
# if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
#   echo "Installing missing essential packages: ${MISSING_PACKAGES[*]}"
#   sudo pacman -Sy --noconfirm "${MISSING_PACKAGES[@]}"
# else
#   echo "All essential packages are already installed."
# fi
PACKAGES2=(
  archlinux-xdg-menu ark aylurs-gtk-shell bluez bluez-utils bpytop cliphist cmake dolphin duf expac fortune-mod fortune-mod-archlinux fzf go grimblast-git gsettings-qt gst-plugin-pipewire gtk-engine-murrine haskell-colourista hyprcursor hypridle hyprpicker hyprshade hyprutils kate konsole konsole-gruvbox kvantum less libpulse libva-intel-driver neovim-lspconfig network-manager-applet otf-font-awesome pacman-mirrorlist pavucontrol pipewire qt5-graphicaleffects ranger rofi-calc rofi-wayland smile syntax-highlighting tig tldr++ tmux tree-sitter waybar wireplumber wl-clipboard wl-clipboard-history-git wtf wtype xclip xdg-desktop-portal-gtk xdg-desktop-portal-hyprland xdg-desktop-portal-kde xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xf86-video-vmware xorg-server xorg-wayland xorg-xhost xorg-xinit xsettingsd zig zoxide gruvbox-plus-icon-theme kscreen kde-applications-meta-slim kde-material-you-colors gruvbox-plus-icon-theme)
yay S --noconfirm "${PACKAGES2[@]}"
clear

##### Section 2: Configuration  #####
{
  log_status "  🛠️   Applying base configurations..." | lsd-print
  cd ~/.hyprgruv/setup || {
    log_error "Failed to navigate to ~/scripts"
    exit 1
  }
  ./stow.sh
  ./config.sh || {
    log_error "Failed to run config.sh"
    exit 1
  }
}
clear

###########   Installation Summary  ###############
echo -e "\n Configuration Completed Successfully." | lsd-print

echo -e "\n       Hyprland Gruvbox Installation is Complete !! 🫠
        A list of common helpful keybinds is below:" | lsd-print

echo -e "  ⌨️  ▏ 󰖳 + ENTER             👻   Ghostty Terminal
  ⌨️  ▏ 󰖳 + B                     Firefox
  ⌨️  ▏ 󰖳 + F                     Krusader Browser
  ⌨️  ▏ 󰖳 + N                     NeoVim
  ⌨️  ▏ 󰖳 + Q                  󰅙   Close Window
  ⌨️  ▏ 󰖳 + SPACE              󰀻   Rofi App Launcher
  ⌨️  ▏ 󰖳 + CTRL + Q           󰗽   Logout 
  ⌨️  ▏ 󰖳 + Mouse Left        🪟   Move Window"

echo -e "\n   Display Full list of keybinds with:  ⌨️  ▏ 󰖳 + SPACE
   or left-click the gear icon    in the Waybar" | lsd-print
echo -e " Restart is required to complete setup !!" | lsd-print
echo -e "  1.   🥾    Reboot Now \n
  2.   🔙    Rerun Installation \n
  3.   🚀    Exit Installation \n"

read -p " Enter your choice: " choice
echo -e ""

##### Check the user's input  #####
case $choice in
1)
  echo " Rebooting now..." | lsd-print
  sudo reboot
  ;;
2)
  echo " Rerunning the script..." | lsd-print
  exec "$0" # Reruns the current script
  ;;
3)
  echo " Exiting. System will not reboot." | lsd-print
  exit 0
  ;;
*)
  echo " Invalid input. Exiting without reboot." | lsd-print
  exit 0
  ;;
esac
