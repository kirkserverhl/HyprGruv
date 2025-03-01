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
    [shell]=false
)

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
            eza fastfetch ghostty gsettings-qt gum hyprgraphics hyprlang hyprpaper hyprpolkitagent hyprutil hyprwayland-scanner imagemagick neovim nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 python-pywalfox python-terminaltexteffects qt5-base qt5-declarative qt5-x11extras qt5ct-kde qt6-base qt6-declarative qt6ct-kde starship stow xorg-xinit wlogout yazi xsettingsd zsh --noconfirm
            )
     yay -S --noconfirm "${PACKAGES1[@]}"

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
     
     checklist[packages]=true
} || checklist[packages]=false
clear

 PACKAGES1=(
           amd-ucode archlinux-xdg-menu ark aylurs-gtk-shell base-devel bluez bluez-utils bpytop btrfs-progs cliphist cmake cmatrix dolphin duf editorconfig-checker  efibootmgr expac fortune-mod fortune-mod-archlinux fzf gimp go gparted grimblast-git grub-theme-vimix gruvbox-plus-icon-theme gsettings-qt gst-plugin-pipewire gtk-engine-murrine haskell-colourista  hyprcursor hypridle hyprpicker hyprshade hyprutils kate konsole konsole-gruvbox kvantum less libpulse libva-intel-driver lsd neovim-lspconfig network-manager-applet obs-studio otf-font-awesome pacman-mirrorlist pavucontrol pipewire qt5-graphicaleffects ranger rofi-calc rofi-wayland sddm-sugar-candy-git smile syntax-highlighting tig timeshift tldr++ tmux tree-sitter ttf-nerd-fonts-symbols ttf-sharetech-mono-nerd waybar waypaper wireplumber wl-clipboard wl-clipboard-history-git wtf wtype xclip xdg-desktop-portal-gtk  xdg-desktop-portal-hyprland xdg-desktop-portal-kde xrainbow-git xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xf86-video-vmware xorg-server xorg-wayland xorg-xhost xorg-xinit xsettingsd yazi zig zoxide zsh-autosuggestions-git zsh-syntax-highlighting          
           )
                yay S --noconfirm "${PACKAGES1[@]}"


##### Section 2: Configuration  #####
{
    log_status "  🛠️   Applying base configurations..." | lsd-print
        sudo rm -rf /usr/share/hypr && sudo rm -rf ~/.config/hypr && cd ~/.hyprgruv && stow .config home --adopt | { log_error "Failed to replace hyprgruv configuration and run stow"; exit 1; }
        cd ~/.hyprgruv/setup   || { log_error "Failed to navigate to ~/scripts"; exit 1; }
        ./config.sh || { log_error "Failed to run config.sh"; exit 1; }
      checklist[config]=true
} ||  checklist[config]=false
clear

##### Section 3: Shell-Config  #####
{
	log_status "󰯂  Running post-configuration scripts..."
        cd ~/.hyprgruv/setup || { log_error "Failed to navigate to ~/scripts"; exit 1; }
        ./shell.sh || { log_error "Failed to run shell.sh"; exit 1; }
     checklist[shell]=true
} || checklist[shell]=false
clear

##### Section 4: Checklist #####

#rm -f ~/config_check.sh
print_checklist_tte

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
        echo " Rerunning the script..."   | lsd-print
        exec "$0"  # Reruns the current script
        ;;
  3)
        echo " Exiting. System will not reboot."  | lsd-print
        exit 0
        ;;
  *)
        echo " Invalid input. Exiting without reboot."  | lsd-print
        exit 0
        ;;
esac

