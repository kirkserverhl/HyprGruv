#!/bin/bash
# ===================================================================
# Hyprland Wallpaper Post-Command for Waypaper (Matugen-focused)
# ===================================================================
# Primary color source: Matugen
# pywal is only kept temporarily for programs that haven't been migrated yet.

set -uo pipefail

# ------------------- Paths -------------------
GENERATED_DIR="$HOME/.config/settings/cache/wallpaper-generated"
CACHE_DIR="$HOME/.config/settings/cache"
CURRENT_WP_CACHE="$CACHE_DIR/current_wallpaper"
WAYPAPER_LOCK="$CACHE_DIR/waypaper-running"
DEFAULT_WP="$HOME/Pictures/Wallpapers/lady.png"

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
    BLUR=$(cat "$BLUR_FILE")
fi

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
else
    WALLPAPER="$DEFAULT_WP"
fi

echo "$WALLPAPER" > "$CURRENT_WP_CACHE"
echo ":: Setting wallpaper: $WALLPAPER"

WALLPAPER_FILENAME=$(basename "$WALLPAPER")
USED_WALLPAPER="$WALLPAPER"

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

echo ":: Running matugen..."
MATUGEN_JSON=""
if command -v matugen >/dev/null 2>&1; then
    matugen_args="--mode dark --source-color-index 0"

    if is_mostly_grayscale "$WALLPAPER"; then
        echo ":: Detected mostly grayscale image → using monochrome scheme for neutral colors"
        matugen_args+=" --type scheme-monochrome"
    fi

    # Always attempt JSON output for automation (Waypaper post-command has no TTY).
    # --source-color-index 0 prevents the interactive "multiple source colors" prompt.
    echo ":: Running matugen (non-interactive)..."
    matugen image "$PREPROCESSED_WALLPAPER" $matugen_args 2>&1 | tee -a ~/.cache/matugen.log || true

    # Capture clean JSON (strip any trailing "ok" noise)
    RAW_JSON=$(matugen image "$PREPROCESSED_WALLPAPER" $matugen_args --json hex 2>/dev/null || true)
    MATUGEN_JSON=$(printf '%s\n' "$RAW_JSON" | sed '/^ok$/d' | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    print(json.dumps(data))
except Exception:
    print("")
' 2>/dev/null || true)

    if [ -n "$MATUGEN_JSON" ]; then
        echo ":: Matugen JSON captured successfully"
    else
        echo ":: Matugen did not produce usable JSON (see ~/.cache/matugen.log)"
    fi
else
    echo ":: matugen not found"
fi

# ------------------- Ensure Waybar colors.css is updated (defensive Matugen-only) -------------------
echo ":: Ensuring Waybar colors.css is up to date from Matugen..."

WAYBAR_COLORS_WRITTEN=false

if [ -n "$MATUGEN_JSON" ]; then
    python3 -c '
import json, sys, os
data = json.loads(sys.stdin.read())
colors = data.get("colors", {}).get("default", {})

css = ""
for name, value in colors.items():
    if isinstance(value, dict) and "hex" in value:
        css += f"@define-color {name} {value["hex"]};\n"

waybar_css_path = os.path.expanduser("~/.config/waybar/colors.css")
with open(waybar_css_path, "w") as f:
    f.write(css)
print(f"Waybar colors.css written from Matugen JSON ({len(colors)} colors)")
' <<< "$MATUGEN_JSON" && WAYBAR_COLORS_WRITTEN=true
fi

# If we didn't get JSON from the main run, try one more time defensively for Waybar
if [ "$WAYBAR_COLORS_WRITTEN" = false ] && command -v matugen >/dev/null 2>&1; then
    echo ":: Main Matugen run did not provide JSON — attempting dedicated extraction for Waybar..."
    RAW_FALLBACK=$(matugen image "$PREPROCESSED_WALLPAPER" --mode dark --source-color-index 0 --json hex 2>/dev/null || true)
    FALLBACK_JSON=$(printf '%s\n' "$RAW_FALLBACK" | sed '/^ok$/d' | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    print(json.dumps(data))
except Exception:
    print("")
' 2>/dev/null || true)
    if [ -n "$FALLBACK_JSON" ]; then
        python3 -c '
import json, sys, os
data = json.loads(sys.stdin.read())
colors = data.get("colors", {}).get("default", {})

css = ""
for name, value in colors.items():
    if isinstance(value, dict) and "hex" in value:
        css += f"@define-color {name} {value["hex"]};\n"

waybar_css_path = os.path.expanduser("~/.config/waybar/colors.css")
with open(waybar_css_path, "w") as f:
    f.write(css)
print(f"Waybar colors.css written from fallback Matugen JSON ({len(colors)} colors)")
' <<< "$FALLBACK_JSON" && WAYBAR_COLORS_WRITTEN=true
    fi
fi

if [ "$WAYBAR_COLORS_WRITTEN" = true ]; then
    pkill -SIGUSR2 waybar 2>/dev/null || true
else
    echo ":: Could not obtain Matugen data for Waybar this time"
fi

# ------------------- Generate Waypaper Stylesheet (Matugen only) -------------------
echo ":: Generating Waypaper stylesheet..."
mkdir -p ~/.config/waypaper

if [ -n "$MATUGEN_JSON" ]; then
    python3 -c '
import json, sys, os
data = json.loads(sys.stdin.read())
colors = data["colors"]["default"]

qss = f"""/* Waypaper Stylesheet - Generated by Matugen */
QWidget {{
    background-color: {colors["surface"]["hex"]};
    color: {colors["on_surface"]["hex"]};
}}

QPushButton {{
    background-color: {colors["primary_container"]["hex"]};
    color: {colors["on_primary_container"]["hex"]};
    border: 1px solid {colors["outline"]["hex"]};
    border-radius: 6px;
    padding: 6px 12px;
}}

QPushButton:hover {{
    background-color: {colors["primary"]["hex"]};
    color: {colors["on_primary"]["hex"]};
}}
"""

with open(os.path.expanduser("~/.config/waypaper/style.css"), "w") as f:
    f.write(qss)
print("Waypaper style.css generated from Matugen")
' <<< "$MATUGEN_JSON"
else
    echo ":: No Matugen JSON available — Waypaper stylesheet not generated this run"
fi

# Optional: pywalfox (legacy)
if command -v pywalfox >/dev/null 2>&1; then
    pywalfox update || true
fi

# ------------------- Generate Derived Assets -------------------
# Blurred wallpaper
BLUR_CACHE_NAME="blur-${BLUR}-${EFFECT}-${WALLPAPER_FILENAME}.png"
BLUR_CACHE_PATH="$GENERATED_DIR/$BLUR_CACHE_NAME"

if [ -f "$BLUR_CACHE_PATH" ] && [ "$FORCE_GENERATE" -eq 0 ] && [ "$USE_CACHE" -eq 1 ]; then
    echo ":: Using cached blurred wallpaper"
else
    echo ":: Generating blurred wallpaper..."
    magick "$USED_WALLPAPER" -resize 75% "$BLURRED_WALLPAPER" 2>/dev/null || true
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

echo ":: Generated assets:"
echo "   - $BLURRED_WALLPAPER"
echo "   - $SQUARE_WALLPAPER"
echo "   - $RASI_FILE"

echo ":: Wallpaper processing complete!"
