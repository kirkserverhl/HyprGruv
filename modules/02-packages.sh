#!/bin/bash
{
	echo -e "   📦️     Installing Essential Packages..." | lsd-print
	echo ""

	PACKAGES1=(
		ags archlinux-xdg-menu bluez bluez-utils btop bpytop cmake cpio duf eza fastfetch fzf ghostty grimblast-git gsettings-qt hyprgraphics hypridle hyprland-qt-support hexyl hyprpicker hyprshade clipse fortune-mod-archlinux grimblast-git gtk-engine-murrine kate konsole kvantum less pacman-mirrorlist pavucontrol pkg-config python-pywalfox qt5-graphicaleffects qt6ct-kde rofi-calc tig tmux tree-sitter wl-clipboard xdg-desktop-portal-kde xorg-wayland xsettingsd zoxide lightly-qt sudo pacman extra-cmake-modules kdecoration qt5-declarative qt5-x11extras python-haishoku mediainfo iwgtk meson neovim neovim-cmp neovim-lspconfig network-manager-applet nwg-dock-hyprland nwg-drawer nwg-look otf-font-awesome pacseek python-pywal16 qt5-declarative rofi-wayland smile udiskie waybar wireplumber wl-clipboard wlogout xclip xorg-wayland xsettingsd yazi zig
	)
	yay -S --noconfirm "${PACKAGES1[@]}"

	# List of essential packages
	ESSENTIAL_PACKAGES=("eza" "gum" "hyprpaper" "waypaper" "nwg-dock-hyprland" "nwg-drawer" "nwg-look" "pacseek" "python-pywal16" "python-pywalfox" "qt5-declarative" "starship" "yazi" "xsettingsd" "wlogout" "zsh")

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
		echo "All essential packages are already installed." | lsd-print
	fi
}
clear
