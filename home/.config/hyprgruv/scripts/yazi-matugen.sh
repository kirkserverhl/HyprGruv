#!/usr/bin/env bash
# yazi-matugen.sh — ensure yazi theme.toml exists, then exec yazi
set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
THEME="${HOME}/.config/yazi/theme.toml"

"$SCRIPTS/reload-yazi-theme.sh" --switch 2>/dev/null || true

exec yazi "$@"