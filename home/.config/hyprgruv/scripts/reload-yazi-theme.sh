#!/usr/bin/env bash
# reload-yazi-theme.sh — switch Yazi flavor + force folder/status colors per theme
#
# Yazi does not hot-reload theme.toml (must reopen). We still update the file
# immediately so the next launch (and yazi.sh) pick the right theme, and we try
# soft signals on any running instances.
#
# Usage:
#   reload-yazi-theme.sh                 switch to .current-theme
#   reload-yazi-theme.sh --switch NAME   switch to a specific theme id
#   reload-yazi-theme.sh --reload        try soft-reload only
#   reload-yazi-theme.sh --flavor NAME   set flavor directly

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
    noir) echo "catppuccin-mocha" ;; # closest installed; overrides paint mono below
    "")
        echo "gruvbox-dark"
        ;;
    *)
        if [[ -d "${FLAVORS_DIR}/${theme}.yazi" ]]; then
            echo "$theme"
        else
            echo "gruvbox-dark"
        fi
        ;;
    esac
}

# Theme-native colors for folders + bottom status (mode) line.
# Flavors vary: gruvbox has no [icon] tint; catppuccin does. Overrides make
# Super+W switches consistently recolor dirs + status regardless of flavor gaps.
theme_visuals() {
    local theme="$1"
    # exports: DIR_FG CWD_FG MODE_FG MODE_BG MODE_ALT_FG MODE_ALT_BG BORDER_FG
    case "$theme" in
    catppuccin)
        DIR_FG="#89b4fa"
        CWD_FG="#94e2d5"
        MODE_FG="#1e1e2e"
        MODE_BG="#89b4fa"
        MODE_ALT_FG="#89b4fa"
        MODE_ALT_BG="#313244"
        SEL_BG="#94e2d5"
        BORDER_FG="#7f849c"
        ;;
    nord-darker | nord)
        DIR_FG="#81A1C1"
        CWD_FG="#88C0D0"
        MODE_FG="#2E3440"
        MODE_BG="#8FBCBB"
        MODE_ALT_FG="#8FBCBB"
        MODE_ALT_BG="#3B4252"
        SEL_BG="#88C0D0"
        BORDER_FG="#4C566A"
        ;;
    everforest-dark | forest-night)
        DIR_FG="#7fbbb3"
        CWD_FG="#7fbbb3"
        MODE_FG="#3d484d"
        MODE_BG="#a7c080"
        MODE_ALT_FG="#7fbbb3"
        MODE_ALT_BG="#4f585e"
        SEL_BG="#e67e80"
        BORDER_FG="#4f585e"
        ;;
    noir)
        DIR_FG="#a6a6a6"
        CWD_FG="#c0c0c0"
        MODE_FG="#111111"
        MODE_BG="#c0c0c0"
        MODE_ALT_FG="#c0c0c0"
        MODE_ALT_BG="#2a2a2a"
        SEL_BG="#888888"
        BORDER_FG="#555555"
        ;;
    gruvbox-light)
        DIR_FG="#076678"
        CWD_FG="#076678"
        MODE_FG="#fbf1c7"
        MODE_BG="#7c6f64"
        MODE_ALT_FG="#7c6f64"
        MODE_ALT_BG="#ebdbb2"
        SEL_BG="#af3a03"
        BORDER_FG="#bdae93"
        ;;
    *)
        # gruvbox-dark family (default)
        DIR_FG="#83a598"
        CWD_FG="#83a598"
        MODE_FG="#282828"
        MODE_BG="#a89984"
        MODE_ALT_FG="#a89984"
        MODE_ALT_BG="#504945"
        SEL_BG="#fe8019"
        BORDER_FG="#665c54"
        ;;
    esac
}

write_theme_file() {
    local flavor="$1"
    local theme_id="${2:-}"

    [[ -d "${FLAVORS_DIR}/${flavor}.yazi" ]] || {
        echo "[reload-yazi] Flavor not installed: ${flavor}.yazi" >&2
        echo "[reload-yazi] Run: ya pkg add <owner>/<flavor>" >&2
        return 1
    }

    theme_visuals "${theme_id:-gruvbox-dark}"

    # theme.toml = flavor pick + hard overrides so folder + bottom status
    # always match the Super+W theme (flavor alone is incomplete for gruvbox icons).
    cat >"$THEME_FILE" <<EOF
# Managed by reload-yazi-theme.sh — do not edit by hand.
# Super+W / apply-theme → flavor + folder/status overrides for theme: ${theme_id:-?}

[flavor]
dark  = "${flavor}"
light = "${flavor}"

# --- folder name + icon color (visible theme switch) ---
# Do not replace [filetype] wholesale — that would wipe flavor mime colors.
[mgr]
cwd = { fg = "${CWD_FG}" }
border_style = { fg = "${BORDER_FG}" }

[icon]
# Tint every directory icon (and name via icon fg) to the theme accent
prepend_conds = [
  { if = "dir", text = "󰉋", fg = "${DIR_FG}" },
]

# --- bottom status line (mode segment) ---
[mode]
normal_main = { fg = "${MODE_FG}", bg = "${MODE_BG}", bold = true }
normal_alt  = { fg = "${MODE_ALT_FG}", bg = "${MODE_ALT_BG}" }
select_main = { fg = "${MODE_FG}", bg = "${SEL_BG}", bold = true }
select_alt  = { fg = "${MODE_ALT_FG}", bg = "${MODE_ALT_BG}" }
unset_main  = { fg = "${MODE_FG}", bg = "${DIR_FG}", bold = true }
unset_alt   = { fg = "${MODE_ALT_FG}", bg = "${MODE_ALT_BG}" }

[tabs]
active   = { fg = "${MODE_FG}", bg = "${MODE_BG}", bold = true }
inactive = { fg = "${MODE_ALT_FG}", bg = "${MODE_ALT_BG}" }
EOF

    if [[ -n "$theme_id" ]]; then
        mkdir -p "${HOME}/.cache/matugen"
        echo "flavor:${flavor}" >"${HOME}/.cache/matugen/yazi-flavor-mode"
        echo "preset:${theme_id}" >"${HOME}/.cache/matugen/yazi-icon-mode"
    fi
}

switch_theme() {
    local theme="${1:-}"
    if [[ -z "$theme" && -f "$CURRENT_THEME_FILE" ]]; then
        theme=$(tr -d '[:space:]' <"$CURRENT_THEME_FILE")
    fi
    [[ -n "$theme" ]] || theme="gruvbox-dark"

    local flavor
    flavor=$(resolve_yazi_flavor "$theme")
    write_theme_file "$flavor" "$theme"
    echo "[reload-yazi] flavor=${flavor} theme=${theme} dir=${DIR_FG} mode=${MODE_BG}"
}

reload_instances() {
    # Yazi 26.x has no reliable live theme reload — config is read at start.
    # Soft signals are best-effort; new yazi / yazi.sh pick up theme.toml.
    command -v ya >/dev/null 2>&1 || return 0
    local id
    for id in 0 1 2 3 4 5 6 7 8 9; do
        ya emit-to "$id" app:theme 2>/dev/null || true
        ya emit-to "$id" app:reflow 2>/dev/null || true
    done
}

case "${1:-}" in
--switch)
    switch_theme "${2:-}"
    reload_instances
    ;;
--flavor)
    # Direct flavor: still paint gruvbox-like overrides unless theme known
    write_theme_file "${2:?flavor name required}" ""
    reload_instances
    ;;
--reload)
    reload_instances
    ;;
--regen | --icons)
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
