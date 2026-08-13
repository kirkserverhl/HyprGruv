#!/bin/bash
#
# settings-menu.sh
# Rofi-based Settings Hub for Waybar
#
# Purpose:
#   Compact "gear" icon on the bar that surfaces all the less-frequently-used
#   configuration tools via a clean Rofi menu instead of taking permanent space.
#
# This fits the design goal of a minimal bar where most things pop out via Rofi.
#
# How to extend:
#   1. Add a new line in the `options` variable below (with a nice icon + label).
#   2. Add a matching case in the `case` statement.
#   3. Point it at an existing script or command.
#
# Recommended rofi configs to try:
#   config-compact.rasi   (used by keybinds — good balance)
#   config-short.rasi
#   config-themes.rasi
#

# --- Menu definition (edit this list to add/remove items) ---
options=$(cat <<EOF
  Wallpapers & Decorations
  Waybar Themes
󰀻  Animations
  Edit .zshrc
EOF
)

# --- Launch Rofi ---
chosen=$(echo "$options" | rofi -dmenu -i \
    -p "Settings" \
    -config ~/.config/rofi/config-compact.rasi \
    -no-fixed-num-lines \
    -width 30)

# --- Handle selection ---
case "$chosen" in
    *"Wallpapers"*)
        waypaper
        ;;

    *"Waybar Themes"*)
        ~/.config/hypr/scripts/themeswitcher.sh
        ;;

    *"Animations"*)
        ~/.config/hypr/scripts/animations.sh
        ;;

    *"Edit .zshrc"*)
        # Try to use the project's terminal launcher if available
        if [ -f ~/.config/hypr/scripts/terminal.sh ]; then
            $(cat ~/.config/hypr/scripts/terminal.sh) --class dotfiles-floating -e nvim ~/.zshrc
        else
            # Fallbacks (adjust to taste)
            kitty --class dotfiles-floating -e nvim ~/.zshrc 2>/dev/null || \
            alacritty --class dotfiles-floating -e nvim ~/.zshrc 2>/dev/null || \
            nvim ~/.zshrc
        fi
        ;;

    *)
        # User cancelled or selected nothing — do nothing
        exit 0
        ;;
esac
