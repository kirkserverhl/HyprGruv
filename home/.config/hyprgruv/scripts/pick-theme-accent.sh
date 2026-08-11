#!/usr/bin/env bash
# pick-theme-accent.sh — Super+W step 3: pick primary/source from theme palette
#
# Shows the theme's standard accent splotches (not wallpaper-extracted colors),
# e.g. Gruvbox: red, purple, yellow, green, aqua, orange, blue.
# Choice becomes base0D/base0F (active border, waybar primary, starship accents, …).
#
# Usage:
#   pick-theme-accent.sh <theme-name> [wallpaper-path]
# Exit 0 always (cancel keeps current theme primary).
set -euo pipefail

THEME="${1:-}"
WALLPAPER="${2:-}"
GENERATOR="${HOME}/.config/colorschemes/generate-preset-colors.py"
RELOAD="${HOME}/.config/hyprgruv/scripts/reload-matugen-visible.sh"
ROFI_THEME="${HOME}/.config/rofi/theme-accent-grid.rasi"
[[ -f "$ROFI_THEME" ]] || ROFI_THEME="${HOME}/.config/rofi/color-grid.rasi"

if [[ -z "$THEME" || ! -f "$GENERATOR" ]]; then
    echo "Usage: pick-theme-accent.sh <theme-name> [wallpaper]" >&2
    exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi not found — skipping accent pick" >&2
    exit 0
fi

# JSON array of {slot,label,hex}
mapfile -t LINES < <(python3 "$GENERATOR" --list-accents "$THEME" 2>/dev/null | jq -c '.[]' 2>/dev/null || true)
if ((${#LINES[@]} == 0)); then
    echo "No accents for theme $THEME — skipping" >&2
    exit 0
fi

SWATCH_DIR=$(mktemp -d /tmp/theme-accent-XXXXXX)
trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT

# Build rofi entries: labeled splotches
ROFI_INPUT=""
declare -a HEXES=()
declare -a LABELS=()
i=0
for line in "${LINES[@]}"; do
    hex=$(jq -r '.hex' <<<"$line")
    label=$(jq -r '.label' <<<"$line")
    [[ -n "$hex" && "$hex" != "null" ]] || continue
    swatch="$SWATCH_DIR/$(printf '%02d' "$i")-${label}.png"
    if command -v magick >/dev/null 2>&1; then
        magick -size 160x96 "xc:${hex}" \
            -fill white -stroke black -strokewidth 1 \
            -gravity south -pointsize 18 -annotate +0+8 "$label" \
            -alpha off png32:"$swatch" 2>/dev/null \
            || magick -size 160x96 "xc:${hex}" -alpha off png32:"$swatch"
    elif command -v convert >/dev/null 2>&1; then
        convert -size 160x96 "xc:${hex}" "$swatch" 2>/dev/null || true
    fi
    [[ -f "$swatch" ]] || continue
    HEXES+=("$hex")
    LABELS+=("$label")
    ROFI_INPUT+="${label}\0icon\x1f${swatch}\n"
    i=$((i + 1))
done

((${#HEXES[@]})) || exit 0

chosen=$(printf '%b' "$ROFI_INPUT" | rofi -dmenu -i -show-icons \
    -p "Primary / source color — $THEME" \
    -mesg "Active window, waybar accents, starship · Escape = keep default" \
    -theme "$ROFI_THEME" \
    -no-custom 2>/dev/null || true)

[[ -z "${chosen:-}" ]] && exit 0

# Match by label
PICK_HEX=""
for i in "${!LABELS[@]}"; do
    if [[ "$chosen" == "${LABELS[$i]}"* ]] || [[ "$chosen" == *"${LABELS[$i]}"* ]]; then
        PICK_HEX="${HEXES[$i]}"
        break
    fi
done
# Fallback: first line of chosen if it's a path with index
if [[ -z "$PICK_HEX" ]]; then
    for i in "${!LABELS[@]}"; do
        if [[ "$chosen" == *"$(printf '%02d' "$i")-"* ]]; then
            PICK_HEX="${HEXES[$i]}"
            break
        fi
    done
fi
[[ -n "$PICK_HEX" ]] || exit 0

echo "Applying $THEME primary/source accent: $PICK_HEX"
python3 "$GENERATOR" --apply-accent "$THEME" "$PICK_HEX"

# Live reload chrome
if [[ -x "$RELOAD" ]]; then
    bash "$RELOAD" 2>/dev/null || true
else
    pkill -SIGUSR2 waybar 2>/dev/null || true
    hyprctl reload >/dev/null 2>&1 || true
fi

# Borders pick up source_color from matugen hypr conf
hyprctl eval 'if type(apply_borders) == "function" then apply_borders() end' >/dev/null 2>&1 || true

notify-send -e -u low "Theme accent" "$THEME → $PICK_HEX (primary / active border)" 2>/dev/null || true
exit 0
