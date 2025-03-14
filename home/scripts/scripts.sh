#!/usr/bin/env sh

ScrDir=$(dirname $(realpath $0))
source $ScrDir/globalcontrol.sh
roconf="~/.config/rofi/config-compact.rasi"

keybinds_hint="  Cleanup	          	cleanup.sh
󰹑   Monitors 		   	monitors.sh
   DOOM 		   	doom.sh
󰊪   Editors Packages	   	editors_packages.sh
   SDDM,Grub,SHELL,etc	   	config.sh
   Figlet	   	   	figlet.sh
󰸉   Animations (RT 󰇘   	   	animation.sh
󰹑   Decorations (RT       	animation.sh
   Re-install Gruvbox        	install.sh"

#  󰀻  󰹑  󰁱  󱈶    󰹑  󰸉     󰯃  󰙧
#   Keybindings             	keybind_hints.sh
# This is with an '' as a separator
selected=$(echo -e "$keybinds_hint" | rofi -dmenu -p -i -theme-str "${fnt_override}" -theme-str "${r_override}" -theme-str "${icon_override}" -config "${roconf}" | sed 's/.*\s*//')

case "$selected" in
"cleanup.sh")
  ~/.dotfiles/cleanup.sh
  ;;  
"monitors.sh")
  ~/scripts/monitors.sh
  ;;
"doom.sh")
  ~/scripts/doom.sh
  ;;  
"editors_packages.sh")
  ~/scripts/editors_packages.sh
  ;; 
"config.sh")
  ~/scripts/config.sh
  ;;  
"animations.sh")
  ~/scripts/animations.sh
  ;;  
"decorations.sh")
  ~/scripts/decorations.sh
  ;;  
"install.sh")
  ~/.dotfiles/install.sh
  ;;  
esac


