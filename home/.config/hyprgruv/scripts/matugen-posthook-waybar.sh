#!/usr/bin/env bash
# matugen-posthook-waybar.sh — sync waybar CSS and signal a style reload

set -euo pipefail

BAR_MODE_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/waybar/bar_mode"
if [[ -f "$BAR_MODE_FILE" ]]; then
    mode=$(tr -d '[:space:]' <"$BAR_MODE_FILE")
    if [[ "$mode" == "hyprbars" || "$mode" == "off" ]]; then
        # Hyprbars/hidden mode — never wake or reload Waybar.
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        # shellcheck source=bar-mode-common.sh
        source "$SCRIPT_DIR/bar-mode-common.sh"
        stop_waybar || true
        exit 0
    fi
fi

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

# Reload CSS on running Waybar only (no pkill — avoids stalls).
for f in /proc/[0-9]*/comm; do
    [[ -r "$f" && "$(<"$f")" == "waybar" ]] || continue
    kill -USR2 "$(basename "$(dirname "$f")")" 2>/dev/null || true
done