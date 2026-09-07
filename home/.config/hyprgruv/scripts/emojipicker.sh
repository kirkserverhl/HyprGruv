#!/usr/bin/env bash
# Super+E / MX F6. Package: hypremoji (AUR, lib/packages/aur.list).
#
# Hypremoji copies the pick, fake-pastes into the previous window, then
# restores the old clipboard. If no caret was focused, the paste misses and
# the emoji is gone. After the picker closes, put the last pick back on the
# clipboard (mac-style: pick, then paste when ready).
set -euo pipefail

if ! command -v hypremoji >/dev/null 2>&1; then
	notify-send -e -u low "Emoji picker" "hypremoji is not installed. It is in aur.list — run sync-packages.sh"
	exit 1
fi

recents="$HOME/.config/hypremoji/recents.json"
css="$HOME/.config/hypremoji/matugen.css"

before_mtime=0
before_emoji=
if [[ -f "$recents" ]]; then
	before_mtime=$(stat -c %Y "$recents")
	before_emoji=$(jq -r '.emojis[0] // empty' "$recents")
fi

if [[ -f "$css" ]]; then
	hypremoji -s "$css" || true
else
	hypremoji || true
fi

[[ -f "$recents" ]] || exit 0
[[ -x "$(command -v wl-copy)" ]] || exit 0

after_mtime=$(stat -c %Y "$recents")
after_emoji=$(jq -r '.emojis[0] // empty' "$recents")
[[ -n "$after_emoji" ]] || exit 0

# Cancel leaves recents untouched. A pick rewrites the file (even a repeat).
if (( after_mtime > before_mtime )) || [[ "$after_emoji" != "$before_emoji" ]]; then
	printf '%s' "$after_emoji" | wl-copy --type text/plain
fi
