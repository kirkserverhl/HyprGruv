#!/usr/bin/env bash
# rofi-choose-matugen-style.sh
#
# Shows two clean Rofi menus (using the shared matugen-aware theme):
#   1. Matugen palette style (mode + type)
#   2. Source color index (0-3) with visual color swatches
#
# These menus are called from set_wallpaper.sh (Waypaper post-command)
# BEFORE the new blurred wallpaper and current_wallpaper.rasi are generated.
#
# The theme (config-matugen-chooser.rasi) deliberately does NOT import
# current_wallpaper.rasi, so we never show the old/stale blurred wallpaper.
#
# It matches the visual language (font, colors, rounding, border) of
# wallSelect.rasi / the other modern rofi menus in this setup.
#
# Usage:
#   chosen_args=$(~/.config/hyprgruv/scripts/rofi-choose-matugen-style.sh "/path/to/wallpaper.png")
#
# Output example:
#   "--mode dark --type scheme-vibrant --source-color-index 2"
#
# Exits with 1 if the user cancelled either menu.

set -euo pipefail

WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Error: No valid wallpaper path provided" >&2
    exit 1
fi

# ------------------------------------------------------------------
# Shared clean theme (no blurred wallpaper background, matches wallSelect)
# ------------------------------------------------------------------
CHOOSER_THEME="$HOME/.config/rofi/config-matugen-chooser.rasi"

# ------------------------------------------------------------------
# Step 1: Choose palette style (mode + type)
# ------------------------------------------------------------------
style_options=(
    "Dark - Standard (tonal spot)"
    "Dark - Vibrant"
    "Dark - Monochrome"
    "· Common themes ·"
    "Gruvbox"
    "Catppuccin"
    "Everforest"
    "Nord"
    "Cancel"
)

# Small per-menu tweaks only (the base theme already has the real styling)
STYLE_THEME_STR='
    window { width: 380px; height: 400px; }
    listview { lines: 9; }
    prompt { enabled: false; }
    inputbar { enabled: false; }
'

while true; do
    style_selected=$(printf '%s\n' "${style_options[@]}" | \
        rofi -dmenu -i \
            -p "" \
            -theme "$CHOOSER_THEME" \
            -theme-str "$STYLE_THEME_STR" \
            -no-custom \
            2>/dev/null || true)

    if [[ -z "$style_selected" || "$style_selected" == "Cancel" ]]; then
        exit 1
    fi

    case "$style_selected" in
        "· Common themes ·")
            continue
            ;;
        "Gruvbox"|"Catppuccin"|"Everforest"|"Nord")
            timeout 1 notify-send -a matugen "Coming soon" \
                "$style_selected theme switching is not wired up yet." 2>/dev/null || true
            continue
            ;;
        "Dark - Standard (tonal spot)")
            MODE="--mode dark"
            TYPE="--type scheme-tonal-spot"
            break
            ;;
        "Dark - Vibrant")
            MODE="--mode dark"
            TYPE="--type scheme-vibrant"
            break
            ;;
        "Dark - Monochrome")
            MODE="--mode dark"
            TYPE="--type scheme-monochrome"
            break
            ;;
    esac
done

# ------------------------------------------------------------------
# Step 2: Choose source color index (0-3) with visual swatches
# ------------------------------------------------------------------
# We generate real color swatches so the user can *see* the color.
# The theme supports show-icons + element-icon sizing.

# Small per-menu tweaks for the color swatch menu
COLOR_THEME_STR='
    window { width: 460px; height: 340px; }
    listview { lines: 6; }
    element-icon { size: 26px; margin: 0 10px 0 4px; }
    prompt { str: "Source color (drives the palette)"; }
'

# Use the reliable saturation-aware extractor for the 4 swatches shown to the user.
# This prevents the "all grey" problem in the source color picker.
EXTRACTOR="$HOME/.config/hyprgruv/scripts/extract-good-source-colors.sh"
if [[ -x "$EXTRACTOR" ]]; then
    mapfile -t COLORS < <("$EXTRACTOR" "$WALLPAPER" 2>/dev/null | head -4)
else
    # Fallback (old naive method)
    mapfile -t COLORS < <(
        magick "$WALLPAPER" -resize '400x400>' -modulate 100,160,100 -colors 12 +dither -unique-colors txt:- 2>/dev/null \
        | grep -oP '#[0-9A-Fa-f]{6}' | head -4 || true
    )
fi
while [ ${#COLORS[@]} -lt 4 ]; do COLORS+=("#5a6a7a"); done
COLORS=("${COLORS[@]:0:4}")

# Temporary directory for the swatch icons (cleaned on exit)
SWATCH_DIR=$(mktemp -d /tmp/matugen-swatches-XXXXXX)
trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT

# Build rofi input lines with icon protocol for actual color splotches
color_input=""
for i in 0 1 2 3; do
    if [[ -n "${COLORS[$i]:-}" ]]; then
        hex="${COLORS[$i]}"
        swatch="$SWATCH_DIR/swatch-${i}.png"

        # Nice solid color square with subtle border (matches the theme's surface)
        magick -size 48x48 xc:"$hex" \
               -bordercolor "#2a2a2a" -border 3 \
               -quality 95 "$swatch" 2>/dev/null || continue

        label="$i — $hex"
        color_input+="${label}\0icon\x1f${swatch}\n"
    else
        color_input+="${i}\n"
    fi
done

# Always offer the safe default
color_input+="Use default (0)\n"

# Show the color picker
color_selected=$(printf '%b' "$color_input" | \
    rofi -dmenu -i -show-icons \
        -p "Source color for $(basename "$WALLPAPER")" \
        -theme "$CHOOSER_THEME" \
        -theme-str "$COLOR_THEME_STR" \
        -no-custom \
        2>/dev/null || true)

INDEX=0
if [[ -n "$color_selected" && "$color_selected" != "Use default (0)" ]]; then
    INDEX=$(echo "$color_selected" | grep -o '^[0-3]' || echo 0)
fi

# Final combined flags for matugen
echo "$MODE $TYPE --source-color-index $INDEX"
