#!/usr/bin/env bash
# Generate placeholder icons for HyprGruv Settings (wlogout-style dark tiles).
set -euo pipefail

ICONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/icons"
mkdir -p "$ICONS_DIR"

if ! command -v magick >/dev/null 2>&1; then
    echo "ImageMagick (magick) required to generate icons." >&2
    exit 1
fi

declare -A ICONS=(
    [styling]="#89b4fa|S"
    [settings]="#a6e3a1|G"
    [system]="#f9e2af|Y"
    [exit]="#f38ba8|X"
    [themes]="#cba6f7|T"
    [waypaper]="#94e2d5|W"
    [waybar]="#fab387|B"
    [back]="#6c7086|<"
    [laptop]="#74c7ec|L"
    [packages]="#b4befe|P"
    [updates]="#a6e3a1|U"
    [cleanup]="#f9e2af|C"
    [setup]="#89dceb|S"
    [ssh]="#94e2d5|⌘"
    [blitz]="#f38ba8|!"
    [hyprsunset]="#eba0ac|☾"
    [defaults]="#fabd2f|A"
    [snapshots]="#d3869b|S"
)

featured_svg=""
for candidate in \
    "${HOME}/.icons/Gruvbox-Plus-Dark/apps/scalable/applications-featured.svg" \
    "${HOME}/.local/share/icons/Gruvbox-Plus-Dark/apps/scalable/applications-featured.svg" \
    "/usr/share/icons/Gruvbox-Plus-Dark/apps/scalable/applications-featured.svg"; do
    if [[ -f "$candidate" ]]; then
        featured_svg="$candidate"
        break
    fi
done

for name in "${!ICONS[@]}"; do
    IFS='|' read -r color glyph <<< "${ICONS[$name]}"
    out="$ICONS_DIR/${name}.png"
    if [[ "$name" == "defaults" && -n "$featured_svg" ]]; then
        magick -background none "$featured_svg" -resize 108x108 \
            -gravity center -extent 128x128 \
            "$out"
        continue
    fi
    magick -size 128x128 xc:none \
        -fill "rgba(25,25,25,0.92)" -draw "roundrectangle 10,10 118,118 20,20" \
        -fill "$color" -font "DejaVu-Sans-Bold" -pointsize 44 \
        -gravity center -annotate 0 "$glyph" \
        "$out"
done

echo "Generated ${#ICONS[@]} icons in $ICONS_DIR"