#!/bin/bash
##$  SETUP  ###
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

cp -r ~/.hyprgruv/assets/wal/ ~/.cache/wal/
cp -r ~/.hyprgruv/assets/kitty.conf ~/.config/kitty/kitty.conf


##### Section 1: Installing Packages #####
echo -e "\n  🫠   Welcome to Hyprland Gruvbox Installation !!   🚀
            Sit back and enjoy the ride !!   \n"
{
  echo -e "   📦️     Installing Essential Packages..."
  echo ""

  sudo pacman -S --noconfirm git || log_error "Failed to install git"
  git clone https://aur.archlinux.org/yay.git || log_success "Git installed successfully"
  cd yay && makepkg -si --noconfirm || log_success "YAY installed successfully"
  yay -Syu
  yay -S stow figlet powerpill --noconfirm || log_error "Failed to install stow, figlet, powerpill"
  yay -S lsd-print-git --noconfirm || log_error "Failed to insall lsd-print-git"

  PACKAGES1=(
    bluez bluez-utils btop cmake duf eza fastfetch fzf ghostty grimblast-git gsettings-qt gum hyprgraphics
    hypridle hyprland-qt-support hyprpaper hyprpicker hyprshade iwgtk neovim neovim-lspconfig network-manager-applet
    nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 qt5-declarative rofi-wayland smile udiskie waybar
    waypaper wireplumber wl-clipboard wlogout xclip xorg-wayland xsettingsd yazi zig
  )
  yay -S --noconfirm "${PACKAGES1[@]}"
  clear

  PACKAGES2=(
    archlinux-xdg-menu clipse fortune-mod-archlinux grimblast-git gtk-engine-murrine kate konsole kscreen
    kvantum less pacman-mirrorlist pavucontrol python-pywalfox qt5-graphicaleffects qt6ct-kde ranger rofi-calc
    tig tmux tree-sitter wl-clipboard xdg-desktop-portal-kde xorg-wayland xsettingsd zoxide
  )
  yay S --noconfirm "${PACKAGES2[@]}"
  clear

  # List of essential packages
  ESSENTIAL_PACKAGES=("eza" "figlet" "lsd-print-git" "gum" "hyprpaper" "waypaper" "nwg-dock-hyprland"
    "nwg-drawer" "nwg-look" "pacseek" "python-pywal16" "python-pywalfox" "qt5-declarative" "qt6ct-kde"
    "starship" "stow" "yazi" "xsettingsd" "wlogout" "zsh")

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
}
clear

#### Section 2: Configuration  #####
{
  log_status "  🛠️   Applying base configurations..."
  cd ~/.hyprgruv/setup
  ./stow.sh
  ./assets.sh
}
