#!/bin/bash
# Apply a wallpaper with awww (all outputs or a single monitor).
# Usage: awww-wallpaper.sh <image-path> [monitor-name|all]
#
# Env:
#   AWWW_PERSIST=1  also write last_wallpaper / default_wp / waypaper config
#                   so login restore + SDDM stay in sync with this choice.

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

# Hyprlock: prefer stable default_wp when persisting; else direct path for previews.
if [[ "${AWWW_PERSIST:-0}" == "1" ]]; then
    DEFAULT_WP_PNG="$HOME/.config/settings/default_wp.png"
    LIBRARY_DEFAULT_PNG="$HOME/Pictures/Wallpapers/default.png"
    WAYPAPER_INI="$HOME/.config/waypaper/config.ini"

    # Source path of last explicit choice (login restore + set_wallpaper fallback).
    printf '%s\n' "$WALLPAPER" >"$HOME/.config/last_wallpaper.txt"
    printf '%s\n' "$WALLPAPER" >"$HOME/.config/settings/default" 2>/dev/null || true

    # Canonical PNG copy (same path SDDM helpers and restore prefer).
    mkdir -p "$HOME/.config/settings" 2>/dev/null || true
    if command -v magick >/dev/null 2>&1; then
        magick "$WALLPAPER" -strip -interlace none -quality 92 "$DEFAULT_WP_PNG" 2>/dev/null \
            || cp -f "$WALLPAPER" "$DEFAULT_WP_PNG"
    else
        cp -f "$WALLPAPER" "$DEFAULT_WP_PNG"
    fi
    chmod 644 "$DEFAULT_WP_PNG" 2>/dev/null || true

    # Keep library default.png real (not a broken stow seed symlink).
    mkdir -p "$(dirname "$LIBRARY_DEFAULT_PNG")" 2>/dev/null || true
    if [[ -L "$LIBRARY_DEFAULT_PNG" ]]; then
        rm -f "$LIBRARY_DEFAULT_PNG" 2>/dev/null || true
    fi
    cp -f "$DEFAULT_WP_PNG" "$LIBRARY_DEFAULT_PNG" 2>/dev/null \
        || cp -f "$WALLPAPER" "$LIBRARY_DEFAULT_PNG" 2>/dev/null || true
    chmod 644 "$LIBRARY_DEFAULT_PNG" 2>/dev/null || true

    # Waypaper config — so waypaper --restore / update-sddm without args match.
    if [[ -f "$WAYPAPER_INI" ]]; then
        if grep -q '^wallpaper[[:space:]]*=' "$WAYPAPER_INI" 2>/dev/null; then
            sed -i "s|^wallpaper[[:space:]]*=.*|wallpaper = $WALLPAPER|" "$WAYPAPER_INI"
        else
            printf '\nwallpaper = %s\n' "$WALLPAPER" >>"$WAYPAPER_INI"
        fi
    fi

    if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
        mkdir -p "$HOME/.config/hypr/hyprlock" 2>/dev/null || true
        ln -sfn "$DEFAULT_WP_PNG" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null || true
    fi
else
    if [[ -f "$HOME/.config/hypr/hyprland.lua" ]]; then
        ln -sf "$WALLPAPER" "$HOME/.config/hypr/hyprlock/wallpaper" 2>/dev/null || true
    fi
fi

printf '%s\n' "$WALLPAPER"