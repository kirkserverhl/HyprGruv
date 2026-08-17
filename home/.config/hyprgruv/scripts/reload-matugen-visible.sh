#!/usr/bin/env bash
# reload-matugen-visible.sh — run focused post-hooks (cache hits / manual reload)
#
# Individual hooks are also wired per-template in ~/.config/matugen/config.toml.
# Super+W sets RELOAD_SKIP_PRESETS=1 (or THEME_SWITCHER_APPLY=1) so official
# presets already applied (starship, nvim, yazi, obsidian, GTK) are not
# touched again.
#
# Manual refresh:  bash ~/.config/hyprgruv/scripts/reload-matugen-visible.sh

set -euo pipefail

SCRIPTS="${HOME}/.config/hyprgruv/scripts"
SKIP_PRESETS=0
if [[ "${RELOAD_SKIP_PRESETS:-0}" == "1" || "${THEME_SWITCHER_APPLY:-0}" == "1" ]]; then
    SKIP_PRESETS=1
fi

if [[ $SKIP_PRESETS -eq 0 ]]; then
    "${SCRIPTS}/apply-desktop-assets.sh" 2>/dev/null || true
fi

# Leftover / shared surfaces. Starship + obsidian are official Super+W presets.
for hook in hyprland waybar terminal swaync firefox browsers grok gum; do
    "${SCRIPTS}/matugen-posthook-${hook}.sh" 2>/dev/null || true
done

if [[ $SKIP_PRESETS -eq 0 ]]; then
    "${SCRIPTS}/matugen-posthook-starship.sh" 2>/dev/null || true
    "${SCRIPTS}/matugen-posthook-obsidian.sh" 2>/dev/null || true
    "${SCRIPTS}/reload-nvim-theme.sh" 2>/dev/null || true
    "${SCRIPTS}/reload-yazi-theme.sh" --switch 2>/dev/null || true
fi

# Never regen all templates from current.json here — that can overwrite a good
# matugen run if the JSON cache was briefly out of sync. Hot-reload only.
bash "${SCRIPTS}/update-sddm-wallpaper.sh" 2>/dev/null || true

hyprctl eval 'reapply_hyprbars()' 2>/dev/null || true