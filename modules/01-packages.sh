#!/bin/bash
# 01-packages.sh

# Load common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/state.sh"

{
	echo -e "   📦️     Installing Essential Packages..." | lsd-print
	echo ""
	sleep 1

	yay -Syu

	PACKAGES1=(
		powerpill ags archlinux-xdg-menu bluez bluez-utils bpytop btop clipse cmake cpio duf exa extra-cmake-modules fastfetch fortune-mod-archlinux fzf ghostty grimblast-git gsettings-qt gtk-engine-murrine hexyl hyprpaper hyprgraphics hypridle hyprland-qt-support hyprpicker hyprshade iwgtk kate kdecoration konsole kvantum less lightly-qt mediainfo meson neovim neovim-cmp neovim-lspconfig network-manager-applet nwg-dock-hyprland nwg-drawer nwg-look pacman pacman-mirrorlist pacseek pavucontrol pkg-config python-haishoku progress-git python2-pygments python2-pygments-style-gruvbox-git python-pywal16 python-pywalfox qt5-declarative qt5-graphicaleffects qt5-x11extras qt6ct-kde rofi-calc rofi-wayland smile stow sudo tig tmux tree-sitter udiskie waybar waypaper wireplumber wl-clip-persist wl-clipboard wl-clipboard wl-clipboard-history-git wlogout xclip xdg-desktop-portal-kde xorg-wayland xorg-wayland xsettingsd xsettingsd yazi zig zoxide zsh waybar
	)
	yay -S --noconfirm "${PACKAGES1[@]}"
	sleep 1

	# List of essential packages
	ESSENTIAL_PACKAGES=("nwg-dock-hyprland" "nwg-drawer" "nwg-look" "python-pywal16" "python-pywalfox" "qt5-declarative" "stow" "waypaper" "wlogout" "xsettingsd" "yazi" "zsh")

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
sleep 1
clear
