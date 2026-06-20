#!/usr/bin/env bash
# Apply GTK + icon + cursor assets for the active colorscheme slot.
set -euo pipefail

SCRIPT="${HOME}/.config/hyprgruv/scripts/apply-desktop-assets.sh"
[[ -x "$SCRIPT" ]] || exit 0
"$SCRIPT"