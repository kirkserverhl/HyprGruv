#!/usr/bin/env bash
# Curated fuzzel launcher — only apps in ~/.config/fuzzel/apps-menu/applications/
pkill -x fuzzel 2>/dev/null

export XDG_DATA_HOME="${HOME}/.config/fuzzel/apps-menu"
export XDG_DATA_DIRS=""

exec fuzzel "$@"