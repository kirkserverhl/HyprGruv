#!/usr/bin/env bash
# matugen-posthook-waybar.sh — sync waybar CSS and signal a style reload

set -euo pipefail

WAYBAR_COLORS="${HOME}/.config/waybar/colors/matugen-waybar.css"
WAYBAR_ACTIVE="${HOME}/.config/waybar/colors.css"

if [[ -f "$WAYBAR_COLORS" ]]; then
    cp -f "$WAYBAR_COLORS" "$WAYBAR_ACTIVE" 2>/dev/null || true
    touch "$WAYBAR_COLORS" 2>/dev/null || true
fi

pkill -SIGUSR2 waybar 2>/dev/null || true