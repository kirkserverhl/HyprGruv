#!/usr/bin/env bash
# matugen-leftover.sh — matugen json for apps that have no official Super+W preset
#
# Skips templates that apply-theme / --tailored overwrite:
#   starship_rainbow  → colorschemes/<theme>/starship-rainbow.toml
#   kitty             → official kitty theme (when the slot has one)
#   neovim            → official colorscheme or slot mini.base16
#   hyprland          → generate-preset-colors write_hypr
#   obsidian          → obsidian-theme.sh community cssTheme
#
# Waypaper / `matugen image` still uses the full ~/.config/matugen/config.toml.
#
# Usage: matugen-leftover.sh <import.json> [theme-name]

set -euo pipefail

IMPORT="${1:-}"
THEME="${2:-}"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
SRC="$CFG/matugen/config.toml"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/matugen"
DST="$CACHE/config.theme-switcher.toml"
STRIP="$CFG/hyprgruv/scripts/matugen-strip-templates.py"

if [[ -z "$IMPORT" || ! -f "$IMPORT" ]]; then
    echo "matugen-leftover: missing import json: ${IMPORT:-<none>}" >&2
    return 1 2>/dev/null || exit 1
fi
if ! command -v matugen >/dev/null 2>&1; then
    echo "matugen-leftover: matugen not installed" >&2
    return 0 2>/dev/null || exit 0
fi
if [[ ! -f "$SRC" ]]; then
    echo "matugen-leftover: missing $SRC — falling back to default config" >&2
    matugen json "$IMPORT" --continue-on-error || true
    return 0 2>/dev/null || exit 0
fi

SKIP=(starship_rainbow neovim hyprland obsidian)

# Official kitty slot (same rule as write_kitty_tailored).
if [[ -n "$THEME" ]]; then
    kitty_slot="$CFG/colorschemes/$THEME/kitty/colors.conf"
    if [[ -f "$kitty_slot" ]]; then
        include=$(sed -n 's/^[[:space:]]*include[[:space:]]\+custom\/\([^[:space:]]\+\.conf\).*/\1/p' \
            "$kitty_slot" | head -1)
        if [[ -n "$include" && -f "$CFG/kitty/colors/custom/$include" ]]; then
            SKIP+=(kitty)
        elif [[ -z "$include" ]]; then
            SKIP+=(kitty)
        fi
    fi
fi

mkdir -p "$CACHE"
if [[ -f "$STRIP" ]]; then
    python3 "$STRIP" "$SRC" "$DST" "${SKIP[@]}" || cp -f "$SRC" "$DST"
else
    cp -f "$SRC" "$DST"
fi

echo "matugen-leftover: skipping ${SKIP[*]}"
matugen json "$IMPORT" --config "$DST" --continue-on-error || true
