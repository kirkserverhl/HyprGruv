#!/usr/bin/env bash
# reload-yazi-theme.sh — switch Yazi flavor to match the active colorscheme theme
#
# Yazi 26.5+ merges flavors from ~/.config/yazi/flavors/*.yazi with this file.
# Keep theme.toml limited to [flavor]; edit flavor.toml files for per-theme tweaks.
#
# Usage:
#   reload-yazi-theme.sh                 switch to .current-theme + hot-reload
#   reload-yazi-theme.sh --switch NAME   switch to a specific theme id + hot-reload
#   reload-yazi-theme.sh --reload        hot-reload running instances only
#   reload-yazi-theme.sh --flavor NAME   set flavor directly (no theme mapping)

set -euo pipefail

THEME_FILE="${HOME}/.config/yazi/theme.toml"
CURRENT_THEME_FILE="${HOME}/.config/colorschemes/.current-theme"
FLAVORS_DIR="${HOME}/.config/yazi/flavors"

resolve_yazi_flavor() {
    local theme="${1:-}"
    if [[ -z "$theme" && -f "$CURRENT_THEME_FILE" ]]; then
        theme=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
    fi

    case "$theme" in
    catppuccin) echo "catppuccin-mocha" ;;
    nord-darker | nord) echo "nord" ;;
    everforest-dark | forest-night) echo "everforest-medium" ;;
    gruvbox-dark | coast-gruv | warm-stone) echo "gruvbox-dark" ;;
    gruvbox-light) echo "gruvbox-light" ;;
    noir | e-ink) echo "catppuccin-mocha" ;;
    "")
        echo "catppuccin-mocha"
        ;;
    *)
        if [[ -d "${FLAVORS_DIR}/${theme}.yazi" ]]; then
            echo "$theme"
        else
            echo "catppuccin-mocha"
        fi
        ;;
    esac
}

write_theme_flavor() {
    local flavor="$1"
    local theme_id="${2:-}"

    [[ -d "${FLAVORS_DIR}/${flavor}.yazi" ]] || {
        echo "[reload-yazi] Flavor not installed: ${flavor}.yazi" >&2
        echo "[reload-yazi] Run: ya pkg add <owner>/<flavor>" >&2
        return 1
    }

    cat >"$THEME_FILE" <<EOF
# Managed by reload-yazi-theme.sh — do not edit [flavor] by hand.
# Switch via theme picker or: reload-yazi-theme.sh --switch <theme-name>

[flavor]
dark  = "${flavor}"
light = "${flavor}"
EOF

    if [[ -n "$theme_id" ]]; then
        echo "flavor:${flavor}" >"${HOME}/.cache/matugen/yazi-flavor-mode"
        echo "preset:${theme_id}" >"${HOME}/.cache/matugen/yazi-icon-mode"
    fi
}

switch_theme() {
    local theme="${1:-}"
    local flavor
    flavor=$(resolve_yazi_flavor "$theme")
    write_theme_flavor "$flavor" "${theme:-$(tr -d '[:space:]' <"$CURRENT_THEME_FILE" 2>/dev/null || true)}"
    echo "[reload-yazi] flavor=${flavor} theme=${theme:-current}"
}

reload_instances() {
    command -v ya >/dev/null 2>&1 || return 0
    ya emit-to 0 app:theme 2>/dev/null || true
}

case "${1:-}" in
--switch)
    switch_theme "${2:-}"
    reload_instances
    ;;
--flavor)
    write_theme_flavor "${2:?flavor name required}"
    reload_instances
    ;;
--reload)
    reload_instances
    ;;
--regen | --icons)
    # Legacy matugen paths — flavors replaced generated theme.toml + icon blocks.
    switch_theme ""
    reload_instances
    ;;
-h | --help)
    sed -n '2,14p' "$0"
    ;;
"")
    switch_theme ""
    reload_instances
    ;;
*)
    switch_theme "$1"
    reload_instances
    ;;
esac