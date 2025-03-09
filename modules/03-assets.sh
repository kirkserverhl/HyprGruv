#!/bin/bash
source ~/.hyprgruv/lib/common.sh
export SCRIPT_DIR CONFIG_DIR BACKUP_DIR

cp -rf ~/.hyprgruv/assets/.mozilla ~/
cp -rf ~/.hyprgruv/assets/nvim ~/.local

# Chaotic Pacman Mirrors
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

#  Transfer Pacman Configuration
sudo cp -r ~/.hyprgruv/assets/pacman.conf /etc/pacman.conf

#  Hyprpm plugins for seaglass theme
hyprpm add https://github.com/alexhulbert/Hyprchroma
hyprpm add https://github.com/DreamMaoMao/hycov
hyprpm add https://github.com/hyprwm/hyprland-plugins
hyprpm enable hyprchroma

# hyprpm enable hycov
hyprpm enable hyprexpo

# Update pywal and systems
pywalfox update
systemctl --user restart hyprpaper waybar

clear
# cd ~/scripts && ./launch.sh

# touch ~/.config/hypr/conf/hyprland.conf
# touch ~/.cache/wal/colors-hyprland.conf

# yay -Syu ungoogled-chromium -Su && paru -Su --noconfirm
#yay -Syu plasma-desktop kvantum-qt6-git kvantum-qt4-git nx-plaxma-look-and-feel-git --noconfirm
#sudo git clone https://github.com/nx-desktop/nx-plasma-look-and-feel.git /usr/share/plasma/look-and-feel/

#kde-material-you-colors --file ~/.cache/wallpaper-path --iconsdark Papirus-Colors-Dark --iconslight Papirus-Colors --chroma-multiplier 1.25 -wal -ko 84 --scheme-variant 6 --on-change-hook "kde-material-you-colors --stop"
#source ~/.cache/wal/colors.sh
#sed -i "/\[Colors:Window]/,+2 s/=#....../=$background/g" ~/.local/share/color-schemes/MaterialYouDark.colors
#sed -Ei '/\[Colors:(Header|Tooltip|Complementary)\]/,+2 s/=#/=#D4/g' ~/.local/share/color-schemes/MaterialYouDark.colors
#sed -i '/\[Colors:View\]/,+2 s/=#/=#44/g' ~/.local/share/color-schemes/MaterialYouDark.colors

#lookandfeeltool -a "$HOME/.local/share/plasma/look-and-feel/sealass"
#plasma-apply-colorscheme MaterialYouDark2
#plasma-apply-colorscheme MaterialYouDark

# change breeze gtk background to match qt
#sleep 0.5
#gtkBkg=$(grep 'theme_bg_color_breeze' ~/.config/gtk-3.0/colors.css | cut -d' ' -f3 | cut -c 1-7)
#sed -i "s/$gtkBkg/$background/g" ~/.config/gtk-3.0/colors.css
#sed -i "s/$gtkBkg/$background/g" ~/.config/gtk-4.0/colors.css

# add selection colors
#for file in "$HOME/.config/gtk-3.0/colors.css" "$HOME/.config/gtk-4.0/colors.css"; do
#	mkdir -p "$(dirname "$file")"
#	grep -q "@define-color selected_bg_color" "$file" 2>/dev/null || echo "
#@define-color selected_bg_color @theme_selected_bg_color_breeze;
#@define-color selected_fg_color @theme_selected_fg_color_breeze;" >>"$file"
#done

#if [ -z "$1" ]; then
#	wallpaper=$(find ~/wallpaper/ -type f | shuf -n 1)
#else
#	wallpaper=$1
#fi

#if [ -e "$wallpaper.scheme" ]; then
#	echo test
#	# pass
#else
#	rm ~/.cache/wallpaper
#	ln -s "$wallpaper" ~/.cache/wallpaper
#	echo "$wallpaper" >~/.cache/wallpaper-path
#	if ! pgrep -x "hyprpaper" >/dev/null; then
#		export SWWW_TRANSITION_STEP=255
#	fi
#	swww init --no-cache
#	swww img "$wallpaper"
#fi
