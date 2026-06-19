#!/usr/bin/env bash
# base16-palette.sh — Base16 color reference for matugen templates
#
# Shows the current base00–base0f palette in rofi:
#   left column  → shades  (00–07)
#   right column → accents (08–0f)
#
# Pick a swatch to copy its hex to the clipboard.

set -euo pipefail

readonly GTK_COLORS="${HOME}/.config/gtk-4.0/colors.css"
readonly GTK_COLORS_ALT="${HOME}/.config/gtk-3.0/colors.css"
readonly NVIM_THEME="${HOME}/.config/nvim/lua/matugen-theme.lua"
readonly MATUGEN_JSON="${HOME}/.cache/matugen/current.json"
readonly ROFI_THEME="${HOME}/.config/rofi/base16-grid.rasi"

declare -A BASE16_HEX=()
declare -A BASE16_HINTS=(
    [BASE00]="darkest background"
    [BASE01]="lighter bg · borders"
    [BASE02]="selection · active ws"
    [BASE03]="muted · comments"
    [BASE04]="status · dim fg"
    [BASE05]="default text"
    [BASE06]="light foreground"
    [BASE07]="bright highlights"
    [BASE08]="red · errors · urgent"
    [BASE09]="tertiary"
    [BASE0A]="secondary"
    [BASE0B]="primary"
    [BASE0C]="tertiary container"
    [BASE0D]="accent · primary"
    [BASE0E]="secondary container"
    [BASE0F]="source color"
)

SLOTS=(
    BASE00 BASE01 BASE02 BASE03 BASE04 BASE05 BASE06 BASE07
    BASE08 BASE09 BASE0A BASE0B BASE0C BASE0D BASE0E BASE0F
)

_slot_label() {
    printf '%s' "${1,,}"
}

_parse_gtk_css() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    local line slot hex
    while IFS= read -r line; do
        [[ "$line" =~ @define-color[[:space:]]+(base0[0-9A-Fa-f])[[:space:]]+#([0-9A-Fa-f]{6}) ]] || continue
        slot="${BASH_REMATCH[1]}"
        hex="#${BASH_REMATCH[2]}"
        slot="${slot^^}"
        BASE16_HEX["$slot"]="$hex"
    done < "$file"
}

_parse_nvim_lua() {
    local file="$1"
    [[ -f "$file" ]] || return 1

    local line slot hex
    while IFS= read -r line; do
        [[ "$line" =~ base0[0-9A-Fa-f][[:space:]]*=[[:space:]]*\"#([0-9A-Fa-f]{6})\" ]] || continue
        slot=$(grep -oE 'base0[0-9A-Fa-f]' <<< "$line" | head -1)
        hex="#${BASH_REMATCH[1]}"
        slot="${slot^^}"
        [[ -z "${BASE16_HEX[$slot]:-}" ]] && BASE16_HEX["$slot"]="$hex"
    done < "$file"
}

_parse_matugen_json() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    command -v jq >/dev/null 2>&1 || return 1

    local slot hex
    for slot in "${SLOTS[@]}"; do
        [[ -n "${BASE16_HEX[$slot]:-}" ]] && continue
        hex=$(jq -r --arg s "$(_slot_label "$slot")" '.base16[$s].dark.color // empty' "$file" 2>/dev/null || true)
        [[ -n "$hex" && "$hex" != "null" ]] && BASE16_HEX["$slot"]="$hex"
    done
}

_load_palette() {
    _parse_gtk_css "$GTK_COLORS" || _parse_gtk_css "$GTK_COLORS_ALT" || true
    _parse_nvim_lua "$NVIM_THEME" || true
    _parse_matugen_json "$MATUGEN_JSON" || true

    local slot
    for slot in "${SLOTS[@]}"; do
        [[ -n "${BASE16_HEX[$slot]:-}" ]] || BASE16_HEX["$slot"]="#444444"
    done
}

_copy_hex() {
    local hex="$1"
    if command -v wl-copy >/dev/null 2>&1; then
        printf '%s' "$hex" | wl-copy
    elif command -v xclip >/dev/null 2>&1; then
        printf '%s' "$hex" | xclip -selection clipboard
    else
        return 1
    fi
}

main() {
    if ! command -v rofi >/dev/null 2>&1; then
        notify-send -u critical "Base16 Palette" "rofi not found in PATH" 2>/dev/null || true
        exit 1
    fi

    _load_palette

    local swatch_dir
    swatch_dir=$(mktemp -d /tmp/base16-palette-XXXXXX)
    trap 'rm -rf "$swatch_dir" 2>/dev/null || true' EXIT

    local input="" slot hex hint swatch label chosen
    for slot in "${SLOTS[@]}"; do
        hex="${BASE16_HEX[$slot]}"
        hint="${BASE16_HINTS[$slot]}"
        swatch="${swatch_dir}/${slot}.png"

        if command -v magick >/dev/null 2>&1; then
            magick -size 40x40 "xc:${hex}" \
                -bordercolor "#2a2a2a" -border 2 \
                -alpha off png32:"$swatch" 2>/dev/null || \
            magick -size 40x40 xc:"#333333" -alpha off png32:"$swatch"
        else
            convert -size 40x40 "xc:${hex}" "$swatch" 2>/dev/null || true
        fi

        label=$(printf '%s  %s  %s' "$(_slot_label "$slot")" "$hex" "$hint")
        input+="${label}\0icon\x1f${swatch}\n"
    done

    chosen=$(printf '%b' "$input" | \
        rofi -dmenu -i -show-icons \
            -p "Base16 palette (pick to copy hex)" \
            -theme "$ROFI_THEME" \
            -no-custom 2>/dev/null || true)

    [[ -z "$chosen" ]] && exit 0

    local copied_hex=""
    if [[ "$chosen" =~ (#[0-9A-Fa-f]{6}) ]]; then
        copied_hex="${BASH_REMATCH[1]}"
    fi

    [[ -z "$copied_hex" ]] && exit 0

    if _copy_hex "$copied_hex"; then
        notify-send -a matugen "Base16" "Copied ${copied_hex}" 2>/dev/null || true
    fi
}

main "$@"