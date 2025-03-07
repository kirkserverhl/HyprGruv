cp -rf ~/.hyprgruv/assets/mozilla/ ~/.mozilla
sleep 1s

cd ~/scripts && ./launch.sh
sleep 1s

touch ~/.config/hypr/conf/hyprland.conf
touch ~/.cache/wal/colors-hyprland.conf

# sudo cp -r ~/.hyprgruv/assets/sddm/ /usr/share/sddm/

###  Package Customization  ##
cd ~/.hyprgruv/setup &&
  ./config.sh
