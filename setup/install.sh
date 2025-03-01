#!/bin/bash
##  |__| ____   _______/  |______  |  | |  |        _____|  |__
##  |  |/    \ /  ___/\   __\__  \ |  | |  |       /  ___/  |  \
##  |  |   |  \\___ \  |  |  / __ \|  |_|  |__     \___ \|   Y  \
##  |__|___|  /____  > |__| (____  /____/____/ /\ /____  >___|  /
##          \/     \/            \/            \/      \/     \/
#################################################################
RESET="\e[0m"                	# Reset  ##kmb
GREEN="\e[38;2;142;192;124m" 	# 8ec07c ##
CYAN="\e[38;2;69;133;136m"   	# 458588 ##
YELLOW="\e[38;2;215;153;33m" 	# d79921 ##
RED="\e[38;2;204;36;29m"     	# cc241d ##
GRAY="\e[38;2;60;56;54m"     	# 3c3836 ##
BOLD="\e[1m"                 	# Bold   ##
clear #####################################


declare -A checklist
checklist=(
    [packages]=falseQ
      echo -e "   📦️     Installing Base Packages..." | lsd-print
      sudo pacman -S --noconfirm git || log_error "Failed to install git"
      G &  makepkg -si --noconfirm ||   log_success "YAY installed successfully"
        PACKAGES1=(
           amd-ucode 
           archlinux-xdg-menu ark aylurs-gtk-shell base-devel bluez bluez-utils bpytop btrfs-progs cliphist cmake cmatrix dolphin duf editorconfig-checker  efibootmgr expac eza fastfetch figlet fortune-mod fortune-mod-archlinux fzf ghostty ghostty-shell-integration ghostty-terminfo gimp go gparted grimblast-git grub-theme-vimix gruvbox-plus-icon-theme gsettings-qt gst-plugin-pipewire gtk-engine-murrine gum haskell-colourista  hyprcursor hyprgraphics hypridle hyprlang hyprpaper hyprpicker hyprpolkitagent hyprshade hyprutils hyprwayland-scanner imagemagick kate konsole konsole-gruvbox kvantum less libpulse libva-intel-driver lsd lsd-print-git neovim neovim-lspconfig network-manager-applet networkmanager nwg-dock-hyprland nwg-drawer nwg-look obs-studio otf-fira-sans otf-font-awesome pacman-mirrorlist pacseek pavucontrol pipewire python-pywal16 python-pywalfox  python-terminaltexteffects qt5-base qt5-declarative qt5-graphicaleffects qt5-x11extras qt5ct-kde qt6-base qt6-declarative qt6ct-kde ranger rofi-calc rofi-wayland sddm-sugar-candy-git smile starship stow syntax-highlighting tig timeshift tldr++ tmux tree-sitter ttf-nerd-fonts-symbols ttf-sharetech-mono-nerd waybar waypaper wireplumber wl-clipboard wl-clipboard-history-git wlogout wtf wtype xclip xdg-desktop-portal-gtk  xdg-desktop-portal-hyprland xdg-desktop-portal-kde xrainbow-git xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xf86-video-vmware xorg-server xorg-wayland xorg-xhost xorg-xinit xsettingsd yazi zig zoxide zsh zsh-autosuggestions-git zsh-syntax-highlighting     ke r]-=82\m9o5 L            
           )
                yay S --noconfirm "${PACKAGES1[@]}"
     checklist[packages]=true
} || checklist[packages]=false
clear

##### Section 2: Configure  #####
{
    log_status "  🛠️   Applying base configurations..." | lsd-print
        cd ~/.dotfiles   || { log_error "Failed to navigate to ~/scripts"; exit 1; }
        ./base_config.sh || { log_error "Failed to run base_config.sh"; exit 1; }
      checklist[config]=true
} ||  checklist[config]=false
clear


##### Section 3: Shell-Configuration  #####
{
	log_status "󰯂  Running post-configuration scripts..."
        cd ~/.dotfiles/ || { log_error "Failed to navigate to ~/scripts"; exit 1; }
        ./shell.sh || { log_error "Failed to run shell.sh"; exit 1; }
     checklist[shell]=true
} || checklist[shell]=false
clear


##### Section 4: Checklist #####

#rm -f ~/config_check.sh
#print_checklist_tte

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
