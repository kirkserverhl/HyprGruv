#!/usr/bin/env bash
# rofi-palette.sh
#
# Single screen: clean 2x2 grid of 4 reliable source colors.
# Uses the saturation-aware extractor so you don't get grey palettes.
#
# Picks one → applies via `matugen color hex` (bypasses image analysis).

set +e

CURRENT_WP_CACHE="$HOME/.config/settings/cache/current_wallpaper"
DEFAULT_WP="$HOME/Pictures/Wallpapers/gruvbox_image46.png"

if [[ -f "$CURRENT_WP_CACHE" ]]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
elif [ -f "$HOME/.config/settings/default" ]; then
    WALLPAPER=$(cat "$HOME/.config/settings/default")
elif command -v hyprctl &>/dev/null; then
    WALLPAPER=$(hyprctl hyprpaper listactive 2>/dev/null | awk -F' = ' '{print $2}' | head -1 || true)
fi
[[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]] && WALLPAPER="$DEFAULT_WP"

EXTRACTOR="$HOME/.config/hypr/scripts/extract-good-source-colors.sh"

SWATCH_DIR=$(mktemp -d /tmp/rofi-palette-swatches-XXXXXX)
trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT

# ============================================
# Get 4 confident source colors (no monochrome!)
# ============================================
echo "Extracting 4 good source colors..."

mapfile -t COLORS < <("$EXTRACTOR" "$WALLPAPER" 2>/dev/null | head -4)

# Safety fallback
while [ ${#COLORS[@]} -lt 4 ]; do
    COLORS+=("#5a6a7a")
done
COLORS=("${COLORS[@]:0:4}")

# Generate nice 2x2 swatches from the 4 good colors
for i in 0 1 2 3; do
    hex="${COLORS[$i]}"
    swatch="$SWATCH_DIR/swatch-$i.png"

    if ! magick -size 240x135 "xc:$hex" -alpha off png32:"$swatch" 2>/dev/null; then
        magick -size 240x135 xc:"#3a3a3a" -alpha off png32:"$swatch"
    fi

    if [ ! -s "$swatch" ] || [ "$(stat -c%s "$swatch" 2>/dev/null || echo 0)" -lt 180 ]; then
        magick -size 240x135 xc:"#3a3a3a" -alpha off png32:"$swatch"
    fi
done

color_input=""
for i in 0 1 2 3; do
    swatch="$SWATCH_DIR/swatch-$i.png"
    [[ -f "$swatch" ]] && color_input+="\0icon\x1f${swatch}\n" || color_input+="\n"
done

chosen=$(printf '%b' "$color_input" | \
    rofi -dmenu -i -show-icons \
         -p "" \
         -theme "$HOME/.config/rofi/color-grid.rasi" \
         -no-custom 2>&1)
rofi_status=$?
if [ $rofi_status -ne 0 ] && [ $rofi_status -ne 1 ]; then
    echo "Rofi color splotches error (status $rofi_status):" >&2
    echo "$chosen" >&2
    exit 0
fi

[[ -z "$chosen" ]] && exit 0

# Figure out which color was picked
INDEX=0
for i in 0 1 2 3; do
    if [[ "$chosen" == *"swatch-$i.png"* ]]; then
        INDEX=$i
        break
    fi
done

CHOSEN_HEX="${COLORS[$INDEX]}"

# Apply using the chosen color directly — this is the reliable path
echo "Applying matugen with source color: $CHOSEN_HEX"
matugen color hex "$CHOSEN_HEX" --mode dark 2>/dev/null || true

pkill -SIGUSR2 waybar 2>/dev/null || true

exit 0
