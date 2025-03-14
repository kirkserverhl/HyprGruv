###########   Installation Summary  ###############
echo -e "\n Configuration Completed Successfully." | lsd-print

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
  echo " Rerunning the script..." | lsd-print
  exec "$0" # Reruns the current script
  ;;
3)
  echo " Exiting. System will not reboot." | lsd-print
  exit 0
  ;;
*)
  echo " Invalid input. Exiting without reboot." | lsd-print
  exit 0
  ;;
esac
