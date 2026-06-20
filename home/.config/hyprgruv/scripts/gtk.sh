#!/bin/bash
#     _______________________  __.
#   /  _____/\__    ___/    |/ _|
#  /   \  ___  |    |  |      <
#  \    \_\  \ |    |  |    |  \
#   \______  / |____|  |____|__ \
#          \/                  \/
#
config="$HOME/.config/gtk-3.0/settings.ini"

if [ ! -f "$config" ]; then exit 1; fi

gnome_schema="org.gnome.desktop.interface"
gtk_theme="$(grep 'gtk-theme-name' "$config" | sed 's/.*\s*=\s*//')"
icon_theme="$(grep 'gtk-icon-theme-name' "$config" | sed 's/.*\s*=\s*//')"
cursor_theme="$(grep 'gtk-cursor-theme-name' "$config" | sed 's/.*\s*=\s*//')"
cursor_size="$(grep 'gtk-cursor-theme-size' "$config" | sed 's/.*\s*=\s*//')"
font_name="$(grep 'gtk-font-name' "$config" | sed 's/.*\s*=\s*//')"
if [[ -f "$HOME/.config/settings/terminal.sh" ]]; then
    terminal=$(cat "$HOME/.config/settings/terminal.sh")
elif [[ -f "${HYPRGRUV_DIR:-$HOME/.hyprgruv}/defaults/terminal.sh" ]]; then
    terminal=$("${HYPRGRUV_DIR:-$HOME/.hyprgruv}/defaults/terminal.sh")
else
    terminal="kitty"
fi

echo $gtk_theme
echo $icon_theme
echo $cursor_theme
echo $cursor_size
echo $font_name
echo $terminal

# shellcheck source=/dev/null
source "$HOME/.config/colorschemes/theme-assets.sh" 2>/dev/null || true
if declare -F gtk_theme_exists >/dev/null 2>&1 && ! gtk_theme_exists "$gtk_theme"; then
    gtk_theme=$(pick_existing_gtk_theme Gruvbox-Dark adw-gtk3-dark)
fi

gsettings set "$gnome_schema" color-scheme "prefer-dark"
gsettings set "$gnome_schema" gtk-theme ""
gsettings set "$gnome_schema" gtk-theme "$gtk_theme"
gsettings set "$gnome_schema" icon-theme "$icon_theme"
gsettings set "$gnome_schema" cursor-theme "$cursor_theme"
gsettings set "$gnome_schema" font-name "$font_name"

# gsettings set com.github.stunkymonkey.nautilus-open-any-terminal terminal "$terminal"
# gsettings set com.github.stunkymonkey.nautilus-open-any-terminal use-generic-terminal-name "true"
# gsettings set com.github.stunkymonkey.nautilus-open-any-terminal keybindings "<Ctrl><Alt>t"

if [ -f ~/.config/hypr/conf/cursor.conf ]; then
	echo "exec-once = hyprctl setcursor $cursor_theme $cursor_size" >~/.config/hypr/conf/cursor.conf
	hyprctl setcursor $cursor_theme $cursor_size
fi
