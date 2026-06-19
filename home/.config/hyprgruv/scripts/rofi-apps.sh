#!/usr/bin/env bash
# Curated app launcher — only ~/.config/rofi/apps-menu/applications/
set -euo pipefail

pkill -x rofi 2>/dev/null || true

APPS_MENU="${HOME}/.config/rofi/apps-menu"
ICON_LOOKUP="${HOME}/.config/rofi/icon-lookup"
USER_ICON_LOOKUP="${HOME}/.config/rofi/user-icon-lookup"
SYSTEM_ICONS="${ICON_LOOKUP}/icons"
USER_ICONS="${USER_ICON_LOOKUP}/icons"
THEME="${HOME}/.config/rofi/config-apps.rasi"

mkdir -p "${SYSTEM_ICONS}" "${USER_ICONS}"

link_icon_theme() {
  local dest="$1" src="$2"
  if [[ -e "${src}" && ! -e "${dest}" ]]; then
    ln -sf "${src}" "${dest}"
  fi
}

link_icon_theme "${SYSTEM_ICONS}/Gruvbox-Plus-Dark" /usr/share/icons/Gruvbox-Plus-Dark
link_icon_theme "${SYSTEM_ICONS}/Gruvbox-Plus-Light" /usr/share/icons/Gruvbox-Plus-Light
link_icon_theme "${SYSTEM_ICONS}/Papirus" /usr/share/icons/Papirus
link_icon_theme "${SYSTEM_ICONS}/Papirus-Dark" /usr/share/icons/Papirus-Dark
link_icon_theme "${SYSTEM_ICONS}/hicolor" /usr/share/icons/hicolor
link_icon_theme "${USER_ICONS}/hicolor" "${HOME}/.local/share/icons/hicolor"

# XDG_DATA_HOME limits which .desktop files drun sees (favorites only).
# XDG_DATA_DIRS must expose icon themes but NOT /usr/share/applications.
export XDG_DATA_HOME="${APPS_MENU}"
export XDG_DATA_DIRS="${ICON_LOOKUP}:${USER_ICON_LOOKUP}"

exec rofi -show drun -show-icons -replace -config "${THEME}" "$@"