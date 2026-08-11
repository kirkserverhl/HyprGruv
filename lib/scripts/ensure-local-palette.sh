#!/usr/bin/env bash
# ensure-local-palette.sh — keep live matugen outputs machine-local
#
# After git-eod-pull (or a fresh clone), active palette files may be missing
# because they are gitignored. Re-apply the last chosen theme, or gruvbox-dark.
#
# Usage:
#   ensure-local-palette.sh           # only if starship/nvim palette missing
#   ensure-local-palette.sh --force   # always re-apply
#   ensure-local-palette.sh --theme gruvbox-dark

set -euo pipefail

FORCE=0
THEME_OVERRIDE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
    --force) FORCE=1; shift ;;
    --theme)
        [[ $# -ge 2 ]] || {
            echo "Missing value for --theme" >&2
            exit 1
        }
        THEME_OVERRIDE="$2"
        shift 2
        ;;
    -h | --help)
        sed -n '2,12p' "$0"
        exit 0
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
done

HOME_CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
MARKER_NVIM="$HOME_CFG/nvim/lua/matugen-theme.lua"
MARKER_SHIP="$HOME_CFG/starship/matugen-rainbow.toml"
CURRENT_THEME_FILE="$HOME_CFG/colorschemes/.current-theme"
APPLY="$HOME_CFG/colorschemes/apply-theme.sh"
DEFAULT_THEME="gruvbox-dark"

palette_present() {
    [[ -f "$MARKER_NVIM" && -s "$MARKER_NVIM" && -f "$MARKER_SHIP" && -s "$MARKER_SHIP" ]]
}

if [[ $FORCE -eq 0 ]] && palette_present; then
    # Already have a local active palette — do not clobber machine choice.
    exit 0
fi

theme="${THEME_OVERRIDE:-}"
if [[ -z "$theme" && -f "$CURRENT_THEME_FILE" ]]; then
    theme="$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")"
fi
[[ -n "$theme" ]] || theme="$DEFAULT_THEME"

# Prefer a known preset directory; fall back to gruvbox-dark.
if [[ ! -d "$HOME_CFG/colorschemes/$theme" ]]; then
    theme="$DEFAULT_THEME"
fi

if [[ ! -x "$APPLY" && ! -f "$APPLY" ]]; then
    echo "ensure-local-palette: missing $APPLY" >&2
    exit 1
fi

echo "ensure-local-palette: applying theme '$theme' (live palette machine-local)"
# THEME_SWITCHER_APPLY skips .active-config override so the named preset wins.
export THEME_SWITCHER_APPLY=1
bash "$APPLY" "$theme" || {
    if [[ "$theme" != "$DEFAULT_THEME" ]]; then
        echo "ensure-local-palette: '$theme' failed — trying $DEFAULT_THEME" >&2
        bash "$APPLY" "$DEFAULT_THEME"
    else
        exit 1
    fi
}
