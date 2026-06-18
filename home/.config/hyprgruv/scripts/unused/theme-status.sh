#!/usr/bin/env bash
# theme-status.sh — quick check: wallpaper vs matugen vs starship vs kitty
# Usage: theme-status

set -euo pipefail

WP_CACHE="$HOME/.config/last_wallpaper.txt"
STARSHIP_CFG="${STARSHIP_CONFIG:-$HOME/.config/starship/matugen-rainbow.toml}"
KITTY_CFG="$HOME/.config/kitty/colors.conf"

wp="(unknown)"
if [[ -f "$WP_CACHE" ]]; then
    wp=$(cat "$WP_CACHE")
fi

src="(n/a)"
primary="(n/a)"
extractor="$HOME/.config/hyprgruv/scripts/extract-good-source-colors.sh"
if [[ -f "$wp" ]] && command -v matugen >/dev/null 2>&1; then
    if [[ -x "$extractor" ]]; then
        src=$("$extractor" "$wp" 1 2>/dev/null | head -1)
    fi
    if [[ -n "$src" && "$src" != "(n/a)" ]]; then
        primary=$(matugen color hex "$src" --mode dark --type scheme-tonal-spot --dry-run --json hex 2>/dev/null \
            | jq -r '.colors.primary.default.color // empty' 2>/dev/null || true)
    fi
fi

starship_orange="(missing)"
if [[ -f "$STARSHIP_CFG" ]]; then
    starship_orange=$(grep -m1 '^color_orange' "$STARSHIP_CFG" | sed -E "s/.*= *['\"]?([^'\"]+)['\"]?.*/\1/")
fi

kitty_bg="(missing)"
kitty_cursor="(missing)"
if [[ -f "$KITTY_CFG" ]]; then
    kitty_bg=$(grep -m1 '^background' "$KITTY_CFG" | awk '{print $2}')
    kitty_cursor=$(grep -m1 '^cursor ' "$KITTY_CFG" | awk '{print $2}')
fi

osc_bg="(n/a)"
if [[ -f "$HOME/.config/terminal-sequences" ]]; then
    osc_bg=$(grep -m1 $'^\e]11;' "$HOME/.config/terminal-sequences" 2>/dev/null | sed 's/.*;//;s/\e\\$//' || true)
    [[ -z "$osc_bg" ]] && osc_bg="(n/a)"
fi

active_starship="(none)"
if [[ -L "$HOME/.config/starship.toml" ]]; then
    active_starship=$(readlink -f "$HOME/.config/starship.toml" 2>/dev/null || echo "broken symlink")
elif [[ -f "$HOME/.config/starship.toml" ]]; then
    active_starship="$HOME/.config/starship.toml"
fi

manifest="$HOME/.cache/matugen/last-run.json"
cache_note=""
if [[ -f "$manifest" ]]; then
    cache_mode=$(jq -r '.mode // "unknown"' "$manifest" 2>/dev/null || echo unknown)
    cache_at=$(jq -r '.ran_at // "unknown"' "$manifest" 2>/dev/null || echo unknown)
    cache_note="last run: $cache_mode @ ${cache_at#*T}"
fi

echo "Theme status"
echo "──────────────"
[[ -n "$cache_note" ]] && echo "Cache     : $cache_note"
echo "Logs      : ~/.cache/matugen/matugen.log  (~/.cache/matugen/runs/)"
echo "Wallpaper : $(basename "$wp")"
echo "Source #1 : $src  (extract-good-source-colors)"
echo "Primary   : $primary"
echo ""
echo "Starship  : $starship_orange  (color_orange in $(basename "$STARSHIP_CFG"))"
echo "Kitty bg  : $kitty_bg  (cursor $kitty_cursor)"
echo "OSC bg    : $osc_bg  (terminal-sequences — ignored in kitty)"
echo "Active cfg: $(basename "$active_starship")"
echo ""

if [[ -n "${KITTY_WINDOW_ID:-}" ]]; then
    echo "ℹ Kitty reloads instantly; starship updates on the next prompt (press Enter)."
    echo "  Kitty still wrong?  bash ~/.config/hyprgruv/scripts/reload-kitty-colors.sh"
    echo ""
fi

if [[ "$primary" != "(n/a)" && "$starship_orange" != "(missing)" ]]; then
    if [[ "$primary" == "$starship_orange" ]]; then
        echo "✓ Starship matches matugen primary"
    else
        echo "⚠ Starship may be stale (primary $primary ≠ starship $starship_orange)"
        echo "  Fix: change wallpaper once, or run:"
        echo "    bash ~/.config/hyprgruv/scripts/set_wallpaper.sh"
    fi
fi

if [[ "${STARSHIP_CFG##*/}" != "$(basename "$active_starship")" ]]; then
    echo "⚠ Active starship.toml is not matugen-rainbow — wallpaper won't change the prompt."
    echo "  Fix: ~/.config/starship/theme.sh  → pick matugen"
fi