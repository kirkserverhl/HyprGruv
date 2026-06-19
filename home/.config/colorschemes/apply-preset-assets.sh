#!/bin/bash
# Apply theme colors from saved palette.json (static — no pywal/matugen re-extract).
# Usage: apply-preset-assets.sh <theme-name> [wallpaper-path]
#
# Env:
#   PRESET_SYNC_WALLPAPER=1  opt-in: re-extract from wallpaper via sync-palette-from-wallpaper.sh

set -euo pipefail

THEME="$1"
WALLPAPER="${2:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CACHE_DIR="$HOME/.cache/matugen"
ACTIVE_CONFIG="$HOME/.config/colorschemes/.active-config"
CONFIG_SCRIPT="$SCRIPT_DIR/colors-config.sh"
GENERATOR="$SCRIPT_DIR/generate-preset-colors.py"
SYNC="$SCRIPT_DIR/sync-palette-from-wallpaper.sh"
RELOAD="$HOME/.config/hyprgruv/scripts/reload-matugen-visible.sh"
BUILDER="$HOME/.config/hyprgruv/scripts/palette-build-import.py"

if [[ ! -f "$GENERATOR" ]]; then
    echo "Missing $GENERATOR" >&2
    return 1 2>/dev/null || exit 1
fi

mkdir -p "$CACHE_DIR"
touch "$HOME/.config/colorschemes/.use-preset-colors"

palette_is_usable() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    local unique
    unique=$(jq -r '.base16 // {} | to_entries[] | .value' "$file" 2>/dev/null | tr '[:upper:]' '[:lower:]' | sort -u | wc -l)
    [[ "${unique// /}" -ge 4 ]]
}

# Active saved configuration wins for waypaper/matugen flows — not explicit theme picks.
if [[ "${THEME_SWITCHER_APPLY:-0}" != "1" && -f "$ACTIVE_CONFIG" ]]; then
    local_name=$(tr -d '[:space:]' <"$ACTIVE_CONFIG")
    config_file="$SCRIPT_DIR/configs/${local_name}.json"
    if [[ -f "$config_file" && -x "$CONFIG_SCRIPT" ]] && palette_is_usable "$config_file"; then
        bash "$CONFIG_SCRIPT" apply-static "$THEME" "$config_file" "${WALLPAPER:-}" "$local_name"
        exit 0
    fi
fi

if [[ "${PRESET_SYNC_WALLPAPER:-0}" == "1" ]] && [[ -n "$WALLPAPER" && -f "$WALLPAPER" && -x "$SYNC" ]]; then
    "$SYNC" "$WALLPAPER" "$THEME"
    exit 0
fi

PALETTE_JSON="$HOME/.config/colorschemes/$THEME/palette.json"
if [[ ! -f "$PALETTE_JSON" ]] || ! palette_is_usable "$PALETTE_JSON"; then
    rm -f "$PALETTE_JSON"
    if ! python3 "$GENERATOR" "$THEME"; then
        echo "No usable palette.json for theme: $THEME" >&2
        return 1 2>/dev/null || exit 1
    fi
fi

if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    for f in "$HOME/.config/last_wallpaper.txt" "$HOME/.config/settings/default"; do
        [[ -f "$f" ]] && WALLPAPER=$(tr -d '\n' <"$f") && break
    done
fi

if [[ -x "$CONFIG_SCRIPT" ]]; then
    bash "$CONFIG_SCRIPT" apply-static "$THEME" "$PALETTE_JSON" "${WALLPAPER:-}" ""
    exit 0
fi

if ! python3 "$GENERATOR" "$THEME"; then
    echo "Preset color generation failed for: $THEME" >&2
    return 1 2>/dev/null || exit 1
fi

echo "saved" >"$CACHE_DIR/color-mode"

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" && -f "$BUILDER" ]] && command -v matugen >/dev/null 2>&1; then
    IMPORT_JSON="$CACHE_DIR/saved-import.json"
    python3 "$BUILDER" build-base16 "$PALETTE_JSON" "$WALLPAPER" "$IMPORT_JSON" 2>/dev/null || true
    if [[ -f "$IMPORT_JSON" ]]; then
        matugen image "$WALLPAPER" \
            --import-json "$IMPORT_JSON" \
            --source-color-index 0 \
            --continue-on-error 2>/dev/null || true
    fi
fi

jq -n \
    --arg wp "${WALLPAPER:-}" \
    --arg theme "$THEME" \
    '{
        wallpaper: $wp,
        method: "preset-static",
        color_mode: "saved",
        mode: "dark",
        type: "static-palette",
        theme: $theme
    }' >"$CACHE_DIR/pending-run.json"

if [[ -x "$RELOAD" ]]; then
    "$RELOAD"
fi