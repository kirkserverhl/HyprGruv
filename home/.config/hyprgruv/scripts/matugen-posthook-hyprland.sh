#!/usr/bin/env bash
# matugen-posthook-hyprland.sh — reload Hyprland after matugen.conf is written

set -euo pipefail

HYPR_COLORS="${HOME}/.config/hypr/colors/custom/matugen.conf"
PENDING_RUN="${HOME}/.cache/matugen/pending-run.json"

# Hex mode leaves {{image}} stale in the template header — fix from pending-run.
if [[ -f "$PENDING_RUN" && -f "$HYPR_COLORS" ]]; then
    wp=$(jq -r '.wallpaper // empty' "$PENDING_RUN" 2>/dev/null || true)
    if [[ -n "$wp" ]]; then
        sed -i "s|^# Generated from:.*|# Generated from: ${wp}|" "$HYPR_COLORS" 2>/dev/null || true
    fi
fi

# Super+W reloads once at the end of apply-theme.sh. A mid-apply reload
# races the Lua loader ("cannot open …/hyprland.lua").
if [[ "${THEME_SWITCHER_APPLY:-0}" == "1" || "${RELOAD_SKIP_PRESETS:-0}" == "1" ]]; then
    exit 0
fi

if [[ ! -f "${HOME}/.config/hypr/hyprland.lua" ]]; then
    echo "[hyprland posthook] skip reload — hyprland.lua missing" >&2
    exit 0
fi

timeout 3 hyprctl reload 2>/dev/null || true