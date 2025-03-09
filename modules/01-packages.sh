#!/bin/bash
{
	echo -e "   📦️     Installing Essential Packages..."
	echo ""

	sudo pacman -S --noconfirm git || log_error "Failed to install git"
	git clone https://aur.archlinux.org/yay.git || log_success "Git installed successfully"
	cd yay && makepkg -si --noconfirm || log_success "YAY installed successfully"
	yay -Syu || update packages
	yay -S stow figlet powerpill --noconfirm || log_error "Failed to install stow, figlet, powerpill"
	yay -S lsd-print-git --noconfirm || log_error "Failed to insall lsd-print-git"

	PACKAGES1=(
		bluez bluez-utils btop cmake duf eza fastfetch fzf ghostty grimblast-git gsettings-qt gum hyprgraphics
		hypridle hyprland-qt-support hyprpaper hyprpicker hyprshade iwgtk neovim neovim-lspconfig network-manager-applet
		nwg-dock-hyprland nwg-drawer nwg-look pacseek python-pywal16 qt5-declarative rofi-wayland smile udiskie waybar
		waypaper wireplumber wl-clipboard wlogout xclip xorg-wayland xsettingsd yazi zig archlinux-xdg-menu clipse
		fortune-mod-archlinux grimblast-git gtk-engine-murrine kate konsole kscreen kvantum less pacman-mirrorlist
		pavucontrol python-pywalfox qt5-graphicaleffects qt6ct-kde ranger rofi-calc tig tmux tree-sitter wl-clipboard
		xdg-desktop-portal-kde xorg-wayland xsettingsd zoxide
	)
	yay -S --noconfirm "${PACKAGES1[@]}"
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
