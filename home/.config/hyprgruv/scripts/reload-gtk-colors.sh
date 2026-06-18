#!/usr/bin/env bash
# reload-gtk-colors.sh — push matugen GTK colors into open GTK3/GTK4 apps
#
# GTK has no kitty-style SIGUSR1 reload. We rely on:
#   1. colorreload-gtk-module (watches ~/.config/gtk-3.0/colors.css)
#   2. A gtk-theme gsettings toggle to force CSS re-read
#
# Some widgets (VTE consoles, GtkSourceView, etc.) may still need an app restart.

set -euo pipefail

GTK3_SETTINGS="${HOME}/.config/gtk-3.0/settings.ini"
GTK3_COLORS="${HOME}/.config/gtk-3.0/colors.css"
GTK4_COLORS="${HOME}/.config/gtk-4.0/colors.css"
SCHEMA="org.gnome.desktop.interface"

gtk_theme="adw-gtk3-dark"
if [[ -f "$GTK3_SETTINGS" ]]; then
    gtk_theme="$(grep -E '^gtk-theme-name=' "$GTK3_SETTINGS" | sed -E 's/^gtk-theme-name=//' | tr -d '"' | xargs)"
    [[ -z "$gtk_theme" ]] && gtk_theme="adw-gtk3-dark"
fi

for css in "$GTK3_COLORS" "$GTK4_COLORS"; do
    [[ -f "$css" ]] && touch "$css" 2>/dev/null || true
done

if ! command -v gsettings >/dev/null 2>&1; then
    exit 0
fi

gsettings set "$SCHEMA" color-scheme "prefer-dark" 2>/dev/null || true
gsettings set "$SCHEMA" gtk-theme "" 2>/dev/null || true
gsettings set "$SCHEMA" gtk-theme "$gtk_theme" 2>/dev/null || true