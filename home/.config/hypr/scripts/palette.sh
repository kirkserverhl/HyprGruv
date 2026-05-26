#!/usr/bin/env bash
# palette.sh — Preview matugen color palettes from your current wallpaper
#
# Usage:
#   palette
#
# Features:
# - Automatically uses your current wallpaper
# - Loopable menu: try as many styles as you want
# - Clear "Exit" option to leave
# - Uses your existing theming helpers (header + colors)

set -euo pipefail

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

# --- Find current wallpaper (your reliable cache) ---
CURRENT_WP_CACHE="$HOME/.config/settings/cache/current_wallpaper"
DEFAULT_WP="$HOME/Pictures/Wallpapers/gruvbox_image46.png"

if [[ -f "$CURRENT_WP_CACHE" ]]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
elif command -v hyprctl &>/dev/null; then
    WALLPAPER=$(hyprctl hyprpaper listactive 2>/dev/null | awk -F' = ' '{print $2}' | head -1 || true)
fi

if [[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]]; then
    echo ":: Could not determine current wallpaper. Using fallback."
    WALLPAPER="$DEFAULT_WP"
fi

WP_NAME=$(basename "$WALLPAPER")

# --- Main loop ---
while true; do
    clear

    print_header "Palette"
    echo "Current wallpaper: $WP_NAME"
    echo

    # Menu with clear exit option
    choice=$(gum choose \
        "Dark - Standard (tonal spot)" \
        "Light - Standard" \
        "Dark - Vibrant" \
        "Dark - Monochrome" \
        "Exit" \
        --header "Choose a style to preview (or Exit):")

    # Handle cancel (Esc / Ctrl+C in gum)
    if [[ -z "$choice" ]]; then
        echo "Cancelled."
        break
    fi

    case "$choice" in
        "Exit")
            echo
            echo "Exiting palette viewer."
            break
            ;;
        "Dark - Standard (tonal spot)")
            MODE="--mode dark"
            TYPE="--type scheme-tonal-spot"
            LABEL="Dark (Standard)"
            ;;
        "Light - Standard")
            MODE="--mode light"
            TYPE="--type scheme-tonal-spot"
            LABEL="Light (Standard)"
            ;;
        "Dark - Vibrant")
            MODE="--mode dark"
            TYPE="--type scheme-vibrant"
            LABEL="Dark - Vibrant"
            ;;
        "Dark - Monochrome")
            MODE="--mode dark"
            TYPE="--type scheme-monochrome"
            LABEL="Dark - Monochrome"
            ;;
        *)
            echo "Unknown option"
            continue
            ;;
    esac

    echo
    echo "Generating: $LABEL"
    echo "Wallpaper : $WP_NAME"
    echo

    if ! command -v matugen >/dev/null 2>&1; then
        echo "Error: matugen is not installed."
        read -r -p "Press Enter to return to menu..."
        continue
    fi

    matugen image "$WALLPAPER" $MODE $TYPE --show-colors

    echo
    gum style --bold --foreground 6 "✓ Shown: $LABEL"
    echo
    read -r -p "Press Enter to choose another style (or select Exit above)..."
done

echo
echo "Done."