#!/bin/bash
# =============================================
# Hyprland Wallpaper Processor
# Generates cached versions (blurred, square, effects)
# and updates colors + waypaper
# =============================================

# ------------------- Config -------------------
GENERATED_DIR="$HOME/.config/settings/cache/wallpaper-generated"
CACHE_DIR="$HOME/.config/settings/cache"
CURRENT_WP_CACHE="$CACHE_DIR/current_wallpaper"
BLURRED_WP="$CACHE_DIR/blurred_wallpaper.png"
SQUARE_WP="$CACHE_DIR/square_wallpaper.png"
RASI_FILE="$CACHE_DIR/current_wallpaper.rasi"
WAYPAPER_RUNNING="$CACHE_DIR/waypaper-running"

DEFAULT_WP="$HOME/Pictures/Wallpapers/default.jpg"
BLUR_FILE="$HOME/.config/hypr/scripts/settings/blur.sh"
EFFECT_FILE="$HOME/.config/settings/wallpaper-effect.sh"

# Create directories if missing
mkdir -p "$GENERATED_DIR" "$CACHE_DIR"

# ------------------- Cache flag -------------------
if [ -f "$HOME/.config/settings/wallpaper_cache" ]; then
    USE_CACHE=1
    echo ":: Using wallpaper cache"
else
    USE_CACHE=0
    echo ":: Wallpaper cache disabled"
fi

# Prevent multiple runs
if [ -f "$WAYPAPER_RUNNING" ]; then
    rm -f "$WAYPAPER_RUNNING"
    exit 0
fi

# ------------------- Get wallpaper -------------------
if [ -n "$1" ]; then
    WALLPAPER="$1"
elif [ -f "$CURRENT_WP_CACHE" ]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
else
    WALLPAPER="$DEFAULT_WP"
fi

echo ":: Setting wallpaper: $WALLPAPER"
echo "$WALLPAPER" >"$CURRENT_WP_CACHE"

WP_FILENAME=$(basename "$WALLPAPER")
TMP_WP="$WALLPAPER"

# ------------------- Load blur setting -------------------
if [ -f "$BLUR_FILE" ]; then
    blur=$(cat "$BLUR_FILE" | tr -d ' \t\n')
else
    blur="50x30"
fi

# ------------------- Wallpaper Effects -------------------
EFFECT="off"
if [ -f "$EFFECT_FILE" ]; then
    EFFECT=$(cat "$EFFECT_FILE" | tr -d ' \t\n')
fi

if [ "$EFFECT" != "off" ] && [ -f "$HOME/.config/hypr/effects/wallpaper/$EFFECT" ]; then
    USED_WP="$GENERATED_DIR/$EFFECT-$WP_FILENAME"

    if [ -f "$USED_WP" ] && [ "$USE_CACHE" = "1" ]; then
        echo ":: Using cached effect: $EFFECT-$WP_FILENAME"
    else
        echo ":: Generating new effect: $EFFECT"
        notify-send "Wallpaper Effect" "Applying $EFFECT to $WP_FILENAME" -h int:value:40
        source "$HOME/.config/hypr/effects/wallpaper/$EFFECT"
    fi
else
    USED_WP="$WALLPAPER"
fi

# Set the wallpaper via waypaper
touch "$WAYPAPER_RUNNING"

# ------------------- Color generation -------------------
echo ":: Running pywal..."
wal -q -i "$USED_WP"

echo ":: Running matugen..."
if command -v matugen >/dev/null 2>&1; then
    matugen image "$USED_WP" --mode dark 2>&1 | tee -a ~/.cache/matugen.log
    echo ":: Matugen completed (dark mode)"
else
    echo ":: Warning: matugen command not found"
fi

# Optional: Notify that Yazi needs restart
notify-send "Theme Updated" "Matugen colors applied.\nRestart Yazi (press Q then reopen) to see changes." -i preferences-desktop-theme

# Optional pywalfox
if command -v pywalfox >/dev/null 2>&1; then
    pywalfox update
fi

# ------------------- Blurred version -------------------
BLUR_FILENAME="blur-${blur}-${EFFECT}-${WP_FILENAME%.*}.png"

if [ -f "$GENERATED_DIR/$BLUR_FILENAME" ] && [ "$USE_CACHE" = "1" ]; then
    echo ":: Using cached blurred version"
else
    echo ":: Generating blurred version ($blur)"
    magick "$USED_WP" -resize 75% "$BLURRED_WP"
    if [ "$blur" != "0x0" ]; then
        magick "$BLURRED_WP" -blur "$blur" "$BLURRED_WP"
    fi
    cp "$BLURRED_WP" "$GENERATED_DIR/$BLUR_FILENAME"
fi

cp "$GENERATED_DIR/$BLUR_FILENAME" "$BLURRED_WP" 2>/dev/null || true

# ------------------- Rasi file for rofi/etc -------------------
echo "* { current-image: url(\"$BLURRED_WP\", height); }" >"$RASI_FILE"

# ------------------- Square version -------------------
echo ":: Generating square version"
magick "$TMP_WP" -gravity Center -extent 1:1 "$SQUARE_WP"
cp "$SQUARE_WP" "$GENERATED_DIR/square-$WP_FILENAME.png"

echo ":: Wallpaper processing complete!"

if [ ! -f "$TMP_WP" ]; then
    echo "Error: Source image $TMP_WP does not exist!"
    exit 1
fi
