#!/usr/bin/env bash
# sync-palette-from-wallpaper.sh — spectrum-scale extract → theme palette.json → outputs
#
# Colors are literal wallpaper hues in reversed rainbow order (purple → … → red).
# Starship, Waybar, and Hyprbars share the same inward column map (see spectrum-scale.json).
# Usage: sync-palette-from-wallpaper.sh /path/to/wallpaper.png <theme-id>

set -euo pipefail

WALLPAPER="${1:-}"
THEME="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILDER="$HOME/.config/hyprgruv/scripts/palette-build-import.py"
GENERATOR="$SCRIPT_DIR/generate-preset-colors.py"
THEME_DIR="$HOME/.config/colorschemes/$THEME"
PALETTE_JSON="$THEME_DIR/palette.json"
CACHE_DIR="$HOME/.cache/matugen"

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "sync-palette-from-wallpaper: missing wallpaper" >&2
    exit 1
fi

if [[ -z "$THEME" || ! -d "$THEME_DIR" ]]; then
    echo "sync-palette-from-wallpaper: unknown theme '$THEME'" >&2
    exit 1
fi

if ! command -v wal >/dev/null 2>&1; then
    echo "sync-palette-from-wallpaper: pywal (wal) required" >&2
    exit 1
fi

mkdir -p "$CACHE_DIR" "$THEME_DIR"
touch "$HOME/.config/colorschemes/.use-preset-colors"
echo "preset:$THEME" >"$CACHE_DIR/yazi-icon-mode"
echo "wallpaper" >"$CACHE_DIR/color-mode"

python3 "$BUILDER" export-theme "$WALLPAPER" "$THEME" "$PALETTE_JSON"

python3 "$GENERATOR" --prepare "$THEME"

# Official presets first (starship/kitty/nvim/hypr). Leftover matugen after.
python3 "$GENERATOR" --tailored "$THEME"

IMPORT_JSON="$CACHE_DIR/wal-import.json"
leftover="$HOME/.config/hyprgruv/scripts/matugen-leftover.sh"
python3 "$BUILDER" build "$WALLPAPER" "$IMPORT_JSON" spectrum-scale
if command -v matugen >/dev/null 2>&1 && [[ -f "$IMPORT_JSON" ]]; then
    if [[ -f "$leftover" ]]; then
        bash "$leftover" "$IMPORT_JSON" "$THEME" || true
    else
        matugen json "$IMPORT_JSON" --continue-on-error 2>/dev/null || true
    fi
fi

jq -n \
    --arg wp "$WALLPAPER" \
    --arg theme "$THEME" \
    '{
        wallpaper: $wp,
        method: "wallpaper",
        color_mode: "wallpaper",
        mode: "dark",
        type: "spectrum-scale",
        theme: $theme
    }' >"$CACHE_DIR/pending-run.json"

cp -f "$PALETTE_JSON" "$CACHE_DIR/current-palette.json" 2>/dev/null || true

"$HOME/.local/bin/matugen-posthook" "$WALLPAPER" 2>/dev/null || true
"$HOME/.config/hyprgruv/scripts/reload-matugen-visible.sh" 2>/dev/null || true

echo "Palette synced from wallpaper → $THEME (spectrum-scale, image-only hues)"