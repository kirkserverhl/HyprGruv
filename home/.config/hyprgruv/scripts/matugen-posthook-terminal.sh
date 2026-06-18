#!/usr/bin/env bash
# matugen-posthook-terminal.sh — reload kitty + broadcast OSC sequences to open shells
#
# Kitty: SIGUSR1 reloads ~/.config/kitty/colors.conf
# Other terminals: ~/.zshrc precmd reads reload-stamp and cats terminal-sequences

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
RELOAD_STAMP="${HOME}/.cache/matugen/reload-stamp"

mkdir -p "${HOME}/.cache/matugen"

"${SCRIPTS}/reload-kitty-colors.sh" 2>/dev/null || true

date +%s >"$RELOAD_STAMP"