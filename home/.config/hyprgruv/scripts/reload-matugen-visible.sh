#!/usr/bin/env bash
# reload-matugen-visible.sh — run all focused matugen post-hooks (cache hits / manual reload)
#
# Individual hooks are also wired per-template in ~/.config/matugen/config.toml.
# This orchestrator runs them together when matugen is skipped (cache hit) or
# you want a manual refresh:  bash ~/.config/hyprgruv/scripts/reload-matugen-visible.sh

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"

for hook in hyprland waybar starship terminal dunst; do
    "${SCRIPTS}/matugen-posthook-${hook}.sh" 2>/dev/null || true
done

# GTK has no per-run matugen cache-hit path in apply-matugen-auto; keep bundled here
"${SCRIPTS}/reload-gtk-colors.sh" 2>/dev/null || true