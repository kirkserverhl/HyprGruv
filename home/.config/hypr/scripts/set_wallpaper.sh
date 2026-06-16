#!/bin/bash
# ===================================================================
# Hyprland Wallpaper Post-Command for Waypaper (Matugen-focused)
# ===================================================================
# Primary color source: Matugen
# pywal is only kept temporarily for programs that haven't been migrated yet.
#
# OVERHAUL GOAL (as clarified):
#   The *only* thing that loads a processed version of the wallpaper as an
#   image file is the rofi 50x30 blur generator.
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
GENERATED_DIR="$HOME/.config/settings/cache/wallpaper-generated"
CACHE_DIR="$HOME/.config/settings/cache"
CURRENT_WP_CACHE="$CACHE_DIR/current_wallpaper"
WAYPAPER_LOCK="$CACHE_DIR/waypaper-running"
DEFAULT_WP="$HOME/Pictures/Wallpapers/lady.png"
DEFAULT_WALLPAPER_FILE="$HOME/.config/settings/default"

# ------------------------------------------------------------------
# The only blurred wallpaper we still generate.
# Used exclusively by rofi menus (see RASI_FILE below).
# All other tools (SDDM, wlogout, hyprlock) no longer need pre-blurred assets.
# ------------------------------------------------------------------
BLURRED_WALLPAPER="$CACHE_DIR/blurred_wallpaper.png"

SQUARE_WALLPAPER="$CACHE_DIR/square_wallpaper.png"

RASI_FILE="$CACHE_DIR/current_wallpaper.rasi"

WALLPAPER_EFFECT_FILE="$HOME/.config/settings/wallpaper-effect.sh"
BLUR_FILE="$HOME/.config/settings/blur.sh"
USE_CACHE_FILE="$HOME/.config/settings/wallpaper_cache"

# ------------------- Defaults -------------------
BLUR="50x30"
FORCE_GENERATE=0
USE_CACHE=0
GRAYSCALE_THRESHOLD=0.08

# ------------------- Setup -------------------
mkdir -p "$GENERATED_DIR" "$CACHE_DIR"

if [ -f "$BLUR_FILE" ]; then
    BLUR=$(cat "$BLUR_FILE" | tr -d '[:space:]' | grep -oE '^[0-9]+x[0-9]+' || true)
fi
[ -z "$BLUR" ] && BLUR="20x8"   # sane default if file is empty/garbage

if [ -f "$USE_CACHE_FILE" ]; then
    USE_CACHE=1
    echo ":: Wallpaper cache enabled"
else
    echo ":: Wallpaper cache disabled"
fi

# ------------------- Grayscale Detection -------------------
is_mostly_grayscale() {
    local img="$1"
    local mean_sat
    mean_sat=$(magick "$img" -colorspace HSL -channel S -separate -format "%[fx:mean]" info: 2>/dev/null)
    [ -z "$mean_sat" ] && return 1
    awk "BEGIN { exit !($mean_sat < $GRAYSCALE_THRESHOLD) }"
}

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
trap 'rm -f "$WAYPAPER_LOCK"' EXIT

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
# Apply light ImageMagick filtering to improve color extraction quality
# This runs automatically when setting new wallpapers
PREPROCESSED_WALLPAPER="$GENERATED_DIR/matugen-input-$WALLPAPER_FILENAME"

if [ ! -f "$PREPROCESSED_WALLPAPER" ] || [ "$FORCE_GENERATE" -eq 1 ]; then
    echo ":: Preprocessing wallpaper for better Matugen color extraction..."
    magick "$WALLPAPER" \
      -modulate 100,115,100 \
      -posterize 12 \
      -contrast-stretch 0.5%x0.5% \
      -resize 1400x1400\> \
      "$PREPROCESSED_WALLPAPER"
fi

# ------------------- Color Generation -------------------
echo ":: Running pywal (legacy, being phased out)..."
wal -q -i "$WALLPAPER" || echo ":: pywal failed (non-fatal)"

echo ":: Applying automatic matugen palette from current wallpaper..."
# Non-interactive default: Dark Standard (tonal-spot) + source color 1.
# palette.sh is kept for manual use (Ctrl+P) but is no longer launched here.
# Waybar colors are managed separately (waybar-theme.sh / theme switcher).

if command -v matugen >/dev/null 2>&1; then
    "$HOME/.config/hypr/scripts/apply-matugen-auto.sh" "$WALLPAPER" || true

    # Respect persistent "I want transparent waybar on top of whatever palette" choice
    if [ -f "$HOME/.cache/matugen/waybar-transparent-this-time" ]; then
        echo ":: waybar-transparent-this-time marker present — making bar transparent while keeping full colors"
        python3 - "$HOME/.config/waybar/colors/matugen.css" <<'PY' 2>/dev/null || true
import sys, re
path = sys.argv[1]
with open(path) as f:
    css = f.read()
repl = [
    (r'@define-color background [^;]+;', '@define-color background rgba(0,0,0,0.0);'),
    (r'@define-color surface [^;]+;',     '@define-color surface rgba(0,0,0,0.0);'),
    (r'@define-color surface_container [^;]+;', '@define-color surface_container rgba(0,0,0,0.0);'),
    (r'@define-color surface_container_high [^;]+;', '@define-color surface_container_high rgba(0,0,0,0.0);'),
]
for pat, rep in repl:
    css = re.sub(pat, rep, css)
with open(path, 'w') as f:
    f.write(css)
print("Waybar made transparent (full semantic palette still active for everything else).")
PY
        pkill -SIGUSR2 waybar 2>/dev/null || true
    fi
fi


# ------------------- Clean defensive sync (new world) -------------------
# The main matugen call above (or palette.sh when run manually) is responsible
# for writing the full correct colors via the normal template system.
# This block just makes sure waybar gets a reload signal, and handles the
# one clean "transparent bar + full colors elsewhere" case.

echo ":: Ensuring waybar sees the latest colors..."

if [ -f "$HOME/.cache/matugen/waybar-transparent-this-time" ]; then
    # Already post-processed right after the matugen run above.
    echo ":: Transparent waybar marker active (full semantic palette still in use for other apps)"
else
    # Normal case — the matugen templates (including the one that writes
    # ~/.config/waybar/colors/matugen.css) have already done the right thing.
    true
fi

# palette.sh is available on demand via Ctrl+P — not part of the waypaper post-command flow.
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

# Optional: pywalfox (legacy)
if command -v pywalfox >/dev/null 2>&1; then
    pywalfox update || true
fi

# ------------------- Generate Derived Assets -------------------
#
# UNIFIED WALLPAPER VARIANT STRATEGY
#
# Strict rule:
#   The *only* processed wallpaper image file we generate and let anything load is:
#
#     1. The 50x30 rofi blur variant (for rofi menus)
#
#   SDDM gets the actual raw wallpaper exported directly by update-sddm-wallpaper.sh
#   (no blurred variant; the script forces FullBlur=false + real wallpaper).
#
#   All other tools must use live/real-time methods:
#     - Wlogout: live grim screenshot + Hyprland layerrule blur (see conf/layerrules.lua)
#     - Hyprlock (triggered by hypridle): loads the raw wallpaper directly + its own blur_passes
#
# This section is responsible only for generating the single allowed pre-blurred asset (rofi).
#
BLUR_CACHE_NAME="blur-${BLUR}-${EFFECT}-${WALLPAPER_FILENAME}.png"
BLUR_CACHE_PATH="$GENERATED_DIR/$BLUR_CACHE_NAME"

if [ -f "$BLUR_CACHE_PATH" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
    echo ":: Using cached blurred wallpaper (rofi)"
else
    echo ":: Generating the only allowed pre-blurred asset (rofi 50x30)..."
    # Use the same high-quality scaling approach as the SDDM asset for consistency
    magick "$USED_WALLPAPER" \
        -resize 1920x1080^ \
        -gravity center \
        -extent 1920x1080 \
        -resize 75% \
        "$BLURRED_WALLPAPER" 2>/dev/null || true

    if [ "$BLUR" != "0x0" ]; then
        magick "$BLURRED_WALLPAPER" -blur "$BLUR" "$BLURRED_WALLPAPER" 2>/dev/null || true
    fi
    cp "$BLURRED_WALLPAPER" "$BLUR_CACHE_PATH" 2>/dev/null || true
fi
cp "$BLUR_CACHE_PATH" "$BLURRED_WALLPAPER" 2>/dev/null || true

# Square wallpaper
SQUARE_CACHE="$GENERATED_DIR/square-$WALLPAPER_FILENAME.png"
if [ -f "$SQUARE_CACHE" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
    echo ":: Using cached square wallpaper"
else
    echo ":: Generating square wallpaper..."
    magick "$WALLPAPER" -gravity Center -extent 1:1 "$SQUARE_WALLPAPER" 2>/dev/null || true
    cp "$SQUARE_WALLPAPER" "$SQUARE_CACHE" 2>/dev/null || true
fi

# Rofi .rasi
echo "* { current-image: url(\"$BLURRED_WALLPAPER\", height); }" > "$RASI_FILE"

# Kill any running rofi so the next launch picks up the freshly generated blurred background.
# This fixes the very common "rofi shows the previous wallpaper blurred" issue.
pkill rofi 2>/dev/null || true

echo ":: Generated assets:"
echo "   - $BLURRED_WALLPAPER   ← The only pre-blurred variant (rofi menus)"
echo "   - $SQUARE_WALLPAPER"
echo "   - $RASI_FILE"
echo ""
echo "   SDDM: central default ($DEFAULT_WP_PNG)  [all themes reference this]"
echo "   Wlogout + Hyprlock (via hypridle) → live layers + real-time blur only."

echo ":: Wallpaper processing complete!"

# -----------------------------------------------------------------------------
# SDDM background update
# -----------------------------------------------------------------------------
# The main work for the *image pixels* is already done above (we wrote
# ~/.config/settings/default_wp.png).
#
# This call (self-elevating) mainly ensures:
#   - sddm can traverse into your homedir to read the central default
#   - theme.conf files (sugar-candy + any others you add) point at the central path
#   - matugen colors are synced into the greeter
#
# Because the Background= now points at a stable user-controlled path,
# future wallpaper changes only need to update the png file (no more
# rewriting theme.conf for the wallpaper itself).
"$HOME/.config/hypr/scripts/update-sddm-wallpaper.sh" "$WALLPAPER" || true &
disown 2>/dev/null || true
