#!/usr/bin/env bash
# reload-matugen-visible.sh — run all focused matugen post-hooks (cache hits / manual reload)
#
# Individual hooks are also wired per-template in ~/.config/matugen/config.toml.
# This orchestrator runs them together when matugen is skipped (cache hit) or
# you want a manual refresh:  bash ~/.config/hyprgruv/scripts/reload-matugen-visible.sh

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

"${SCRIPTS}/apply-desktop-assets.sh" 2>/dev/null || true

for hook in hyprland waybar starship terminal dunst swaync firefox grok; do
    "${SCRIPTS}/matugen-posthook-${hook}.sh" 2>/dev/null || true
done

# Never regen all templates from current.json here — that can overwrite a good
# matugen run if the JSON cache was briefly out of sync. Hot-reload only.
"${SCRIPTS}/reload-yazi-theme.sh" --switch 2>/dev/null || true

hyprctl eval 'reapply_hyprbars()' 2>/dev/null || true