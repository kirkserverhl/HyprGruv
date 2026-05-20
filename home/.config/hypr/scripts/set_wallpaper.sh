#!/bin/bash
# =============================================
# set_wallpaper.sh - Post waypaper command
# =============================================

CACHE_WAL="$HOME/.cache/wal/wal"
LAST_WP="$HOME/.config/last_wallpaper.txt"
DEFAULT_WP="$HOME/Pictures/Wallpapers/default.jpg" # ← note: capital W

# Get current wallpaper from wal cache
if [ -f "$CACHE_WAL" ]; then
    CURRENT_WP=$(cat "$CACHE_WAL" | tr -d '\n\r')
else
    CURRENT_WP="$DEFAULT_WP"
fi

# Resolve path and fallback logic
if [[ -z "$CURRENT_WP" || ! -f "$CURRENT_WP" ]]; then
    if [ -f "$LAST_WP" ]; then
        CURRENT_WP=$(cat "$LAST_WP")
    fi
    if [[ ! -f "$CURRENT_WP" ]]; then
        CURRENT_WP="$DEFAULT_WP"
    fi
fi

echo "Selected file: $CURRENT_WP"

# Save for next time
echo "$CURRENT_WP" >"$LAST_WP"

# Call our processor script
"$HOME/.config/hypr/scripts/wallpaper.sh" "$CURRENT_WP"
