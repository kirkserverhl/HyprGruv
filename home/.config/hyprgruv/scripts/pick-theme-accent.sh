#!/usr/bin/env bash
# pick-theme-accent.sh — Super+W: pick primary from theme palette splotches
#
# Fast: only reads theme base16 accents + rofi. Does NOT apply the full theme
# first (that was applying default orange and blocking this UI for minutes).
#
# Usage:
#   pick-theme-accent.sh <theme-name> [wallpaper]
# Prints chosen #hex to stdout; exit 1 if cancelled.
# Writes colorschemes/<theme>/user-accent for the subsequent apply-theme.
set -euo pipefail

THEME="${1:-}"
GENERATOR="${HOME}/.config/colorschemes/generate-preset-colors.py"
COLORSCHEMES="${HOME}/.config/colorschemes"
ROFI_THEME="${HOME}/.config/rofi/theme-accent-grid.rasi"
[[ -f "$ROFI_THEME" ]] || ROFI_THEME="${HOME}/.config/rofi/color-grid.rasi"

if [[ -z "$THEME" || ! -f "$GENERATOR" ]]; then
    echo "Usage: pick-theme-accent.sh <theme-name> [wallpaper]" >&2
    exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi not found" >&2
    exit 1
fi

# Unset so list-accents never does a heavy THEME_SWITCHER rebuild
unset THEME_SWITCHER_APPLY

mapfile -t LINES < <(python3 "$GENERATOR" --list-accents "$THEME" 2>/dev/null | jq -c '.[]' 2>/dev/null || true)
if ((${#LINES[@]} == 0)); then
    echo "No accents for $THEME" >&2
    exit 1
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
        # Solid splotch only — labels shown as rofi text (faster than annotate)
        magick -size 120x72 "xc:${hex}" -alpha off png32:"$swatch" 2>/dev/null || true
    elif command -v convert >/dev/null 2>&1; then
        convert -size 120x72 "xc:${hex}" "$swatch" 2>/dev/null || true
    fi
    [[ -f "$swatch" ]] || continue
    HEXES+=("$hex")
    LABELS+=("$label")
    ROFI_INPUT+="${label}\0icon\x1f${swatch}\n"
    i=$((i + 1))
done

((${#HEXES[@]})) || exit 1

# Default selection = Orange / primary slot when present (index of Orange label)
default_row=0
for i in "${!LABELS[@]}"; do
    if [[ "${LABELS[$i]}" == "Orange" ]]; then
        default_row=$i
        break
    fi
done

chosen=$(printf '%b' "$ROFI_INPUT" | rofi -dmenu -i -show-icons \
    -p "Primary — $THEME" \
    -mesg "Source color for borders, waybar, starship · Esc = theme default" \
    -theme "$ROFI_THEME" \
    -selected-row "$default_row" \
    -no-custom 2>/dev/null || true)

# Esc / cancel → empty (caller uses theme default)
if [[ -z "${chosen:-}" ]]; then
    exit 1
fi

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
[[ -n "$PICK_HEX" ]] || exit 1

# Persist before any theme apply so apply-theme / generate-preset pick it up
mkdir -p "${COLORSCHEMES}/${THEME}"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/user-accent"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/source-color"

printf '%s\n' "$PICK_HEX"
exit 0
