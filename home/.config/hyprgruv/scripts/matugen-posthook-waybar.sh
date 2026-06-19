#!/usr/bin/env bash
# matugen-posthook-waybar.sh — sync waybar CSS and signal a style reload

set -euo pipefail

WAYBAR_DIR="${HOME}/.config/waybar"
WAYBAR_COLORS="${WAYBAR_DIR}/colors/matugen-waybar.css"
WAYBAR_ACTIVE="${WAYBAR_DIR}/colors.css"
WAYBAR_BASE="${WAYBAR_DIR}/shared/base.css"
WAYBAR_STYLE="${WAYBAR_DIR}/style.css"

if [[ -f "$WAYBAR_COLORS" ]]; then
    cp -f "$WAYBAR_COLORS" "$WAYBAR_ACTIVE" 2>/dev/null || true
    touch "$WAYBAR_COLORS" "$WAYBAR_BASE" 2>/dev/null || true
    if [[ -L "$WAYBAR_STYLE" || -f "$WAYBAR_STYLE" ]]; then
        touch "$WAYBAR_STYLE" 2>/dev/null || true
    fi
fi

pkill -SIGUSR2 waybar 2>/dev/null || true