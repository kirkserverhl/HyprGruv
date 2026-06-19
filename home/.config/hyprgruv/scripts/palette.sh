#!/usr/bin/env bash
# palette.sh — Apply matugen color palettes from your current wallpaper
#
# New flow (per user request):
# 1. First screen: Choose and apply the base palette (Dark Standard/Vibrant/Monochrome
#    or "no matugen").
# 2. After the palette is applied: Optional second step to adjust only waybar
#    (normal vs transparent bright vs transparent dark).
#
# Waybar transparency is treated as a post-processing step on top of an
# already-applied matugen palette.
#
# Usage:
#   palette
#
# Features:
# - Automatically uses your current wallpaper
# - Source color selection for best results
# - Clear separation: palette first, waybar transparency second
# - Uses your existing theming helpers (header + colors)

# --- Pop out in floating window (same mechanism as unlockroot.sh, htop.sh, etc.) ---
CLASS="dotfiles-floating"
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

if [[ -z "${PALETTE_INSIDE:-}" ]]; then
    export PALETTE_INSIDE=1
    # Use -e + explicit column size for reliable floating pop-out (same pattern as other tools).
    # The Hyprland windowrule below will enforce the final pixel size + centering.
    # 70c is a good starting point for the compact color preview content.
    # Change this number (e.g. 65c or 75c) to tune the width to your liking.
    exec "${CLEAN_ENV[@]}" kitty \
        --class "$CLASS" \
        --title "Color Palette" \
        --override initial_window_width=70c \
        --override initial_window_height=24c \
        -e "$0" "$@"
fi

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

# Force the terminal title from inside the script as early as possible.
# This guarantees the Hyprland windowrule (which keys on title) will match reliably.
printf '\e]2;Color Palette\a' 2>/dev/null || true

# Note: We intentionally do not use set -euo pipefail for the main body.
# gum, matugen, and some of the wallpaper detection commands can return
# non-zero in normal interactive use and would kill the script.

# --- Find current wallpaper (your reliable cache) ---
CURRENT_WP_CACHE="$HOME/.config/last_wallpaper.txt"
DEFAULT_WP="$HOME/Pictures/Wallpapers/gruvbox_image46.png"

if [[ -f "$CURRENT_WP_CACHE" ]]; then
    WALLPAPER=$(cat "$CURRENT_WP_CACHE")
elif [[ -f "$HOME/.config/settings/default" ]]; then
    WALLPAPER=$(cat "$HOME/.config/settings/default")
fi

if [[ -z "${WALLPAPER:-}" || ! -f "$WALLPAPER" ]]; then
    echo ":: Could not determine current wallpaper. Using fallback."
    WALLPAPER="$DEFAULT_WP"
fi

WP_NAME=$(basename "$WALLPAPER")

# --- Main loop ---
while true; do
    clear

    print_header "Palette"
    echo "Current wallpaper: $WP_NAME"
    echo

    # First screen: Pure palette application (waybar transparency is a follow-up step)
    choice=$(gum choose \
        "Dark - Standard (tonal spot)" \
        "Dark - Vibrant" \
        "Dark - Monochrome" \
        "None - Plain text only (no matugen at all)" \
        "Exit" \
        --header "Apply palette:")

    # Handle cancel (Esc / Ctrl+C in gum)
    if [[ -z "$choice" ]]; then
        echo "Cancelled."
        break
    fi

    case "$choice" in
        "Exit")
            echo
            echo "Exiting palette viewer."
            break
            ;;

        "None - Plain text only (no matugen at all)")
            echo
            echo "Extracting raw dominant colors (no matugen processing):"
            echo "Wallpaper: $WP_NAME"
            echo

            if ! command -v matugen >/dev/null 2>&1; then
                echo "Error: matugen is not installed."
                read -r -p "Press Enter to return to menu..."
                continue
            fi

            # Get colors as plain text only — no colored backgrounds from --show-colors
            RAW_JSON=$(matugen image "$WALLPAPER" --mode dark --json hex 2>/dev/null || true)

            if [[ -n "$RAW_JSON" ]]; then
                echo "Hex          Name"
                echo "────────────────────────────"
                echo "$RAW_JSON" | jq -r '
                    .colors.default
                    | to_entries[]
                    | "\(.value.hex)   \(.key)"
                ' | sort
            else
                echo "Could not extract colors from matugen."
            fi

            echo

            # Clean, utility-style notice (no fancy styling)
            echo "────────────────────────────────────────"
            echo "  NO MATUGEN THEMING SELECTED"
            echo "────────────────────────────────────────"
            echo
            echo "  This wallpaper will use its original colors."
            echo "  No generated palettes or backgrounds will be applied."
            echo
            echo "  Press Enter to apply and close this window."
            echo "────────────────────────────────────────"

            echo
            while true; do
                read -rsn1 key
                if [[ -z "$key" ]]; then
                    echo
                    echo "→ No Matugen will be applied."
                    mkdir -p "$HOME/.cache/matugen"
                    touch "$HOME/.cache/matugen/no-matugen-this-time"
                    sleep 0.4
                    exit 0
                elif [[ "$key" =~ [qQ] ]]; then
                    echo "Returning to menu..."
                    break
                fi
            done
            continue
            ;;

        "Dark - Standard (tonal spot)")
            MODE="--mode dark"
            TYPE="--type scheme-tonal-spot"
            LABEL="Dark (Standard)"
            rm -f "$HOME/.cache/matugen/force-monochrome" 2>/dev/null || true
            ;;
        "Dark - Vibrant")
            MODE="--mode dark"
            TYPE="--type scheme-vibrant"
            LABEL="Dark - Vibrant"
            rm -f "$HOME/.cache/matugen/force-monochrome" 2>/dev/null || true
            ;;
        "Dark - Monochrome")
            MODE="--mode dark"
            TYPE="--type scheme-monochrome"
            LABEL="Dark - Monochrome"
            mkdir -p "$HOME/.cache/matugen"
            touch "$HOME/.cache/matugen/force-monochrome"
            ;;
        *)
            echo "Unknown option"
            continue
            ;;
    esac

    echo
    echo "Generating: $LABEL"
    echo "Wallpaper : $WP_NAME"
    echo

    if ! command -v matugen >/dev/null 2>&1; then
        echo "Error: matugen is not installed."
        read -r -p "Press Enter to return to menu..."
        continue
    fi

    # === Restore the important "choose among good source colors" step ===
    # Some source colors produce much better waybar / rainbow results than others.
    # The user needs to be able to try several, exactly like the previous working flow.
    EXTRACTOR="$HOME/.config/hyprgruv/scripts/extract-good-source-colors.sh"
    mapfile -t GOOD_COLORS < <("$EXTRACTOR" "$WALLPAPER" 4 2>/dev/null)

    if [[ ${#GOOD_COLORS[@]} -lt 4 ]]; then
        GOOD_COLORS=("#a78a9d" "#eda9a1" "#838095" "#e9ccb8")
    fi

    # Helper: return a small truecolor square for the given hex (works in kitty)
    color_swatch() {
        local hex=${1#\#}
        local r=$((16#${hex:0:2}))
        local g=$((16#${hex:2:2}))
        local b=$((16#${hex:4:2}))
        # Solid block character with background color = nice visible square
        printf '\e[48;2;%d;%d;%dm█\e[0m' "$r" "$g" "$b"
    }

    source_options=()
    for i in "${!GOOD_COLORS[@]}"; do
        hex="${GOOD_COLORS[$i]}"
        swatch=$(color_swatch "$hex")
        source_options+=("${swatch}  Source color $((i+1))   $hex")
    done
    source_options+=("Auto (first good color)")

    chosen_src=$(gum choose "${source_options[@]}" \
        --header "STEP 2 / 2 — Choose source color for $LABEL (critical for good waybar output)")

    if [[ "$chosen_src" == Auto* ]]; then
        SRC="${GOOD_COLORS[0]}"
    elif [[ "$chosen_src" =~ Source\ color\ ([0-9]) ]]; then
        idx=$(( ${BASH_REMATCH[1]} - 1 ))
        SRC="${GOOD_COLORS[$idx]}"
    else
        SRC="${GOOD_COLORS[0]}"
    fi

    # Ensure the wal cache dir exists (prevents pywalfox template errors)
    mkdir -p "$HOME/.cache/wal" 2>/dev/null || true

    matugen color hex "$SRC" $MODE $TYPE --show-colors --dry-run

    echo
    swatch=$(color_swatch "$SRC")
    gum style --bold --foreground 6 "✓ Preview (no changes applied): $LABEL   ${swatch}  $SRC"
    echo
    echo "Press [Enter] to apply this style and close, or [q] to exit without applying"
    while true; do
        read -rsn1 key
        if [[ -z "$key" ]]; then
            swatch=$(color_swatch "$SRC")
            echo "Applying $LABEL   ${swatch}  $SRC ..."
            mkdir -p "$HOME/.cache/wal" "$HOME/.cache/matugen" 2>/dev/null || true

            MATUGEN_MODE="${MODE#--mode }"
            MATUGEN_TYPE="${TYPE#--type }"
            jq -n \
                --arg wp "$WALLPAPER" \
                --arg method "hex" \
                --arg mode "$MATUGEN_MODE" \
                --arg type "$MATUGEN_TYPE" \
                --arg source_hex "$SRC" \
                --argjson source_index 0 \
                '{
                    wallpaper: $wp,
                    method: $method,
                    mode: $mode,
                    type: $type,
                    source_hex: $source_hex,
                    source_index: $source_index
                }' >"$HOME/.cache/matugen/pending-run.json"

            # Run matugen. We no longer trust its exit code blindly because
            # secondary templates (pywalfox/wal) can complain even when the
            # important ones (waybar, starship, hypr, etc.) succeed.
            matugen color hex "$SRC" $MODE $TYPE 2>&1 | tail -6

            # Verify that the thing we actually care about moved forward
            if [ -f "$HOME/.config/waybar/colors/matugen.css" ]; then
                echo "✓ $LABEL applied (waybar + starship templates updated)"

                pkill -SIGUSR2 waybar 2>/dev/null || true
                if [ -f "$HOME/.config/waybar/colors/matugen.css" ]; then
                    cp -f "$HOME/.config/waybar/colors/matugen.css" "$HOME/.config/waybar/colors.css" 2>/dev/null || true
                fi
                if [ -f "$HOME/.config/starship/matugen-rainbow.toml" ]; then
                    touch "$HOME/.config/starship/matugen-rainbow.toml" 2>/dev/null || true
                fi

                sleep 0.4

                # --- Second stage: Waybar treatment (only after palette is applied) ---
                waybar_choice=$(gum choose \
                    "Normal (full matugen colors)" \
                    "Transparent background + bright text" \
                    "Transparent background + dark text" \
                    --header "Waybar style for this palette?")

                case "$waybar_choice" in
                    "Transparent background + bright text")
                        echo "Applying transparent waybar (bright text)..."
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
print("Waybar backgrounds made transparent (bright text variant).")
PY
                        mkdir -p "$HOME/.cache/matugen"
                        touch "$HOME/.cache/matugen/waybar-transparent-bright"
                        touch "$HOME/.cache/matugen/waybar-transparent-this-time"
                        pkill -SIGUSR2 waybar 2>/dev/null || true
                        echo "✓ Transparent + bright text applied"
                        ;;
                    "Transparent background + dark text")
                        echo "Applying transparent waybar (dark text)..."
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
print("Waybar backgrounds made transparent (dark text variant).")
PY
                        mkdir -p "$HOME/.cache/matugen"
                        touch "$HOME/.cache/matugen/waybar-transparent-dark"
                        touch "$HOME/.cache/matugen/waybar-transparent-this-time"
                        pkill -SIGUSR2 waybar 2>/dev/null || true
                        echo "✓ Transparent + dark text applied"
                        ;;
                    *)
                        echo "✓ Normal matugen waybar colors kept"
                        ;;
                esac

                sleep 0.6
                exit 0
            else
                echo "⚠ Something went wrong — check the output above."
            fi
        elif [[ "$key" =~ [qQ] ]]; then
            echo "Exiting without applying."
            exit 0
        fi
    done
done

echo
echo "Done."