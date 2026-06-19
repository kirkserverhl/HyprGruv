#!/usr/bin/env bash
# matugen-posthook-terminal.sh — reload kitty/alacritty + broadcast OSC sequences to open shells
#
# Kitty: SIGUSR1 reloads ~/.config/kitty/colors/custom/matugen.conf
# Alacritty: live_config_reload picks up ~/.config/alacritty/colors/matugen.toml
# Other terminals: ~/.zshrc precmd reads reload-stamp and cats terminal-sequences

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
RELOAD_STAMP="${HOME}/.cache/matugen/reload-stamp"

mkdir -p "${HOME}/.cache/matugen"

"${SCRIPTS}/reload-kitty-colors.sh" 2>/dev/null || true

# Alacritty watches its config files; touch to nudge reload on older builds.
if [[ -f "${HOME}/.config/alacritty/colors/matugen.toml" ]]; then
    touch "${HOME}/.config/alacritty/colors/matugen.toml" 2>/dev/null || true
fi

date +%s >"$RELOAD_STAMP"