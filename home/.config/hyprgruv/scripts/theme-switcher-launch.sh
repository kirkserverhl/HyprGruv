#!/usr/bin/env bash
# Super+W — theme switcher (theme grid → wallpaper picker, or Waypaper from footer).
set -euo pipefail

pkill -x rofi 2>/dev/null || true
exec "$HOME/.config/colorschemes/rofi-launcher.sh"