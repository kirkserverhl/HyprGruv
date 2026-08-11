#!/usr/bin/env bash
# pick-theme-accent.sh — Super+W step 3: theme-palette primary + full chrome rebuild
#
# After theme + wallpaper are applied, show fixed theme accent splotches
# (Gruvbox: red, purple, yellow, green, aqua, orange, blue — not wallpaper extract).
# On pick: set base0D/base0F, then FULL rebuild (preset assets + reload).
#
# Usage:
#   pick-theme-accent.sh <theme-name> [wallpaper-path]
# Escape = keep theme default primary (already applied).
set -euo pipefail

THEME="${1:-}"
WALLPAPER="${2:-}"
COLORSCHEMES="${HOME}/.config/colorschemes"
GENERATOR="${COLORSCHEMES}/generate-preset-colors.py"
CONFIG_SCRIPT="${COLORSCHEMES}/colors-config.sh"
RELOAD="${HOME}/.config/hyprgruv/scripts/reload-matugen-visible.sh"
ROFI_THEME="${HOME}/.config/rofi/theme-accent-grid.rasi"
[[ -f "$ROFI_THEME" ]] || ROFI_THEME="${HOME}/.config/rofi/color-grid.rasi"

# Never force-canonical rebuild here (would wipe the accent we just wrote).
unset THEME_SWITCHER_APPLY

if [[ -z "$THEME" || ! -f "$GENERATOR" ]]; then
    echo "Usage: pick-theme-accent.sh <theme-name> [wallpaper]" >&2
    exit 0
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi not found — skipping accent pick" >&2
    exit 0
fi

mapfile -t LINES < <(python3 "$GENERATOR" --list-accents "$THEME" 2>/dev/null | jq -c '.[]' 2>/dev/null || true)
if ((${#LINES[@]} == 0)); then
    echo "No accents for theme $THEME — skipping" >&2
    exit 0
fi

SWATCH_DIR=$(mktemp -d /tmp/theme-accent-XXXXXX)
trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT

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
    -p "Primary color — $THEME" \
    -mesg "Active window · waybar · starship · Escape = theme default" \
    -theme "$ROFI_THEME" \
    -no-custom 2>/dev/null || true)

[[ -z "${chosen:-}" ]] && exit 0

PICK_HEX=""
for i in "${!LABELS[@]}"; do
    if [[ "$chosen" == "${LABELS[$i]}" ]] || [[ "$chosen" == "${LABELS[$i]}"* ]]; then
        PICK_HEX="${HEXES[$i]}"
        break
    fi
done
if [[ -z "$PICK_HEX" ]]; then
    for i in "${!LABELS[@]}"; do
        if [[ "$chosen" == *"$(printf '%02d' "$i")-"* ]]; then
            PICK_HEX="${HEXES[$i]}"
            break
        fi
    done
fi
[[ -n "$PICK_HEX" ]] || exit 0

echo "Accent $PICK_HEX — writing primary/source and full rebuild…"
python3 "$GENERATOR" --apply-accent "$THEME" "$PICK_HEX"

PALETTE_JSON="${COLORSCHEMES}/${THEME}/palette.json"
if [[ ! -f "$PALETTE_JSON" ]]; then
    echo "Missing $PALETTE_JSON after accent apply" >&2
    exit 0
fi

# Resolve wallpaper for matugen import path (templates need an image path)
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    for f in "$HOME/.config/last_wallpaper.txt" "$HOME/.config/settings/default"; do
        [[ -f "$f" ]] || continue
        WALLPAPER=$(tr -d '\n' <"$f")
        [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]] && break
    done
fi

# Full static rebuild from palette.json (includes matugen import + spectrum restore + reload).
# Must NOT set THEME_SWITCHER_APPLY — that forces canonical orange and undoes the accent.
if [[ -x "$CONFIG_SCRIPT" && -n "${WALLPAPER:-}" && -f "$WALLPAPER" ]]; then
    echo "Rebuilding system chrome from palette + accent…"
    bash "$CONFIG_SCRIPT" apply-static "$THEME" "$PALETTE_JSON" "$WALLPAPER" "" || true
else
    # Fallback: generator already wrote files; still reload visible apps
    if [[ -x "$RELOAD" ]]; then
        bash "$RELOAD" 2>/dev/null || true
    else
        pkill -SIGUSR2 waybar 2>/dev/null || true
        hyprctl reload >/dev/null 2>&1 || true
    fi
fi

# Ensure borders pick up $source_color from hypr matugen conf
hyprctl reload >/dev/null 2>&1 || true
sleep 0.15
hyprctl eval 'if type(apply_borders) == "function" then apply_borders() end' >/dev/null 2>&1 || true
pkill -SIGUSR1 nvim 2>/dev/null || true

notify-send -e -u low "Theme accent" "$THEME → $PICK_HEX (rebuilt)" 2>/dev/null || true
exit 0
