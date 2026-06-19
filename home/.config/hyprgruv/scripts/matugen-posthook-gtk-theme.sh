#!/usr/bin/env bash
# Apply GTK window theme from the active colorscheme slot (e.g. Gruvbox-Dark).
set -euo pipefail

SCHEMA="org.gnome.desktop.interface"
CURRENT_THEME_FILE="${HOME}/.config/colorschemes/.current-theme"
GTK3_SETTINGS="${HOME}/.config/gtk-3.0/settings.ini"
gtk_theme="adw-gtk3-dark"

if [[ -f "$CURRENT_THEME_FILE" ]]; then
    theme=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
    theme_file="${HOME}/.config/colorschemes/${theme}/gtk-theme"
    if [[ -n "$theme" && -f "$theme_file" ]]; then
        gtk_theme=$(tr -d '[:space:]' <"$theme_file")
    fi
elif [[ -f "$GTK3_SETTINGS" ]]; then
    gtk_theme=$(grep -E '^gtk-theme-name=' "$GTK3_SETTINGS" | sed -E 's/^gtk-theme-name=//' | tr -d '"' | xargs)
    [[ -z "$gtk_theme" ]] && gtk_theme="adw-gtk3-dark"
fi

command -v gsettings >/dev/null 2>&1 || exit 0

gsettings set "$SCHEMA" color-scheme "prefer-dark" 2>/dev/null || true
gsettings set "$SCHEMA" gtk-theme "" 2>/dev/null || true
gsettings set "$SCHEMA" gtk-theme "$gtk_theme" 2>/dev/null || true

if [[ -f "$GTK3_SETTINGS" ]] && grep -q '^gtk-theme-name=' "$GTK3_SETTINGS"; then
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=${gtk_theme}/" "$GTK3_SETTINGS"
fi