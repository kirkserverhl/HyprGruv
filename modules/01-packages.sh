#!/bin/bash
# 01-packages.sh

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

RESET="\e[0m"
GREEN="\e[38;2;142;192;124m"
CYAN="\e[38;2;69;133;136m"
YELLOW="\e[38;2;215;153;33m"
RED="\e[38;2;204;36;29m"
GRAY="\e[38;2;60;56;54m"
BOLD="\e[1m"

{
	echo -e "   📦️     Installing Essential Packages..." | lsd-print
	echo ""
	sleep 1

	yay -Syu

	PACKAGES1=(
		powerpill aylurs-gtk-shell-git archlinux-xdg-menu bash-language-server bat bluez bluez-utils bpytop btop clipse cmake cpio diskonaut duf exa extra-cmake-modules fastfetch fortune-mod-archlinux fzf ghostty glow grimblast-git gsettings-qt gtk-engine-murrine hexyl hyprpaper hyprgraphics hypridle hyprland-qt-support hyprpicker hyprshade iwgtk kate kdecoration konsole kvantum less lscolors-git mediainfo meson ncdu neovim neovim-cmp neovim-lspconfig network-manager-applet nwg-dock-hyprland nwg-drawer nwg-look pacman pacman-mirrorlist pacseek pavucontrol pkg-config progress-git python-ansicolors python-pywal16 python-pywalfox qt5-declarative qt5-graphicaleffects qt5-x11extras qt6ct-kde rofi-calc rofi-wayland smile starship stow sudo tig tmux tree tree-sitter udiskie waybar waypaper wireplumber wl-clip-persist wl-clipboard wl-clipboard wl-clipboard-history-git wlogout xclip xdg-desktop-portal-kde xorg-wayland xorg-wayland xsettingsd xsettingsd yazi zoxide zsh waybar
		)

	yay -S --noconfirm "${PACKAGES1[@]}"
	sleep 1

	# List of essential packages
	ESSENTIAL_PACKAGES=("nwg-dock-hyprland" "nwg-drawer" "nwg-look" "python-pywal16" "python-pywalfox" "qt5-declarative" "wlogout" "xsettingsd" "yazi")

	# Check for missing packages
	MISSING_PACKAGES=()
	for pkg in "${ESSENTIAL_PACKAGES[@]}"; do
		if ! pacman -Qq "$pkg" &>/dev/null; then
			MISSING_PACKAGES+=("$pkg")
		fi
	done
	sleep 1

	# Install missing packages
	if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
		echo "Installing missing essential packages: ${MISSING_PACKAGES[*]}"
		sudo pacman -Sy --noconfirm "${MISSING_PACKAGES[@]}"
	else
		echo "All essential packages are already installed." | lsd-print
	fi
	sleep 2
}
clear
