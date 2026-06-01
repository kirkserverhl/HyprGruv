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

# --- Pop out in floating window (same mechanism as unlockroot.sh, htop.sh, etc.) ---
CLASS="dotfiles-floating"
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

if [[ -z "${PALETTE_INSIDE:-}" ]]; then
    export PALETTE_INSIDE=1
    # Use -e + explicit column size for reliable floating pop-out (same pattern as other tools).
    # The Hyprland windowrule below will enforce the final pixel size + centering.
    # 70c is a good starting point for the compact color preview content.
    # Change this number (e.g. 65c or 75c) to tune the width to your liking.
    exec "${CLEAN_ENV[@]}" kitty \
        --class "$CLASS" \
        --title "Color Palette" \
        --override initial_window_width=70c \
        --override initial_window_height=24c \
        -e "$0" "$@"
fi

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

# Force the terminal title from inside the script as early as possible.
# This guarantees the Hyprland windowrule (which keys on title) will match reliably.
printf '\e]2;Color Palette\a' 2>/dev/null || true

# Note: We intentionally do not use set -euo pipefail for the main body.
# gum, matugen, and some of the wallpaper detection commands can return
# non-zero in normal interactive use and would kill the script.

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
        "None - Transparent bar + bright text (light font)" \
        "None - Transparent bar + dark text" \
        "None - Plain text only (no matugen at all)" \
        "Dark - Standard (tonal spot)" \
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

        "None - Transparent bar + bright text (light font)")
            echo
            echo "Transparent bar + brightest text color from matugen (light font on see-through bar)"
            mkdir -p "$HOME/.cache/matugen"
            touch "$HOME/.cache/matugen/waybar-transparent-bright"
            echo "→ Marker set for transparent bar + bright text. Will be applied on wallpaper change."
            sleep 0.6
            exit 0
            ;;

        "None - Transparent bar + dark text")
            echo
            echo "Transparent bar + darkest text color from matugen"
            mkdir -p "$HOME/.cache/matugen"
            touch "$HOME/.cache/matugen/waybar-transparent-dark"
            echo "→ Marker set for transparent bar + dark text. Will be applied on wallpaper change."
            sleep 0.6
            exit 0
            ;;

        "None - Plain text only (no matugen at all)")
            echo
            echo "Extracting raw dominant colors (no matugen processing):"
            echo "Wallpaper: $WP_NAME"
            echo

            if ! command -v matugen >/dev/null 2>&1; then
                echo "Error: matugen is not installed."
                read -r -p "Press Enter to return to menu..."
                continue
            fi

            # Get colors as plain text only — no colored backgrounds from --show-colors
            RAW_JSON=$(matugen image "$WALLPAPER" --mode dark --json hex 2>/dev/null || true)

            if [[ -n "$RAW_JSON" ]]; then
                echo "Hex          Name"
                echo "────────────────────────────"
                echo "$RAW_JSON" | jq -r '
                    .colors.default
                    | to_entries[]
                    | "\(.value.hex)   \(.key)"
                ' | sort
            else
                echo "Could not extract colors from matugen."
            fi

            echo

            # Clean, utility-style notice (no fancy styling)
            echo "────────────────────────────────────────"
            echo "  NO MATUGEN THEMING SELECTED"
            echo "────────────────────────────────────────"
            echo
            echo "  This wallpaper will use its original colors."
            echo "  No generated palettes or backgrounds will be applied."
            echo
            echo "  Press Enter to apply and close this window."
            echo "────────────────────────────────────────"

            echo
            while true; do
                read -rsn1 key
                if [[ -z "$key" ]]; then
                    echo
                    echo "→ No Matugen will be applied."
                    mkdir -p "$HOME/.cache/matugen"
                    touch "$HOME/.cache/matugen/no-matugen-this-time"
                    sleep 0.4
                    exit 0
                elif [[ "$key" =~ [qQ] ]]; then
                    echo "Returning to menu..."
                    break
                fi
            done
            continue
            ;;

        "Dark - Standard (tonal spot)")
            MODE="--mode dark"
            TYPE="--type scheme-tonal-spot"
            LABEL="Dark (Standard)"
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
    echo "Press [Enter] to apply this style and close, or [q] to exit without applying"
    while true; do
        read -rsn1 key
        if [[ -z "$key" ]]; then
            # Enter → actually apply the chosen scheme (this is what updates all templates + waybar)
            echo "Applying $LABEL..."
            matugen image "$WALLPAPER" $MODE $TYPE 2>&1 | tail -5
            echo "✓ $LABEL applied"
            sleep 0.6
            exit 0
        elif [[ "$key" =~ [qQ] ]]; then
            echo "Exiting without applying."
            exit 0
        fi
    done
done

echo
echo "Done."