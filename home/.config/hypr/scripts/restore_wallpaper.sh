#!/bin/bash
# Robust wallpaper restore on Hyprland login.
# - Loads the last known wallpaper from the primary cache (or legacy last_wallpaper.txt)
# - Uses waypaper --wallpaper so that the configured post_command runs (set_wallpaper.sh)
#   which re-runs the matugen quick-auto + generates assets + updates SDDM etc.
# - Non-interactive: set_wallpaper.sh auto-applies Dark Standard + source color 1.
# - Has a direct awww fallback in case the waypaper CLI path has issues.
#
# This replaces the plain "waypaper --restore" which only sets the image on the backend
# and does not trigger matugen re-application.

set -uo pipefail

# shellcheck source=/home/kirk/.config/settings/wallpaper-paths.sh
source "$HOME/.config/settings/wallpaper-paths.sh"
CACHE="$CURRENT_WALLPAPER_FILE"
LEGACY_LAST="$CURRENT_WALLPAPER_FILE"
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

echo "[restore_wallpaper] starting at $(date)"

# Determine last wallpaper (priority: cache > legacy last_wallpaper.txt > waypaper config entry)
WP=""
if [ -f "$CACHE" ]; then
    WP=$(cat "$CACHE" | tr -d '\r\n')
elif [ -f "$LEGACY_LAST" ]; then
    WP=$(cat "$LEGACY_LAST" | tr -d '\r\n')
elif [ -f "$WAYPAPER_CONFIG" ]; then
    WP=$(grep -E '^\s*wallpaper\s*=' "$WAYPAPER_CONFIG" 2>/dev/null | tail -1 | cut -d'=' -f2- | xargs || true)
fi

if [ -z "$WP" ] || [ ! -f "$WP" ]; then
    echo "[restore_wallpaper] No valid last wallpaper found (cache=$CACHE, wp=$WP). Nothing to restore."
    exit 0
fi

echo "[restore_wallpaper] target: $WP"

# Give the wallpaper daemon (awww via waypaper-engine) and monitors time to settle.
# The autostart already does some sleeps, but this is self-contained and defensive.
for i in 1 2 3; do
    if awww query >/dev/null 2>&1; then
        break
    fi
    echo "[restore_wallpaper] waiting for awww daemon... ($i)"
    sleep 0.8
done

# Primary path: go through waypaper so post_command (set_wallpaper.sh) is invoked.
# This ensures matugen is re-applied, assets are (re)generated if needed, SDDM updated, etc.
echo "[restore_wallpaper] setting via waypaper (will invoke post_command + matugen)"
waypaper --wallpaper "$WP" >>/tmp/restore_wallpaper.log 2>&1 || true

# Direct fallback / belt-and-suspenders: tell awww daemon directly.
# This guarantees an image actually appears even if waypaper's restore bookkeeping is odd.
echo "[restore_wallpaper] ensuring via direct awww img"
awww img "$WP" >>/tmp/restore_wallpaper.log 2>&1 || true

# Nudge waybar in case colors changed
pkill -SIGUSR2 waybar 2>/dev/null || true

echo "[restore_wallpaper] done"
