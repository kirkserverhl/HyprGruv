#!/usr/bin/env bash
# palette-choose.sh
#
# Visual swatch-based source color chooser for matugen.
# Gives you real choice instead of one "best" color.
#
# - Extracts 8 high-quality candidate source colors for the current wallpaper
# - Shows them as nice color swatches + hex in a clean rofi list
# - Selecting one applies it immediately via `matugen color hex`
#
# This is the "I want to pick one of the good palettes" tool you described.
#
# Usage:
#   palette-choose.sh
#   (or bind it to a key / rofi launcher)

set +e

CURRENT_WP_CACHE="$HOME/.config/last_wallpaper.txt"
DEFAULT_WP="$HOME/Pictures/Wallpapers/gruvbox_image46.png"

if [[ -f "$CURRENT_WP_CACHE" ]]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
elif [ -f "$HOME/.config/settings/default" ]; then
    WALLPAPER=$(cat "$HOME/.config/settings/default")
fi
[[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]] && WALLPAPER="$DEFAULT_WP"

EXTRACTOR="$HOME/.config/hyprgruv/scripts/extract-good-source-colors.sh"
SWATCH_DIR=$(mktemp -d /tmp/palette-choose-XXXXXX)
trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT

# Get more choices (8 gives good selection without overwhelming)
echo "Extracting good source colors for $(basename "$WALLPAPER")..."
mapfile -t COLORS < <("$EXTRACTOR" "$WALLPAPER" 8 2>/dev/null)

# Pad if needed
while [ ${#COLORS[@]} -lt 4 ]; do
    COLORS+=("#4a5568")
done
COLORS=("${COLORS[@]:0:8}")

# Generate swatch icons (small colored squares + optional label strip)
for i in "${!COLORS[@]}"; do
    hex="${COLORS[$i]}"
    swatch="$SWATCH_DIR/swatch-$i.png"
    # Nice 48x48 solid color with subtle border
    magick -size 48x48 "xc:$hex" \
           -bordercolor "#222222" -border 2 \
           -quality 92 "$swatch" 2>/dev/null || \
    magick -size 48x48 xc:"#333333" "$swatch"
done

# Build rofi input: "icon\0icon\x1fpath\n" + text with hex
input=""
for i in "${!COLORS[@]}"; do
    hex="${COLORS[$i]}"
    swatch="$SWATCH_DIR/swatch-$i.png"
    # Format: show the color + hex. User can fuzzy search by hex or just visually pick.
    label="$(printf '%s  %s' "$hex" "source color $((i+1))")"
    input+="${label}\0icon\x1f${swatch}\n"
done

# Use a clean theme (falls back to default if your custom one isn't perfect)
THEME="$HOME/.config/rofi/config-matugen-chooser.rasi"
[[ -f "$THEME" ]] || THEME=""

chosen=$(printf '%b' "$input" | \
    rofi -dmenu -i -show-icons \
         -p "Pick source color for $(basename "$WALLPAPER")" \
         -theme "$THEME" \
         -theme-str 'listview { lines: 10; } element-icon { size: 28px; }' \
         -no-custom 2>/dev/null || true)

[[ -z "$chosen" ]] && exit 0

# Extract the hex from the chosen line (first 7 chars after possible icon stuff)
CHOSEN_HEX=$(echo "$chosen" | grep -oE '#[0-9A-Fa-f]{6}' | head -1)

if [[ -z "$CHOSEN_HEX" ]]; then
    # Fallback: try to match by index in the label
    for i in "${!COLORS[@]}"; do
        if [[ "$chosen" == *"${COLORS[$i]}"* ]]; then
            CHOSEN_HEX="${COLORS[$i]}"
            break
        fi
    done
fi

[[ -z "$CHOSEN_HEX" ]] && exit 0

echo "Applying: $CHOSEN_HEX"
matugen color hex "$CHOSEN_HEX" --mode dark --type scheme-tonal-spot 2>/dev/null || true

# Make sure waybar and others notice
pkill -SIGUSR2 waybar 2>/dev/null || true

notify-send -a matugen "Palette" "Applied $CHOSEN_HEX" 2>/dev/null || true
