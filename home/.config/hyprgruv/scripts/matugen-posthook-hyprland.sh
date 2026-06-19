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

timeout 3 hyprctl reload 2>/dev/null || true