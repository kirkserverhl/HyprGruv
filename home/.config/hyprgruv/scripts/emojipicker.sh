#!/usr/bin/env bash
# MX F6 / XF86EmojiPicker. Package: hypremoji (AUR, lib/packages/aur.list).
set -euo pipefail
if ! command -v hypremoji >/dev/null 2>&1; then
	notify-send -e -u low "Emoji picker" "hypremoji is not installed. It is in aur.list — run sync-packages.sh"
	exit 1
fi
css="$HOME/.config/hypremoji/matugen.css"
if [[ -f "$css" ]]; then
	exec hypremoji -s "$css"
fi
exec hypremoji
