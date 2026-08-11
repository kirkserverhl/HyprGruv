#!/usr/bin/env bash
# yazi-matugen.sh — sync Super+W flavor then exec yazi
set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

# Always re-apply flavor + folder/status colors from .current-theme
bash "$SCRIPTS/reload-yazi-theme.sh" --switch 2>/dev/null || true

exec yazi "$@"
