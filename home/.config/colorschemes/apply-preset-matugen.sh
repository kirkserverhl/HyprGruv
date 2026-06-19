#!/bin/bash
# Run matugen from a static theme seed color (not wallpaper extraction).
# Usage: apply-preset-matugen.sh <theme-name> [wallpaper-path]

set -euo pipefail

THEME="$1"
WALLPAPER="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/matugen"

# shellcheck source=theme-assets.sh
source "$SCRIPT_DIR/theme-assets.sh"

SOURCE_HEX="$(get_source_color "$THEME")"
MATUGEN_MODE="${MATUGEN_MODE:-dark}"
MATUGEN_TYPE="${MATUGEN_TYPE:-scheme-tonal-spot}"

if ! command -v matugen >/dev/null 2>&1; then
    echo "matugen not installed" >&2
    return 1 2>/dev/null || exit 1
fi

mkdir -p "$CACHE_DIR"
rm -f "$CACHE_DIR/force-monochrome" 2>/dev/null || true

jq -n \
    --arg wp "$WALLPAPER" \
    --arg method "hex" \
    --arg mode "$MATUGEN_MODE" \
    --arg type "$MATUGEN_TYPE" \
    --arg source_hex "$SOURCE_HEX" \
    --argjson source_index 0 \
    '{
        wallpaper: $wp,
        method: $method,
        mode: $mode,
        type: $type,
        source_hex: $source_hex,
        source_index: $source_index
    }' >"$CACHE_DIR/pending-run.json"

matugen color hex "$SOURCE_HEX" \
    --mode "$MATUGEN_MODE" \
    --type "$MATUGEN_TYPE" \
    --continue-on-error

"$HOME/.local/bin/matugen-posthook" "${WALLPAPER:-}" 2>/dev/null || true