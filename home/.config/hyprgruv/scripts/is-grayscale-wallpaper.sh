#!/usr/bin/env bash
# is-grayscale-wallpaper.sh — optional helper to test if an image is B&W
#
# NOT used in the matugen pipeline. Grayscale theming is opt-in only via
# palette.sh → "Dark - Monochrome" (sets ~/.cache/matugen/force-monochrome).
#
# Usage:
#   is-grayscale-wallpaper.sh /path/to/image.png   → exit 0 if mostly greyscale

GRAYSCALE_MAX_SAT_THRESHOLD="${GRAYSCALE_MAX_SAT_THRESHOLD:-0.12}"

is_mostly_grayscale() {
    local img="$1"
    local max_sat

    [[ -f "$img" ]] || return 1
    command -v magick >/dev/null 2>&1 || return 1

    max_sat=$(magick "$img" -colorspace HSL -channel S -separate -format "%[fx:maxima]" info: 2>/dev/null)
    [[ -n "$max_sat" ]] || return 1

    awk "BEGIN { exit !($max_sat < $GRAYSCALE_MAX_SAT_THRESHOLD) }"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    [[ -n "${1:-}" ]] || exit 1
    is_mostly_grayscale "$1"
fi