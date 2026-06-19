#!/usr/bin/env bash
# wal-to-matugen-import.sh — build matugen --import-json from pywal cache
#
# Runs pywal on the wallpaper (unless WAL_SKIP=1), maps color0–color15 to base16
# using the standard pywal↔base16 slot order, then maps base16 → Material You
# semantic roles so existing matugen templates keep working without pastels.
#
# Usage: wal-to-matugen-import.sh /path/to/wallpaper.png [output.json]

set -euo pipefail

WALLPAPER="${1:-}"
OUT="${2:-$HOME/.cache/matugen/wal-import.json}"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "wal-to-matugen-import: no valid wallpaper" >&2
    exit 1
fi

if ! command -v wal >/dev/null 2>&1; then
    echo "wal-to-matugen-import: pywal (wal) not installed" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUT")"

WAL_JSON="${HOME}/.cache/wal/colors.json"
need_wal=1
if [[ "${WAL_SKIP:-0}" == "1" && -f "$WAL_JSON" ]]; then
    cached_wp=$(jq -r '.wallpaper // empty' "$WAL_JSON" 2>/dev/null || true)
    if [[ -n "$cached_wp" && "$cached_wp" == "$WALLPAPER" ]]; then
        need_wal=0
    fi
fi

if [[ "$need_wal" -eq 1 ]]; then
    wal -i "$WALLPAPER" -n -q </dev/null 2>/dev/null || wal -i "$WALLPAPER" -n -q </dev/null
fi

if [[ ! -f "$WAL_JSON" ]]; then
    echo "wal-to-matugen-import: missing $WAL_JSON after wal run" >&2
    exit 1
fi

cached_wp=$(jq -r '.wallpaper // empty' "$WAL_JSON" 2>/dev/null || true)
if [[ -z "$cached_wp" || "$cached_wp" != "$WALLPAPER" ]]; then
    echo "wal-to-matugen-import: wal cache is for '$cached_wp', expected '$WALLPAPER'" >&2
    exit 1
fi

BUILDER="$HOME/.config/hyprgruv/scripts/palette-build-import.py"
SOURCE="${PALETTE_SOURCE:-wal}"
if [[ -f "$HOME/.config/matugen/user-palette.json" ]]; then
    saved_wp=$(jq -r '.wallpaper // empty' "$HOME/.config/matugen/user-palette.json" 2>/dev/null || true)
    if [[ -n "$saved_wp" && "$saved_wp" == "$WALLPAPER" ]]; then
        SOURCE="custom"
    fi
fi

if [[ -x "$BUILDER" ]]; then
    "$BUILDER" build "$WALLPAPER" "$OUT" "$SOURCE"
    exit 0
fi

echo "wal-to-matugen-import: missing $BUILDER" >&2
exit 1