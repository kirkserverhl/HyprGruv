#!/bin/bash
# Apply a wallpaper with awww (all outputs or a single monitor).
# Usage: awww-wallpaper.sh <image-path> [monitor-name|all]

set -euo pipefail

WALLPAPER="$1"
MONITOR="${2:-all}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Wallpaper not found: $WALLPAPER" >&2
    exit 1
fi

AWWW_ARGS=(--resize crop --transition-type center --transition-fps 60 --transition-step 90)

if [[ "$MONITOR" == "all" ]]; then
    awww img "${AWWW_ARGS[@]}" "$WALLPAPER" >/dev/null 2>&1
else
    awww img "${AWWW_ARGS[@]}" -o "$MONITOR" "$WALLPAPER" >/dev/null 2>&1
fi

ln -sf "$WALLPAPER" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null || true
printf '%s\n' "$WALLPAPER"