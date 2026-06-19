#!/usr/bin/env bash
# Curated fuzzel launcher — only apps in ~/.config/fuzzel/apps-menu/applications/
pkill -x fuzzel 2>/dev/null

FUZZEL_CONFIG="${HOME}/.config/fuzzel"
SYSTEM_ICONS="${FUZZEL_CONFIG}/icon-lookup/icons"
USER_ICONS="${FUZZEL_CONFIG}/user-icon-lookup/icons"

mkdir -p "${SYSTEM_ICONS}" "${USER_ICONS}"

link_icon_theme() {
  local dest="$1" src="$2"
  if [[ -e "${src}" && ! -e "${dest}" ]]; then
    ln -sf "${src}" "${dest}"
  fi
}

link_icon_theme "${SYSTEM_ICONS}/Papirus" /usr/share/icons/Papirus
link_icon_theme "${SYSTEM_ICONS}/Papirus-Dark" /usr/share/icons/Papirus-Dark
link_icon_theme "${SYSTEM_ICONS}/hicolor" /usr/share/icons/hicolor
link_icon_theme "${USER_ICONS}/hicolor" "${HOME}/.local/share/icons/hicolor"

export XDG_DATA_HOME="${FUZZEL_CONFIG}/apps-menu"
export XDG_DATA_DIRS="${FUZZEL_CONFIG}/icon-lookup:${FUZZEL_CONFIG}/user-icon-lookup"

exec fuzzel -n fuzzel "$@"