#!/usr/bin/env bash
# obsidian-theme.sh — switch Obsidian community theme (cssTheme) to match system theme
#
# Usage:
#   obsidian-theme.sh [theme-id]
#
# With no argument, reads ~/.config/colorschemes/.current-theme.
# Updates appearance.json in every discovered vault that has the target theme installed.

set -euo pipefail

THEME="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COLORS_DIR="$HOME/.config/colorschemes"
CURRENT_THEME_FILE="$COLORS_DIR/.current-theme"

# shellcheck source=/dev/null
source "$COLORS_DIR/theme-assets.sh"

if [[ -z "$THEME" && -f "$CURRENT_THEME_FILE" ]]; then
    THEME=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
fi

if [[ -z "$THEME" ]]; then
    exit 0
fi

CSS_THEME=$(resolve_obsidian_css_theme "$THEME" 2>/dev/null || true)
if [[ -z "$CSS_THEME" ]]; then
    exit 0
fi

discover_obsidian_vaults() {
    local vault seen="" dir

    add_vault() {
        local candidate="$1"
        [[ -d "$candidate/.obsidian" ]] || return 0
        case " $seen " in
        *" $candidate "*) return 0 ;;
        esac
        seen="${seen:+$seen }$candidate"
        printf '%s\n' "$candidate"
    }

    for vault in \
        "$HOME/notes/Work Notes" \
        "$HOME/Documents/Obsidian" \
        "$HOME/Obsidian" \
        "$HOME/vaults" \
        "$HOME/Documents/hyprcourse/Hyprland"; do
        add_vault "$vault"
    done

    if [[ -d "$HOME/notes" ]]; then
        while IFS= read -r -d '' dir; do
            add_vault "$(dirname "$dir")"
        done < <(find "$HOME/notes" -mindepth 1 -maxdepth 4 -type d -name .obsidian -print0 2>/dev/null)
    fi
}

updated=0
while IFS= read -r vault; do
    [[ -n "$vault" ]] || continue
    appearance="$vault/.obsidian/appearance.json"
    theme_dir="$vault/.obsidian/themes/$CSS_THEME"
    [[ -d "$theme_dir" ]] || continue
    [[ -f "$appearance" ]] || continue

    python3 - "$appearance" "$CSS_THEME" <<'PY'
import json
import os
import sys

path, css_theme = sys.argv[1:3]
data = {}
if os.path.isfile(path):
    with open(path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            data = {}

if data.get("cssTheme") == css_theme:
    sys.exit(2)

data["cssTheme"] = css_theme
if not data.get("theme"):
    data["theme"] = "obsidian"

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
    rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "[obsidian] $vault → cssTheme: $CSS_THEME"
        updated=$((updated + 1))
    fi
done < <(discover_obsidian_vaults)

if [[ "$updated" -gt 0 ]]; then
    exit 0
fi