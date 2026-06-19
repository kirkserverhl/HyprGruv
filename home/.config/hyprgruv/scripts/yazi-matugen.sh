#!/usr/bin/env bash
# yazi-matugen.sh — ensure matugen theme.toml is current, then exec yazi
set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
"$SCRIPTS/reload-yazi-theme.sh" --regen
exec yazi "$@"