#!/usr/bin/env bash
# pick-theme-accent.sh — Super+W: source/primary color from theme palette
#
# Only choice after theme pick. Fast: list accents + rofi. Never applies themes.
# Magick swatches best-effort; text fallback if ImageMagick missing/busy.
#
# Usage:
#   pick-theme-accent.sh <theme-name>
# Prints chosen #hex; exit 1 if cancelled (caller uses theme default).
# Writes user-accent + source-color for apply-theme standard assets.
set -euo pipefail

THEME="${1:-}"
GENERATOR="${HOME}/.config/colorschemes/generate-preset-colors.py"
COLORSCHEMES="${HOME}/.config/colorschemes"
ROFI_THEME="${HOME}/.config/rofi/theme-accent-grid.rasi"
[[ -f "$ROFI_THEME" ]] || ROFI_THEME="${HOME}/.config/rofi/color-grid.rasi"

if [[ -z "$THEME" || ! -f "$GENERATOR" ]]; then
    echo "Usage: pick-theme-accent.sh <theme-name>" >&2
    exit 1
fi

if ! command -v rofi >/dev/null 2>&1; then
    echo "rofi not found" >&2
    exit 1
fi

# Never inherit a heavy rebuild path from the parent shell
unset THEME_SWITCHER_APPLY

mapfile -t LINES < <(python3 "$GENERATOR" --list-accents "$THEME" 2>/dev/null | jq -c '.[]' 2>/dev/null || true)
if ((${#LINES[@]} == 0)); then
    echo "No accents for $THEME" >&2
    exit 1
fi

SWATCH_DIR=""
USE_ICONS=0
if command -v magick >/dev/null 2>&1 || command -v convert >/dev/null 2>&1; then
    SWATCH_DIR=$(mktemp -d /tmp/theme-accent-XXXXXX)
    trap 'rm -rf "$SWATCH_DIR" 2>/dev/null || true' EXIT
    USE_ICONS=1
fi

ROFI_INPUT=""
declare -a HEXES=()
declare -a LABELS=()
i=0
for line in "${LINES[@]}"; do
    hex=$(jq -r '.hex' <<<"$line")
    label=$(jq -r '.label' <<<"$line")
    [[ -n "$hex" && "$hex" != "null" ]] || continue
    HEXES+=("$hex")
    LABELS+=("$label")

    if [[ "$USE_ICONS" -eq 1 ]]; then
        swatch="$SWATCH_DIR/$(printf '%02d' "$i")-${label}.png"
        # Timeout so a stuck magick never blocks the accent UI
        # Square swatches — names stay in the dmenu text (for matching) but the
        # theme hides element-text so palettes without a shared Red/Green/Blue
        # set don't look inconsistent.
        if command -v magick >/dev/null 2>&1; then
            timeout 1 magick -size 112x112 "xc:${hex}" -alpha off png32:"$swatch" 2>/dev/null || true
        else
            timeout 1 convert -size 112x112 "xc:${hex}" "$swatch" 2>/dev/null || true
        fi
        if [[ -f "$swatch" ]]; then
            ROFI_INPUT+="${label}\0icon\x1f${swatch}\n"
        else
            ROFI_INPUT+="${label}  ${hex}\n"
        fi
    else
        ROFI_INPUT+="${label}  ${hex}\n"
    fi
    i=$((i + 1))
done

((${#HEXES[@]})) || exit 1

# Default row = Orange when present (gruvbox primary), else first
default_row=0
for i in "${!LABELS[@]}"; do
    if [[ "${LABELS[$i]}" == "Orange" ]]; then
        default_row=$i
        break
    fi
done

rofi_args=(
    -dmenu -i
    -p ""
    -mesg "Select Primary Color"
    -theme "$ROFI_THEME"
    -selected-row "$default_row"
    -no-custom
)
# Only request icons when we actually produced swatches
if [[ "$USE_ICONS" -eq 1 ]] && compgen -G "$SWATCH_DIR"/*.png >/dev/null 2>&1; then
    rofi_args+=(-show-icons)
fi

# Clear any leftover THEME_SWITCHER so rofi theme CSS is not blocked
chosen=$(printf '%b' "$ROFI_INPUT" | rofi "${rofi_args[@]}" 2>/dev/null || true)

# Esc / cancel → empty (caller uses theme default)
if [[ -z "${chosen:-}" ]]; then
    exit 1
fi

# Match label (with or without trailing "  #hex")
PICK_HEX=""
for i in "${!LABELS[@]}"; do
    if [[ "$chosen" == "${LABELS[$i]}" ]] || [[ "$chosen" == "${LABELS[$i]}"* ]]; then
        PICK_HEX="${HEXES[$i]}"
        break
    fi
done
if [[ -z "$PICK_HEX" ]]; then
    # bare hex paste / fallback
    cand=$(grep -oE '#[0-9a-fA-F]{6}' <<<"$chosen" | head -1 || true)
    [[ -n "$cand" ]] && PICK_HEX="${cand,,}"
fi
[[ -n "$PICK_HEX" ]] || exit 1

# Persist before any theme apply so apply-theme / generate-preset pick it up
mkdir -p "${COLORSCHEMES}/${THEME}"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/user-accent"
printf '%s\n' "$PICK_HEX" >"${COLORSCHEMES}/${THEME}/source-color"

printf '%s\n' "$PICK_HEX"
exit 0
