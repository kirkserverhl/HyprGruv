/#!/bin/bash
##  |__| ____   _______/  |______  |  | |  |        _____|  |__
##  |  |/    \ /  ___/\   __\__  \ |  | |  |       /  ___/  |  \
##  |  |   |  \\___ \  |  |  / __ \|  |_|  |__     \___ \|   Y  \
##  |__|___|  /____  > |__| (____  /____/____/ /\ /____  >___|  /
##          \/     \/            \/            \/      \/     \/
#################################################################
RESET="\e[0m"                # Reset  ##  Notes:
GREEN="\e[38;2;142;192;124m" # 8ec07c ##
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"                 # Bold   ##
clear ##################################

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
    bluez bluez-utils btop cmake duf eza fastfetch fzf ghostty grimblast-git gsettings-qt gum hyprgraphics hypridle hyprland-qt-support hyprpaper hyprpicker hyprshade iwgtk neovim neovim-lspconfig network-manager-applet nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 qt5-declarative rofi-wayland smile udiskie waybar waypaper wireplumber wl-clipboard wlogout xclip xorg-wayland xsettingsd yazi zig archlinux-xdg-menu clipse fortune-mod-archlinux grimblast-git gtk-engine-murrine kate konsole kscreen kvantum less pacman-mirrorlist pavucontrol python-pywalfox qt5-graphicaleffects qt6ct-kde ranger rofi-calc tig tmux tree-sitter wl-clipboard xdg-desktop-portal-kde xorg-wayland xsettingsd zoxide
  )
  yay -S --noconfirm "${PACKAGES1[@]}"
  clear


  # List of essential packages
  ESSENTIAL_PACKAGES=(
    "eza" "figlet" "lsd-print-git" "gum" "hyprpaper" "waypaper" "nwg-dock-hyprland" "nwg-drawer" "nwg-look" "pacseek"
    "python-pywal16" "python-pywalfox" "qt5-declarative" "qt6ct-kde" "starship" "stow" "yazi" "xsettingsd" "wlogout" "zsh"
    )

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
}

########################   STOW.sh ###################################################################

#!/bin/bash
{
  REPO_DIR="$HOME/.hyprgruv"
  USER_HOME="$HOME"

  # Create a timestamped backup directory
  TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
  BACKUP_DIR="$HOME/.local/backup/hyprgruv_$TIMESTAMP"

  # Create backup directory
  mkdir -p "$BACKUP_DIR"

  # Clone repository if it doesn't exist
  if [ ! -d "$REPO_DIR" ]; then
     git clone https://github.com/kirkserverhl/hyorgruv "$REPO_DIR"
  fi

  cd "$REPO_DIR" || exit

  # Backup existing files
  for file in $(ls -A "$REPO_DIR/home"); do
    if [ -e "$USER_HOME/$file" ]; then
      # Create subdirectories in backup folder to maintain structure
      PARENT_DIR=$(dirname "$BACKUP_DIR/${file}")
      mkdir -p "$PARENT_DIR"

      # Copy the file to backup directory (preserving structure)
      cp -r "$USER_HOME/$file" "$BACKUP_DIR/${file}"

      # Now remove the original file (stow will fail if file exists)
      # rm -rf "$USER_HOME/$file"
    fi
  done

  # Stow home directory configs
  stow -t "$USER_HOME" home --adopt

  echo "Installation complete. Backup saved to: $BACKUP_DIR"
}
    cd ~/.hyprgruv/setup
    ./assets.sh

########################  ./assets.sh  ###############################
#!/bin/bash

#!/bin/bash

sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
# sudo nvim pacman.conf
sudo cp ~/.dotfiles/assets/pacman.conf /etc/pacman.conf
yay -Syyu lightly-qt python-haishoku
yay -Syu ungoogled-chromium powerpill -Su && paru -Su
yay -Syu plasma-desktop kvantum-qt6-git kvantum-qt4-git nx-plaxma-look-and-feel-git
sudo git clone https://github.com/nx-desktop/nx-plasma-look-and-feel.git /usr/share/plasma/look-and-feel/
sudo cp -r -f ~/.dotfiles/assets/sddm /usr/share/sddm/themes/
sudo cp -r -f ~/.dotfiles/assets/color-schemes /usr/share/color-schemes/
sudo cp -r -f ~/.dotfiles/assets/konsole /usr/share/konsole/


    cp -rf ~/.hyprgruv/assets/mozilla/ ~/.mozilla
sleep 1s

cd ~/scripts && ./launch.sh
sleep 1s

touch ~/.config/hypr/conf/hyprland.conf
touch ~/.cache/wal/colors-hyprland.conf

###  Package Customization  ##
cd ~/.hyprgruv/setup &&
  ./config.sh


###############################   config.sh #########################################



RESET="\e[0m"                	# Reset  ##  Notes:
GREEN="\e[38;2;142;192;124m" 	# 8ec07c ##
CYAN="\e[38;2;69;133;136m"   	# 458588 ##
YELLOW="\e[38;2;215;153;33m" 	# d79921 ##
RED="\e[38;2;204;36;29m"     	# cc241d ##
GRAY="\e[38;2;60;56;54m"     	# 3c3836 ##
BOLD="\e[1m"                 	:# Bold   ##
clear #####################################

display_header() {
    # clear
    figlet -f ~/.local/share/fonts/Graffiti.flf "$1"
}

######  Initialize checklist array  ########

declare -A checklist
mark_completed() {
    checklist["$1"]="[✔️]"
}
mark_skipped() {
    checklist["$1"]="[✖️ ]"
}

######## SDDM Configuration  #######################

display_header "SDDM" | lsd-print
echo ""
read -p "   🍬     Would you like to install Sugar-Candy SDDM theme  (y/n)  ? " configure_sddm
if [[ "$configure_sddm" =~ ^[Yy]$ ]]; then
    if ~/scripts/sddm_candy_install.sh; then
        track_action "SDDM setup"
        mark_completed "SDDM Configuration"
    else
        mark_skipped "SDDM Configuration"
    fi
else
    mark_skipped "SDDM Configuration"
fi
clear

######## Monitor Setup #########################

display_header "Monitors" | lsd-print
echo ""
read -p "   🖥️    Would you like to configure monitor setup  (y/n)  ? " configure_monitor
echo ""
if [[ "$configure_monitor" =~ ^[Yy]$ ]]; then
    if ~/scripts/monitor.sh; then
        track_action "Monitor setup"
        mark_completed "Monitor Setup"
    else
        mark_skipped "Monitor Setup"
    fi
else
    mark_skipped "Monitor Setup"
fi
clear

#######  GRUB Theme and Extra Packages ##########

display_header "GRUB" | lsd-print
echo ""
read -p "  🪱    Would you like to configure GRUB theme & extra packages (y/n)? " configure_grub
echo ""

if [[ "$configure_grub" =~ ^[Yy]$ ]]; then
    if sudo -v; then  # Checks if the user has sudo privileges
        sudo ~/scripts/sddm_theme.sh  # Run the script with sudo
        track_action "Grub Theme"
        mark_completed "Grub Theme"
    else
        echo "You need sudo privileges to configure the GRUB theme."
        mark_skipped "Grub Theme"
    fi
else
    mark_skipped "Grub Theme"
fi
clear

######  Editors Choice #######################

display_header "Editors Choice" | lsd-print
echo ""
read -p "  🫠    Would you like to install Editors Choice packages  (y/n) ? " editors_choice
echo ""
if [[ "$editors_choice" =~ ^[Yy]$ ]]; then
    if  ~/scripts/editors_choice.sh; then
        track_action "Editors Choice Packages"
        mark_completed "Editors Choice Packages"
    else
        mark_skipped "Editors Choice Packages"
    fi
else
    mark_skipped "Editors Choice Packages"
fi
clear

#####  Neovim Configuration #################

display_header "Neovim  Setup" | lsd-print
echo ""
echo "     Would you like to configure Neovim (y/n) ? "
echo ""
echo "  ( To Close Neovim use:  󰖳 + Q )   " | lsd-print
read -p "   " configure_nvim
if [[ "$configure_nvim" =~ ^[Yy]$ ]]; then
    if ~/scripts/nvim.sh; then
    	track_action "Neovim Configuration"
      mark_completed "Neovim Configuration"
    else
        mark_skipped "Neovim Configuration"
    fi
else
    mark_skipped "Neovim Configuration"
fi
clear

#########  Terminal Effects  ################

display_header "Terminal Effects" | lsd-print
echo ""
read -p "   🌈    Would you like to Beautify your Terminal  (y/n) ?   " terminal_effects
if [[ "$terminal_effects" =~ ^[Yy]$ ]]; then
    if ~/.dotfiles/assets/set_script/additional_pkgs.sh; then
    	track_action "Terminal Effects"
      mark_completed "Terminal Effects"
    else
        mark_skipped "Terminal Effects"
    fi
else
    mark_skipped "Terminal Effects"
fi
clear

#########  Python Packages  ################

display_header "Python Packages" | lsd-print
echo ""
read -p "::  🐍    Would you like to install Python Packages  (y/n) ?   " python_pkgs
if [[ "$python_pkgs" =~ ^[Yy]$ ]]; then
    if ~/scripts/python_pkgs.sh; then
    	track_action "Python Packages"
      mark_completed "Python Packages"
    else
        mark_skipped "Python Packages"
    fi
else
    mark_skipped "Python Packages"
fi
clear

###########  Cleanup  ####################

display_header "Cleanup" | lsd-print
echo ""
read -p ":: 🧹    Would you like to perform a system cleanup  (y/n) ? " perform_cleanup
if [[ "$perform_cleanup" =~ ^[Yy]$ ]]; then
    if ~/scripts/cleanup.sh; then
        track_action "System cleanup"
        mark_completed "Cleanup"
    else
        mark_skipped "Cleanup"
    fi
else
    mark_skipped "Cleanup"
fi
clear

###########   Display Checklist Summary  ###############

echo -e "\n  📜    Configuration Summary:"   | lsd-print
for section in "${!checklist[@]}"; do
    echo -e "${checklist[$section]} $section"
done
echo -e "\n Configuration Completed Successfully." | lsd-print

########## Options for reboot, rerun, or ###############

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
        echo -e "  🚀   Exiting..." | lsd-print
        echo "off" > ~/config_check.sh
        exit 0
        ;;
    *)
        echo -e "❌ Invalid choice. Exiting by default." | lsd-print
        # echo "off" > ~/config_check.sh  # Ensure the file is set to "off" on invalid input as well
        exit 1
        ;;
esac
