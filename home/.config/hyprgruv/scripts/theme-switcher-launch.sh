#!/usr/bin/env bash
# Super+W — theme switcher (theme grid → wallpaper picker, or Waypaper from footer).
set -euo pipefail

killall -9 rofi 2>/dev/null || true

if ! "$HOME/.config/colorschemes/rofi-launcher.sh"; then
    notify-send "Theme switcher" "Could not open theme picker (see ~/.cache/matugen.log)" -u critical 2>/dev/null || true
    exit 1
fi