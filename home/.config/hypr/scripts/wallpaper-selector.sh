#!/bin/bash

COLORSCHEMES_DIR="$HOME/.config/colorschemes"
WALLPAPER_STATE="$COLORSCHEMES_DIR/.wallpaper-state"
CURRENT_THEME_FILE="$COLORSCHEMES_DIR/.current-theme"

# Get current theme
if [ ! -f "$CURRENT_THEME_FILE" ]; then
    notify-send "Error" "No theme currently active"
    exit 1
fi

CURRENT_THEME=$(cat "$CURRENT_THEME_FILE")
WALLPAPER_DIR="$COLORSCHEMES_DIR/$CURRENT_THEME/wallpapers"

if [ ! -d "$WALLPAPER_DIR" ]; then
    notify-send "Error" "No wallpapers directory found for theme: $CURRENT_THEME"
    exit 1
fi

# Get list of wallpapers
mapfile -t wallpapers < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.svg" \) | sort)

if [ ${#wallpapers[@]} -eq 0 ]; then
    notify-send "Error" "No wallpapers found in $WALLPAPER_DIR"
    exit 1
fi

# Get currently selected wallpaper
CURRENT_WALLPAPER=$(grep "^$CURRENT_THEME:" "$WALLPAPER_STATE" 2>/dev/null | cut -d':' -f2-)

# === Portrait thumbnail generation for proper "fill + crop" previews ===
THUMB_DIR="$HOME/.cache/wallpaper-previews"
THUMB_SIZE="170x226"   # portrait, sized to match ~155px displayed icons in the 4x3 matugen grid (good quality after downscale)

get_thumb() {
    local orig="$1"
    local theme="$2"
    local hash
    hash=$(echo -n "$orig|$THUMB_SIZE" | md5sum | cut -d' ' -f1)
    local thumb_dir="$THUMB_DIR/$theme"
    local thumb="$thumb_dir/${hash}.jpg"
    mkdir -p "$thumb_dir"

    if [ ! -f "$thumb" ] || [ "$orig" -nt "$thumb" ]; then
        # Resize + ^ (fill) + center crop + extent = object-fit: cover behavior
        if ! magick "$orig" -resize "${THUMB_SIZE}^" -gravity center -extent "$THUMB_SIZE" -quality 85 "$thumb" 2>/dev/null; then
            # Fallback: just copy original if conversion fails (SVG etc.)
            cp "$orig" "$thumb" 2>/dev/null || true
        fi
    fi
    echo "$thumb"
}

# Build menu with icon paths for rofi (using cropped portrait thumbs)
# Clean names only — no polluting prefixes. Current wallpaper is tracked in state.
menu_options=""
for wp in "${wallpapers[@]}"; do
    basename_wp=$(basename "$wp")
    thumb_path=$(get_thumb "$wp" "$CURRENT_THEME")
    menu_options+="$basename_wp\0icon\x1f$thumb_path\n"
done

# Show rofi with icons (matugen-themed, 4x3 minimal grid)
selected=$(echo -en "$menu_options" | rofi -dmenu -i -p "Wallpaper" -show-icons -theme ~/.local/share/rofi/themes/wallpapers.rasi)

if [ -z "$selected" ]; then
    exit 0
fi

# No prefix stripping needed anymore (was broken: used "| " but stripped "● ")

# Find the full path
selected_path=""
for wp in "${wallpapers[@]}"; do
    if [ "$(basename "$wp")" = "$selected" ]; then
        selected_path="$wp"
        break
    fi
done

if [ -z "$selected_path" ]; then
    notify-send "Error" "Could not find selected wallpaper"
    exit 1
fi

# Apply wallpaper with wipe transition
swww img "$selected_path" --transition-type wipe --transition-fps 144 --transition-step 255

# Update state file
touch "$WALLPAPER_STATE"
sed -i "/^$CURRENT_THEME:/d" "$WALLPAPER_STATE"
echo "$CURRENT_THEME:$selected_path" >> "$WALLPAPER_STATE"

# Update hyprlock symlink
ln -sf "$selected_path" ~/.config/hypr/hyprlock/wallpaper

notify-send "Wallpaper Changed" "Applied: $selected"
