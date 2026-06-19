#!/bin/bash
# ===================================================================
# Hyprland Wallpaper Post-Command for Waypaper (Matugen-focused)
# ===================================================================
# Primary color source: Matugen
#
# OVERHAUL GOAL (as clarified):
#   No pre-rendered blurred/cropped wallpaper variants are generated anymore.
#
#   SDDM (and anything else) reads the *central* default:
#     ~/.config/settings/default_wp.png
#   This file is kept fresh on every change (see the block below that runs
#   magick/cp to it). The update-sddm script mainly handles ACLs + color sync
#   into theme.conf and ensures the Background= lines point at the central path.
#
#   Everything else must use live layers + real-time blur:
#     - Wlogout → live screenshot + layerrule blur
#     - Hyprlock (via hypridle) → loads the raw wallpaper + its own blur
#
#   This keeps the system minimal and consistent.

set -uo pipefail

# ------------------- Paths -------------------
# shellcheck source=/home/kirk/.config/settings/wallpaper-paths.sh
source "$HOME/.config/settings/wallpaper-paths.sh"

GENERATED_DIR="$WALLPAPER_GENERATED_DIR"
CACHE_DIR="$WALLPAPER_CACHE_DIR"
CURRENT_WP_CACHE="$CURRENT_WALLPAPER_FILE"
WAYPAPER_LOCK="$WAYPAPER_LOCK_FILE"
DEFAULT_WP="$HOME/Pictures/Wallpapers/lady.png"
DEFAULT_WALLPAPER_FILE="$HOME/.config/settings/default"

# ------------------------------------------------------------------
# DISABLED: blurred + square/cropped wallpaper generation (no longer used).
# Rofi and other menus now use live compositor blur instead of pre-rendered assets.
# ------------------------------------------------------------------
# BLURRED_WALLPAPER="$BLURRED_WALLPAPER_FILE"
# SQUARE_WALLPAPER="$SQUARE_WALLPAPER_FILE"
# RASI_FILE="$ROFI_WALLPAPER_RASI_FILE"

WALLPAPER_EFFECT_FILE="$HOME/.config/settings/wallpaper-effect.sh"
# BLUR_FILE="$HOME/.config/settings/blur.sh"
USE_CACHE_FILE="$HOME/.config/settings/wallpaper_cache"

# ------------------- Defaults -------------------
# BLUR="50x30"
FORCE_GENERATE=0
USE_CACHE=0
# ------------------- Setup -------------------
mkdir -p "$GENERATED_DIR" "$CACHE_DIR"

# if [ -f "$BLUR_FILE" ]; then
#     BLUR=$(cat "$BLUR_FILE" | tr -d '[:space:]' | grep -oE '^[0-9]+x[0-9]+' || true)
# fi
# [ -z "$BLUR" ] && BLUR="20x8"   # sane default if file is empty/garbage

if [ -f "$USE_CACHE_FILE" ]; then
    USE_CACHE=1
    echo ":: Wallpaper cache enabled"
else
    echo ":: Wallpaper cache disabled"
fi

# ------------------- Lock Handling -------------------
if [ -f "$WAYPAPER_LOCK" ]; then
    if [ "$(find "$WAYPAPER_LOCK" -mmin +0.2 2>/dev/null)" ]; then
        echo ":: Stale lock found, removing..."
        rm -f "$WAYPAPER_LOCK"
    else
        echo ":: Another instance is running, exiting"
        exit 0
    fi
fi

touch "$WAYPAPER_LOCK"
release_lock() { rm -f "$WAYPAPER_LOCK"; }
trap release_lock EXIT

# ------------------- Determine Wallpaper -------------------
if [ -n "${1:-}" ]; then
    WALLPAPER="$1"
elif [ -f "$CURRENT_WP_CACHE" ]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
elif [ -f "$DEFAULT_WALLPAPER_FILE" ]; then
    WALLPAPER=$(cat "$DEFAULT_WALLPAPER_FILE")
else
    WALLPAPER="$DEFAULT_WP"
fi

echo "$WALLPAPER" > "$CURRENT_WP_CACHE"
echo "$WALLPAPER" > "$DEFAULT_WALLPAPER_FILE"
echo "$WALLPAPER" > "$HOME/.config/last_wallpaper.txt"
echo ":: Setting wallpaper: $WALLPAPER"

WALLPAPER_FILENAME=$(basename "$WALLPAPER")
USED_WALLPAPER="$WALLPAPER"

# ------------------------------------------------------------------
# Update the canonical default wallpaper image.
# SDDM (and any other tools) reference ONE stable path. The file at that
# path is refreshed on every wallpaper change.
# We always normalize to PNG here for maximum SDDM/Qt compatibility.
# Any input (jpg, png, webp, etc.) is converted losslessly enough via magick.
# This step requires no root privileges.
# ------------------------------------------------------------------
DEFAULT_WP_PNG="$HOME/.config/settings/default_wp.png"
if command -v magick >/dev/null 2>&1; then
    magick "$WALLPAPER" -strip -interlace none -quality 92 "$DEFAULT_WP_PNG" 2>/dev/null \
        || cp -f "$WALLPAPER" "$DEFAULT_WP_PNG"
else
    cp -f "$WALLPAPER" "$DEFAULT_WP_PNG"
fi
chmod 644 "$DEFAULT_WP_PNG" 2>/dev/null || true
echo ":: Updated canonical default (for SDDM etc.): $DEFAULT_WP_PNG"
# Optional: also keep the convenience sourcable script in sync if needed (it just points at the png)
source "$HOME/.config/settings/default_wp.sh" 2>/dev/null || true

# SDDM first — don't wait for matugen/color work to finish.
"$HOME/.config/hyprgruv/scripts/update-sddm-wallpaper.sh" "$WALLPAPER" || true

# ------------------- Wallpaper Effects -------------------
if [ -f "$WALLPAPER_EFFECT_FILE" ]; then
    EFFECT=$(cat "$WALLPAPER_EFFECT_FILE")
    if [ "$EFFECT" != "off" ] && [ -n "$EFFECT" ]; then
        EFFECTED_WP="$GENERATED_DIR/$EFFECT-$WALLPAPER_FILENAME"
        if [ -f "$EFFECTED_WP" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
            echo ":: Using cached effected wallpaper"
        else
            echo ":: Generating wallpaper effect '$EFFECT'..."
            wallpaper="$WALLPAPER"
            used_wallpaper="$EFFECTED_WP"
            if [ -f "$HOME/.config/hypr/effects/wallpaper/$EFFECT" ]; then
                source "$HOME/.config/hypr/effects/wallpaper/$EFFECT"
            else
                echo ":: Effect script not found, falling back"
                EFFECT="off"
            fi
        fi
        [ -f "$EFFECTED_WP" ] && USED_WALLPAPER="$EFFECTED_WP"
    else
        EFFECT="off"
    fi
else
    EFFECT="off"
fi

# ------------------- Preprocess for Matugen -------------------
# dipc outputs in ~/themed-wallpapers/ are already palette-filtered — pywal reads
# them directly. Raw photos still get a light posterize pass for Material You extraction.
SKIP_MATUGEN_PREPROCESS=0
if [[ "$WALLPAPER" == *"/themed-wallpapers/"* ]]; then
    SKIP_MATUGEN_PREPROCESS=1
elif [[ -f "$HOME/.cache/matugen/color-mode" ]] && [[ "$(tr -d '[:space:]' <"$HOME/.cache/matugen/color-mode")" == "wal" ]]; then
    SKIP_MATUGEN_PREPROCESS=1
fi

PREPROCESSED_WALLPAPER="$GENERATED_DIR/matugen-input-$WALLPAPER_FILENAME"

if [[ "$SKIP_MATUGEN_PREPROCESS" -eq 0 ]]; then
    if [ ! -f "$PREPROCESSED_WALLPAPER" ] || [ "$FORCE_GENERATE" -eq 1 ]; then
        echo ":: Preprocessing wallpaper for better Matugen color extraction..."
        magick "$WALLPAPER" \
          -modulate 100,115,100 \
          -posterize 12 \
          -contrast-stretch 0.5%x0.5% \
          -resize 1400x1400\> \
          "$PREPROCESSED_WALLPAPER"
    fi
else
    echo ":: Skipping matugen preprocess (dipc/pywal wallpaper)"
fi

# ------------------- Color Generation -------------------
echo ":: Running matugen via palette chooser (interactive)..."
# palette.sh is the same script bound to Ctrl+P in Hyprland. Waypaper's post_command
# and the theme-switcher wallpaper picker both land here after a wallpaper is chosen.

# shellcheck source=wallpaper-preset-scope.sh
source "$HOME/.config/hyprgruv/scripts/wallpaper-preset-scope.sh" 2>/dev/null || true

if [[ -f "$HOME/.config/colorschemes/.active-config" ]]; then
    CONFIG_NAME=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.active-config")
    echo ":: Saved config ($CONFIG_NAME) active — wallpaper only, colors unchanged"
elif [[ "${SET_WALLPAPER_FORCE_PALETTE:-0}" != "1" ]] && declare -F wallpaper_in_preset_scope >/dev/null 2>&1 && wallpaper_in_preset_scope "$WALLPAPER"; then
    CURRENT_THEME=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme")
    echo ":: Preset theme ($CURRENT_THEME) — applying saved palette (no re-extract)"
    bash "$HOME/.config/colorschemes/apply-preset-assets.sh" "$CURRENT_THEME" "$WALLPAPER" 2>/dev/null || true
elif command -v matugen >/dev/null 2>&1; then
    # Release lock before the floating kitty + gum UI so rapid GUI picks are not dropped.
    release_lock
    trap - EXIT

    echo ":: Launching palette chooser..."
    "$HOME/.config/hyprgruv/scripts/palette.sh" || true
fi


# ------------------- Clean defensive sync -------------------
echo ":: Ensuring waybar sees the latest colors..."

if [ -f "$HOME/.cache/matugen/waybar-transparent-this-time" ]; then
    echo ":: Transparent waybar marker active (full semantic palette still in use for other apps)"
fi

pkill -SIGUSR2 waybar 2>/dev/null || true

rm -f "$HOME/.cache/matugen/waybar-dark-text" \
      "$HOME/.cache/matugen/waybar-light-text" \
      "$HOME/.cache/matugen/waybar-transparent-bright" \
      "$HOME/.cache/matugen/waybar-transparent-dark" 2>/dev/null || true


# ------------------- Generate Waypaper Stylesheet (DISABLED) -------------------
# The stock waypaper (GTK) cannot load the Qt/QSS generated here.
# This block was re-creating ~/.config/waypaper/style.css on every wallpaper change,
# which caused the GUI to crash on the second launch (and on `waypaper` from terminal).
# We keep the section commented so the GUI (backend/folder picker) stays reliable.
# echo ":: Generating Waypaper stylesheet... (disabled to avoid GTK QSS crash)"
# mkdir -p ~/.config/waypaper
# ... (original Matugen QSS generator removed)

# ------------------- Generate Derived Assets (DISABLED) -------------------
#
# Blurred full-size + square/cropped variants are no longer generated.
# Rofi, wlogout, hyprlock, and SDDM all use live blur or the raw wallpaper now.
#
# BLUR_CACHE_NAME="blur-${BLUR}-${EFFECT}-${WALLPAPER_FILENAME}.png"
# BLUR_CACHE_PATH="$GENERATED_DIR/$BLUR_CACHE_NAME"
#
# if [ -f "$BLUR_CACHE_PATH" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
#     echo ":: Using cached blurred wallpaper (rofi)"
# else
#     echo ":: Generating the only allowed pre-blurred asset (rofi 50x30)..."
#     magick "$USED_WALLPAPER" \
#         -resize 1920x1080^ \
#         -gravity center \
#         -extent 1920x1080 \
#         -resize 75% \
#         "$BLURRED_WALLPAPER" 2>/dev/null || true
#
#     if [ "$BLUR" != "0x0" ]; then
#         magick "$BLURRED_WALLPAPER" -blur "$BLUR" "$BLURRED_WALLPAPER" 2>/dev/null || true
#     fi
#     cp "$BLURRED_WALLPAPER" "$BLUR_CACHE_PATH" 2>/dev/null || true
# fi
# cp "$BLUR_CACHE_PATH" "$BLURRED_WALLPAPER" 2>/dev/null || true
#
# SQUARE_CACHE="$GENERATED_DIR/square-$WALLPAPER_FILENAME.png"
# if [ -f "$SQUARE_CACHE" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
#     echo ":: Using cached square wallpaper"
# else
#     echo ":: Generating square wallpaper..."
#     magick "$WALLPAPER" -gravity Center -extent 1:1 "$SQUARE_WALLPAPER" 2>/dev/null || true
#     cp "$SQUARE_WALLPAPER" "$SQUARE_CACHE" 2>/dev/null || true
# fi
#
# echo "* { current-image: url(\"$BLURRED_WALLPAPER\", height); }" > "$RASI_FILE"
# pkill rofi 2>/dev/null || true
#
# echo ":: Generated assets:"
# echo "   - $BLURRED_WALLPAPER   ← The only pre-blurred variant (rofi menus)"
# echo "   - $SQUARE_WALLPAPER"
# echo "   - $RASI_FILE"

echo ":: Wallpaper processing complete!"
