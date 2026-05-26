#!/bin/bash
# ===================================================================
# Rofi Wallpaper Selector — robust version for Waypaper + Matugen
# 
# - Uses waypaper --wallpaper so the post-command (set_wallpaper.sh)
#   always runs for colors, waybar, caches, rofi rasi bg, etc.
# - Defaults to wallSelect.rasi (the classic grid look you had before)
# - Falls back gracefully if you want the blurred-bg "config-wallpaper" style
# - Properly handles subfolders and duplicate basenames
# - Fixed the "could not resolve selected wallpaper" bug
# ===================================================================

set -euo pipefail

# Guard so the script can be sourced for debugging without executing the picker
if [[ "${BASH_SOURCE[0]}" != "$0" ]]; then
    return 0 2>/dev/null || true
fi

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"

# === Choose your preferred look ===
# 3 rows × 4 columns image grid using matugen colors + blurred wallpaper background
THEME="$HOME/.config/rofi/themes/wallSelect.rasi"

# Alternative style:
# THEME="$HOME/.config/rofi/config-wallpaper.rasi"

WAYPAPER_CMD="${HOME}/.local/bin/waypaper"
if [ ! -x "$WAYPAPER_CMD" ]; then
    WAYPAPER_CMD="waypaper"
fi

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Wallpaper Selector" "Directory not found: $WALLPAPER_DIR"
    exit 1
fi

# Toggle behavior
if pidof rofi >/dev/null 2>&1; then
    pkill rofi
    exit 0
fi

# Collect images (recursive to match Waypaper subfolders=True)
mapfile -t -d '' ALL_PICS < <(find -L "$WALLPAPER_DIR" -type f \
    \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
       -o -iname '*.gif' -o -iname '*.webp' \) -print0 | sort -z)

if ((${#ALL_PICS[@]} == 0)); then
    notify-send "Wallpaper Selector" "No images found in $WALLPAPER_DIR"
    exit 1
fi

# Build mapping + rofi input safely (no huge NUL-containing variable)
MAP_FILE=$(mktemp)
ROFI_INPUT=$(mktemp)
PLACEHOLDER_DIR="/tmp/rofi-wallpaper-placeholders-$$"
mkdir -p "$PLACEHOLDER_DIR"
trap 'rm -f "$MAP_FILE" "$ROFI_INPUT"; rm -rf "$PLACEHOLDER_DIR"' EXIT

RANDOM_LABEL="[ Random Wallpaper ]"
GUI_LABEL="[ Open Waypaper GUI ]"

# Create small placeholder icons for the special entries so they render as clean image cards
# (no long text labels because element-text is disabled in the theme)
if command -v magick >/dev/null 2>&1; then
    magick -size 185x185 xc:'#222222' \
           -fill '#aaaaaa' -gravity center -pointsize 64 -annotate 0 '⟳' \
           "$PLACEHOLDER_DIR/random.png" 2>/dev/null || true

    magick -size 185x185 xc:'#222222' \
           -fill '#aaaaaa' -gravity center -pointsize 42 -annotate 0 'GUI' \
           "$PLACEHOLDER_DIR/gui.png" 2>/dev/null || true
fi

# Write header entries to map (no | for these special ones)
printf '%s\n' "$RANDOM_LABEL" >> "$MAP_FILE"
printf '%s\n' "$GUI_LABEL" >> "$MAP_FILE"

# Attach placeholder icons so the long labels are suppressed (element-text is disabled)
printf '%s\0icon\x1f%s\n' "$RANDOM_LABEL" "$PLACEHOLDER_DIR/random.png" >> "$ROFI_INPUT"
printf '%s\0icon\x1f%s\n' "$GUI_LABEL" "$PLACEHOLDER_DIR/gui.png" >> "$ROFI_INPUT"

# Track seen basenames for disambiguation
declare -A SEEN

for pic in "${ALL_PICS[@]}"; do
    base=$(basename "$pic")
    display="$base"

    # If basename collision (common with subfolders), disambiguate
    if [[ -n "${SEEN[$base]:-}" ]]; then
        rel_dir=$(realpath --relative-to="$WALLPAPER_DIR" "$(dirname "$pic")")
        if [[ "$rel_dir" != "." && "$rel_dir" != "" ]]; then
            display="$base ($rel_dir)"
        else
            display="$base (${SEEN[$base]})"
        fi
    fi
    SEEN[$base]=$(( ${SEEN[$base]:-0} + 1 ))

    # Map file: display|fullpath   (use | as delimiter, safe for filenames)
    printf '%s|%s\n' "$display" "$pic" >> "$MAP_FILE"

    # Rofi input with icon syntax (real NUL byte via printf)
    printf '%s\0icon\x1f%s\n' "$display" "$pic" >> "$ROFI_INPUT"
done

# Launch rofi
CHOICE=$(cat "$ROFI_INPUT" | rofi -dmenu -i -p "Wallpaper" \
    -theme "$THEME" -no-fixed-num-lines 2>/dev/null || true)

if [[ -z "$CHOICE" ]]; then
    exit 0
fi

# Resolve the choice
if [[ "$CHOICE" == "$RANDOM_LABEL" ]]; then
    # Pick a random real wallpaper (skip the two special lines)
    SELECTED_PATH=$(tail -n +3 "$MAP_FILE" | shuf -n 1 | cut -d'|' -f2-)
elif [[ "$CHOICE" == "$GUI_LABEL" ]]; then
    exec "$WAYPAPER_CMD"
else
    # Normal selection: lookup in map
    LINE=$(grep -F -- "$CHOICE|" "$MAP_FILE" | head -n1 || true)
    if [[ -z "$LINE" ]]; then
        notify-send "Wallpaper Selector" "Could not resolve: $CHOICE"
        exit 1
    fi
    SELECTED_PATH="${LINE#*|}"
fi

if [[ -z "$SELECTED_PATH" || ! -f "$SELECTED_PATH" ]]; then
    notify-send "Wallpaper Selector" "Could not resolve selected wallpaper"
    exit 1
fi

# Apply through Waypaper so the full post script runs (Matugen, Waybar, caches, etc.)
notify-send "Wallpaper" "Applying: $(basename "$SELECTED_PATH")" -t 1200

if ! "$WAYPAPER_CMD" --wallpaper "$SELECTED_PATH" 2>/dev/null; then
    # Fallback direct (rare)
    if command -v swww >/dev/null 2>&1; then
        swww img "$SELECTED_PATH"
    elif command -v awww >/dev/null 2>&1; then
        awww "$SELECTED_PATH"
    fi
    "$HOME/.config/hypr/scripts/set_wallpaper.sh" "$SELECTED_PATH" || true
fi
