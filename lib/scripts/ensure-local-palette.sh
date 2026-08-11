#!/usr/bin/env bash
# ensure-local-palette.sh — machine-local live matugen outputs
#
# Policy:
#   1. If live palette files already exist → leave them (follow current system).
#   2. Else if the user has chosen a theme (.current-theme) → re-apply that.
#   3. Else → default to gruvbox-dark and record it as .current-theme.
#
# Live outputs are gitignored so git-eod cannot ship another machine's palette.
# Called from git-eod-pull after a successful hyprgruv pull.
#
# Usage:
#   ensure-local-palette.sh              # seed only if markers missing
#   ensure-local-palette.sh --force      # always re-apply resolved theme
#   ensure-local-palette.sh --theme NAME # force a specific preset

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
        sed -n '2,16p' "$0"
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

theme_is_valid() {
    local name="$1"
    [[ -n "$name" && -d "$HOME_CFG/colorschemes/$name" ]]
}

# --- resolve theme: explicit > chosen system theme > gruvbox default ---
resolve_theme() {
    local theme=""

    if [[ -n "$THEME_OVERRIDE" ]]; then
        theme="$THEME_OVERRIDE"
        if theme_is_valid "$theme"; then
            printf '%s\n' "$theme"
            return
        fi
        echo "ensure-local-palette: unknown --theme '$theme', falling back" >&2
    fi

    if [[ -f "$CURRENT_THEME_FILE" ]]; then
        theme="$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")"
        if theme_is_valid "$theme"; then
            printf '%s\n' "$theme"
            return
        fi
        if [[ -n "$theme" ]]; then
            echo "ensure-local-palette: .current-theme='$theme' not found, using $DEFAULT_THEME" >&2
        fi
    fi

    printf '%s\n' "$DEFAULT_THEME"
}

if [[ $FORCE -eq 0 ]] && palette_present; then
    # Live system palette already on this machine (matugen or last apply) — keep it.
    exit 0
fi

theme="$(resolve_theme)"

if [[ ! -f "$APPLY" ]]; then
    echo "ensure-local-palette: missing $APPLY" >&2
    exit 1
fi

if [[ "$theme" == "$DEFAULT_THEME" ]] && { [[ ! -f "$CURRENT_THEME_FILE" ]] || [[ -z "$(tr -d '[:space:]' <"$CURRENT_THEME_FILE" 2>/dev/null || true)" ]]; }; then
    echo "ensure-local-palette: no theme chosen — defaulting to $DEFAULT_THEME"
else
    echo "ensure-local-palette: following chosen theme '$theme'"
fi

# THEME_SWITCHER_APPLY skips .active-config override so the named preset wins.
export THEME_SWITCHER_APPLY=1
if ! bash "$APPLY" "$theme"; then
    if [[ "$theme" != "$DEFAULT_THEME" ]]; then
        echo "ensure-local-palette: '$theme' failed — defaulting to $DEFAULT_THEME" >&2
        bash "$APPLY" "$DEFAULT_THEME"
        theme="$DEFAULT_THEME"
    else
        exit 1
    fi
fi

# Persist default so later pulls "follow system" instead of re-deciding blindly.
mkdir -p "$(dirname "$CURRENT_THEME_FILE")"
if [[ ! -f "$CURRENT_THEME_FILE" ]] || [[ -z "$(tr -d '[:space:]' <"$CURRENT_THEME_FILE" 2>/dev/null || true)" ]]; then
    printf '%s\n' "$theme" >"$CURRENT_THEME_FILE"
fi

# Refresh gum/toilet shell cache + SDDM greeter colors from live palette.
if [[ -f "$HOME_CFG/hyprgruv/scripts/colors.sh" ]]; then
    # shellcheck source=/dev/null
    source "$HOME_CFG/hyprgruv/scripts/colors.sh" --gum 2>/dev/null || true
    if declare -F write_matugen_shell_color_cache >/dev/null 2>&1; then
        write_matugen_shell_color_cache 2>/dev/null || true
    fi
fi
if [[ -x "$HOME_CFG/hyprgruv/scripts/update-sddm-wallpaper.sh" || -f "$HOME_CFG/hyprgruv/scripts/update-sddm-wallpaper.sh" ]]; then
    bash "$HOME_CFG/hyprgruv/scripts/update-sddm-wallpaper.sh" 2>/dev/null \
        || echo "ensure-local-palette: SDDM color sync skipped (run update-sddm-wallpaper.sh after login)" >&2
fi
