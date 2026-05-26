#!/usr/bin/env bash
# rofi-choose-matugen-style.sh
#
# Shows a compact Rofi menu with the same 4 palette styles as 'palette' script.
# Intended to be called from set_wallpaper.sh (Waypaper post-command).
#
# Usage:
#   chosen_args=$(~/.config/hypr/scripts/rofi-choose-matugen-style.sh "/path/to/wallpaper.png")
#
# Outputs matugen flags on stdout (e.g. "--mode dark --type scheme-vibrant")
# or exits with code 1 if user cancelled.

set -euo pipefail

WALLPAPER="${1:-}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Error: No valid wallpaper path provided" >&2
    exit 1
fi

# Use your matugen colors for consistency
THEME_OVERRIDE='
* {
    background:                  rgba(22, 19, 11, 0.92);
    background-alt:              #4c4639;
    foreground:                  #eae1d4;
    selected:                    #e3c46d;
    active:                      #e3c46d;
    urgent:                      #ffb4ab;
}

window {
    width:                       28%;
    height:                      42%;
    border-radius:               12px;
    padding:                     12px;
}

listview {
    lines:                       6;
    fixed-height:                true;
    scrollbar:                   true;
}

element {
    padding:                     10px 16px;
    border-radius:               8px;
}

element selected.normal {
    background-color:            @selected;
    text-color:                  #222222;
}
'

# The 4 options + cancel (same as your improved palette.sh)
options=(
    "Dark - Standard (tonal spot)"
    "Light - Standard"
    "Dark - Vibrant"
    "Dark - Monochrome"
    "Cancel"
)

selected=$(printf '%s\n' "${options[@]}" | \
    rofi -dmenu -i \
        -p "Matugen Style for $(basename "$WALLPAPER")" \
        -theme-str "$THEME_OVERRIDE" \
        -no-custom \
        2>/dev/null || true)

if [[ -z "$selected" || "$selected" == "Cancel" ]]; then
    exit 1
fi

case "$selected" in
    "Dark - Standard (tonal spot)")
        echo "--mode dark --type scheme-tonal-spot"
        ;;
    "Light - Standard")
        echo "--mode light --type scheme-tonal-spot"
        ;;
    "Dark - Vibrant")
        echo "--mode dark --type scheme-vibrant"
        ;;
    "Dark - Monochrome")
        echo "--mode dark --type scheme-monochrome"
        ;;
    *)
        echo "--mode dark --type scheme-tonal-spot"
        ;;
esac
