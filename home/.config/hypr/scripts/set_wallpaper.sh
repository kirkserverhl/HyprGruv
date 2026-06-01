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
#   SDDM receives the actual chosen wallpaper (never a blurred copy) via
#   update-sddm-wallpaper.sh, which also forces FullBlur="false".
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

echo ":: Running matugen via palette chooser (interactive)..."
MATUGEN_JSON=""
SKIP_MATUGEN_THEMING=0

if command -v matugen >/dev/null 2>&1; then
    # palette.sh is the main outhook for wallpaper changes.
    # It pops the floating Kitty + gum menu so you can visually choose a good source color.
    # Inside palette.sh it calls `matugen color hex` (which we verified updates every template + post_hooks).
    echo ":: Launching palette chooser..."
    ~/.config/hypr/scripts/palette.sh || true

    # --- New transparent text-only modes (bright/dark font on fully transparent bar) ---
    # IMPORTANT: We deliberately do NOT call matugen at all here, to avoid applying any color scheme.
    # We use the local extractor (ImageMagick based) to get candidate colors, then pick the extreme one.
    if [ -f "$HOME/.cache/matugen/waybar-transparent-bright" ] || [ -f "$HOME/.cache/matugen/waybar-transparent-dark" ]; then
        echo ":: Transparent text-only mode (from palette) — no matugen theming will be applied"

        EXTRACTOR="$HOME/.config/hypr/scripts/extract-good-source-colors.sh"
        CANDIDATES=()
        if [[ -x "$EXTRACTOR" ]]; then
            mapfile -t CANDIDATES < <("$EXTRACTOR" "$WALLPAPER" 8 2>/dev/null | head -8)
        fi

        # Fallback if extractor gave nothing
        if [ ${#CANDIDATES[@]} -lt 2 ]; then
            mapfile -t CANDIDATES < <(magick "$PREPROCESSED_WALLPAPER" -resize 300x300\> -modulate 100,180,100 -colors 12 +dither -unique-colors txt:- 2>/dev/null | grep -oP '#[0-9A-Fa-f]{6}' | head -8)
        fi

        if [ ${#CANDIDATES[@]} -gt 0 ]; then
            if [ -f "$HOME/.cache/matugen/waybar-transparent-bright" ]; then
                # Pick brightest (highest luma)
                WAYBAR_CUSTOM_TEXT=$(python3 -c '
import sys
colors = sys.stdin.read().split()
best_hex = "#eeeeee"
best_luma = -1
for hx in colors:
    hx = hx.strip()
    if hx.startswith("#") and len(hx) == 7:
        r = int(hx[1:3], 16)
        g = int(hx[3:5], 16)
        b = int(hx[5:7], 16)
        luma = 0.299 * r + 0.587 * g + 0.114 * b
        if luma > best_luma:
            best_luma = luma
            best_hex = hx
print(best_hex)
' <<< "${CANDIDATES[*]}" 2>/dev/null || echo "#eeeeee")
                MODE_LABEL="bright text (light font)"
                rm -f "$HOME/.cache/matugen/waybar-transparent-bright"
            else
                # Pick darkest (lowest luma)
                WAYBAR_CUSTOM_TEXT=$(python3 -c '
import sys
colors = sys.stdin.read().split()
best_hex = "#222222"
best_luma = 999999
for hx in colors:
    hx = hx.strip()
    if hx.startswith("#") and len(hx) == 7:
        r = int(hx[1:3], 16)
        g = int(hx[3:5], 16)
        b = int(hx[5:7], 16)
        luma = 0.299 * r + 0.587 * g + 0.114 * b
        if luma < best_luma:
            best_luma = luma
            best_hex = hx
print(best_hex)
' <<< "${CANDIDATES[*]}" 2>/dev/null || echo "#222222")
                MODE_LABEL="dark text"
                rm -f "$HOME/.cache/matugen/waybar-transparent-dark"
            fi

            # Write fully transparent minimal colors — only the text color is set
            cat > ~/.config/waybar/colors.css << EOF
/* Fully transparent bar + $MODE_LABEL only (from palette None modes)
   No matugen scheme applied at all.
*/
@define-color background rgba(0,0,0,0.0);
@define-color foreground ${WAYBAR_CUSTOM_TEXT};
@define-color surface rgba(0,0,0,0.0);
@define-color on_surface ${WAYBAR_CUSTOM_TEXT};
@define-color surface_container rgba(0,0,0,0.0);
@define-color surface_container_high rgba(0,0,0,0.0);
EOF
            pkill -SIGUSR2 waybar 2>/dev/null || true
            echo ":: Waybar now fully transparent with $MODE_LABEL (${WAYBAR_CUSTOM_TEXT})"
            WAYBAR_COLORS_WRITTEN=true
            MATUGEN_JSON=""
            SKIP_MATUGEN_THEMING=1
        else
            echo ":: Could not extract colors for transparent mode, skipping"
            rm -f "$HOME/.cache/matugen/waybar-transparent-bright" "$HOME/.cache/matugen/waybar-transparent-dark"
        fi
    fi

    # Respect full "None / no matugen" choice
    if [ -f "$HOME/.cache/matugen/no-matugen-this-time" ]; then
        echo ":: None mode selected — keeping waybar minimal/transparent (no matugen colors forced)"
        # Write a very minimal transparent waybar colors file
        cat > ~/.config/waybar/colors.css << 'EOF'
/* Minimal transparent mode requested from palette "None" */
@define-color background rgba(0,0,0,0.0);
@define-color foreground #dddddd;
@define-color surface rgba(0,0,0,0.0);
EOF
        pkill -SIGUSR2 waybar 2>/dev/null || true
        rm -f "$HOME/.cache/matugen/no-matugen-this-time"
        # Skip all the normal matugen JSON / waybar writing below
        WAYBAR_COLORS_WRITTEN=true
        MATUGEN_JSON=""
    else
        if [ "$SKIP_MATUGEN_THEMING" = "1" ]; then
            echo ":: Skipping normal matugen JSON capture (transparent text mode)"
        else
            # Normal path: try to capture JSON for special handling (best effort)
            RAW_JSON=$(matugen image "$PREPROCESSED_WALLPAPER" --mode dark --source-color-index 0 --json hex 2>/dev/null || true)
        MATUGEN_JSON=$(printf '%s\n' "$RAW_JSON" | sed '/^ok$/d' | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    print(json.dumps(data))
except Exception:
    print("")
' 2>/dev/null || true)

        if [ -n "$MATUGEN_JSON" ]; then
            echo ":: Matugen JSON captured (for special Waybar modes)"
        else
            echo ":: Could not capture extra JSON (not critical)"
        fi
    fi
fi

# Strong guard for transparent text-only modes
if [ "$SKIP_MATUGEN_THEMING" = "1" ]; then
    echo ":: Transparent text-only mode — skipping remaining matugen forcing"
fi

# ------------------- Ensure Waybar colors.css is updated (defensive Matugen-only) -------------------
if [ -f "$HOME/.cache/matugen/no-matugen-this-time" ]; then
    # Already handled above — do nothing
    rm -f "$HOME/.cache/matugen/no-matugen-this-time" 2>/dev/null || true
    echo ":: Skipping waybar theming (None mode)"
else
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

# If we didn't get JSON from the main run (palette.sh), try one simple safe fallback for Waybar
if [ "$WAYBAR_COLORS_WRITTEN" = false ] && command -v matugen >/dev/null 2>&1; then
    if [ "$SKIP_MATUGEN_THEMING" = "1" ]; then
        echo ":: Skipping fallback matugen (transparent text mode active)"
    else
        echo ":: Trying simple fallback matugen run for Waybar JSON..."
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

# --- Handle "None" mode from palette (apply Matugen everywhere except Waybar) ---
if [ -f "$HOME/.cache/matugen/waybar-dark-text" ]; then
    echo ":: Waybar Dark mode — extracting whitest color from Matugen palette for text"
    WAYBAR_CUSTOM_TEXT=$(python3 -c '
import sys, json
data = json.load(sys.stdin)
colors = data.get("colors", {}).get("default", {})
best_hex = "#ffffff"
best_luma = -1
for name, val in colors.items():
    if isinstance(val, dict) and "hex" in val:
        h = val["hex"].lstrip("#")
        if len(h) == 6:
            r = int(h[0:2], 16)
            g = int(h[2:4], 16)
            b = int(h[4:6], 16)
            luma = 0.299 * r + 0.587 * g + 0.114 * b
            if luma > best_luma:
                best_luma = luma
                best_hex = val["hex"]
print(best_hex)
' <<< "$MATUGEN_JSON" 2>/dev/null || echo "#ffffff")
    rm -f "$HOME/.cache/matugen/waybar-dark-text"

elif [ -f "$HOME/.cache/matugen/waybar-light-text" ]; then
    echo ":: Waybar Light mode — extracting darkest color from Matugen palette for text"
    WAYBAR_CUSTOM_TEXT=$(python3 -c '
import sys, json
data = json.load(sys.stdin)
colors = data.get("colors", {}).get("default", {})
best_hex = "#000000"
best_luma = 999999
for name, val in colors.items():
    if isinstance(val, dict) and "hex" in val:
        h = val["hex"].lstrip("#")
        if len(h) == 6:
            r = int(h[0:2], 16)
            g = int(h[2:4], 16)
            b = int(h[4:6], 16)
            luma = 0.299 * r + 0.587 * g + 0.114 * b
            if luma < best_luma:
                best_luma = luma
                best_hex = val["hex"]
print(best_hex)
' <<< "$MATUGEN_JSON" 2>/dev/null || echo "#000000")
    rm -f "$HOME/.cache/matugen/waybar-light-text"
fi

if [ -n "$WAYBAR_CUSTOM_TEXT" ]; then
    cat > ~/.config/waybar/colors/matugen.css << EOF
/* Waybar using single extreme color pulled from the current Matugen palette */
/* Dark bar background + high-contrast text color chosen to match the wallpaper */

@define-color background #1f1f1f;
@define-color foreground ${WAYBAR_CUSTOM_TEXT};

@define-color surface #1f1f1f;
@define-color on_surface ${WAYBAR_CUSTOM_TEXT};
EOF
    pkill -SIGUSR2 waybar 2>/dev/null || true
fi

# --- Generate and switch Starship to grayscale scale when using special "None" Waybar modes ---
STARSHIP_DIR="$HOME/.config/starship"
mkdir -p "$STARSHIP_DIR"

if [ "$WAYBAR_MODE" = "dark" ] || [ -f "$HOME/.cache/matugen/waybar-dark-text" ]; then
    # white-grey-black scale using the bright extreme
    cat > "$STARSHIP_DIR/matugen-grayscale-dark.toml" << EOF
# Grayscale prompt - white/grey/black (for "Dark" None option)
# Bright accent from Matugen: ${WAYBAR_CUSTOM_TEXT}
# All text is black except the final time module.

format = """
[](fg:color_bright)\
$os\
$username\
[](fg:color_bright bg:color_grey2)\
$directory\
[](fg:color_grey2 bg:color_grey1)\
$git_branch\
$git_status\
[](fg:color_grey1 bg:color_dark)\
$character
[](fg:color_dark bg:color_bright)\
$time
[](fg:color_bright)\
$line_break"""

palette = 'matugen-gs-dark'

[palettes.matugen-gs-dark]
color_bright = "${WAYBAR_CUSTOM_TEXT}"
color_grey2   = "#aaaaaa"
color_grey1   = "#666666"
color_dark    = "#222222"

[time]
format = "[$time]($style)"
style = "bg:color_bright fg:black"
EOF
    ln -sf "$STARSHIP_DIR/matugen-grayscale-dark.toml" "$HOME/.config/starship.toml"
    echo ":: Starship → grayscale dark (white-grey-black)"

elif [ "$WAYBAR_MODE" = "light" ] || [ -f "$HOME/.cache/matugen/waybar-light-text" ]; then
    # black-grey-white scale using the dark extreme
    cat > "$STARSHIP_DIR/matugen-grayscale-light.toml" << EOF
# Grayscale prompt - black/grey/white (for "Light" None option)
# Dark accent from Matugen: ${WAYBAR_CUSTOM_TEXT}
# All text is black except the final time module.

format = """
[](fg:color_dark)\
$os\
$username\
[](fg:color_dark bg:color_grey1)\
$directory\
[](fg:color_grey1 bg:color_grey2)\
$git_branch\
$git_status\
[](fg:color_grey2 bg:color_bright)\
$character
[](fg:color_bright bg:color_dark)\
$time
[](fg:color_dark)\
$line_break"""

palette = 'matugen-gs-light'

[palettes.matugen-gs-light]
color_dark   = "${WAYBAR_CUSTOM_TEXT}"
color_grey1  = "#555555"
color_grey2  = "#aaaaaa"
color_bright = "#ffffff"

[time]
format = "[$time]($style)"
style = "bg:color_bright fg:black"
EOF
    ln -sf "$STARSHIP_DIR/matugen-grayscale-light.toml" "$HOME/.config/starship.toml"
    echo ":: Starship → grayscale light (black-grey-white)"
fi



# (Old generic static Waybar block removed — replaced by the Matugen extreme-color modes above)

fi   # end of "if not in no-matugen mode" guard
fi   # end of SKIP_MATUGEN_THEMING guard (for transparent text modes)

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
echo "   SDDM: actual wallpaper (sddm-wallpaper.png) + FullBlur=false"
echo "   Wlogout + Hyprlock (via hypridle) → live layers + real-time blur only."

echo ":: Wallpaper processing complete!"

# -----------------------------------------------------------------------------
# SDDM background update (sugar-candy)
# -----------------------------------------------------------------------------
# Pass the *raw actual wallpaper*. The updater writes it directly as
# sddm-wallpaper.png and forces theme.conf to use it with FullBlur=false.
# (The only remaining blur for SDDM is the theme's optional PartialBlur on the form.)
"$HOME/.config/hypr/scripts/update-sddm-wallpaper.sh" "$WALLPAPER" || true &
disown 2>/dev/null || true

fi  # close main matugen if (safety for previous edits)
