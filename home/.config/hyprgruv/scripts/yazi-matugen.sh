#!/usr/bin/env bash
# yazi-matugen.sh — ensure yazi theme.toml exists, then exec yazi
set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
THEME="${HOME}/.config/yazi/theme.toml"

if [[ ! -f "$THEME" ]]; then
    "$SCRIPTS/reload-yazi-theme.sh" --regen
else
    "$SCRIPTS/reload-yazi-theme.sh" --icons 2>/dev/null || true
fi

exec yazi "$@"