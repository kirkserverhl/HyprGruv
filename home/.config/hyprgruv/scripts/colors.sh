#!/usr/bin/env bash
# colors.sh — Load live system palette into COLOR_* shell vars (gum / figlet / install)
#
# Policy (same as ensure-local-palette.sh):
#   1. Live matugen / preset outputs if present  → follow system
#   2. Else gruvbox-dark defaults               → baseline
#
# Usage:
#   source ~/.config/hyprgruv/scripts/colors.sh
#   source ~/.config/hyprgruv/scripts/colors.sh --gum   # also apply gum env
#
# Prefer order:
#   1. ~/.cache/matugen/colors.sh          (written by this loader / posthooks)
#   2. ~/.config/hypr/colors/custom/matugen.conf  (base16 + semantic roles)
#   3. ~/.cache/matugen/current.json
#   4. lib/defaults/gruvbox-colors.sh
#
# Safe to source multiple times. Does not use set -e.

MATUGEN_HYPR_CONF="${HOME}/.config/hypr/colors/custom/matugen.conf"
MATUGEN_HYPR_CONF_REPO="${HYPRGRUV_DIR:-${HYPR_DIR:-$HOME/.hyprgruv}}/home/.config/hypr/colors/custom/matugen.conf"
MATUGEN_JSON="${HOME}/.cache/matugen/current.json"
MATUGEN_CACHE_DIR="${HOME}/.cache/matugen"
MATUGEN_SHELL_CACHE="${MATUGEN_CACHE_DIR}/colors.sh"
MATUGEN_DEFAULT_COLORS="${HYPRGRUV_DIR:-${HYPR_DIR:-$HOME/.hyprgruv}}/lib/defaults/gruvbox-colors.sh"

declare -gA MATUGEN_COLORS=()

COLOR_PRIMARY=""
COLOR_ON_PRIMARY=""
COLOR_PRIMARY_CONTAINER=""
COLOR_ON_PRIMARY_CONTAINER=""
COLOR_SECONDARY=""
COLOR_ON_SECONDARY=""
COLOR_BACKGROUND=""
COLOR_ON_BACKGROUND=""
COLOR_SURFACE=""
COLOR_ON_SURFACE=""
COLOR_SURFACE_VARIANT=""
COLOR_ON_SURFACE_VARIANT=""
COLOR_SURFACE_CONTAINER=""
COLOR_SURFACE_CONTAINER_HIGH=""
COLOR_SURFACE_CONTAINER_HIGHEST=""
COLOR_OUTLINE=""
COLOR_ERROR=""
COLOR_ON_ERROR=""
COLOR_SUCCESS=""
COLOR_WARNING=""
COLOR_INFO=""
COLOR_ACCENT=""
COLOR_BG=""
COLOR_FG=""
COLOR_TEXT=""
HYPRGRUV_COLOR_SOURCE=""

# -----------------------------------------------------------------------------
_hex_from_rgba_token() {
    # rgba(d65d0eff) or d65d0eff → #d65d0e
    local s="$1"
    if [[ "$s" =~ rgba\(([0-9a-fA-F]{6}) ]]; then
        printf '#%s\n' "${BASH_REMATCH[1],,}"
        return 0
    fi
    if [[ "$s" =~ ^#?([0-9a-fA-F]{6})$ ]]; then
        printf '#%s\n' "${BASH_REMATCH[1],,}"
        return 0
    fi
    return 1
}

_hex_from_rgba_line() {
    _hex_from_rgba_token "${1#*=}"
}

# Fast path: cached exports from a previous successful load / theme apply
_load_from_cache_shell() {
    local shell_cache="$MATUGEN_SHELL_CACHE"
    [[ -f "$shell_cache" ]] || return 1

    local tmp
    tmp=$(bash -c "
        set -a
        # shellcheck source=/dev/null
        source '$shell_cache' 2>/dev/null || exit 1
        set +a
        env | grep -E '^COLOR_[A-Z0-9_]+=' | sort
    " 2>/dev/null) || return 1

    local count=0
    while IFS='=' read -r var value; do
        [[ -n "$var" ]] || continue
        local key="${var#COLOR_}"
        key="${key,,}"
        MATUGEN_COLORS["$key"]="${value//\"/}"
        count=$((count + 1))
    done <<< "$tmp"

    [[ $count -ge 4 ]] || return 1
    HYPRGRUV_COLOR_SOURCE="cache"
    return 0
}

# Parse hypr matugen.conf: base16 slots + semantic roles (resolves $base0D refs)
_load_from_hypr_conf() {
    local conf="$MATUGEN_HYPR_CONF"
    [[ -f "$conf" ]] || conf="$MATUGEN_HYPR_CONF_REPO"
    [[ -f "$conf" ]] || return 1

    declare -A raw=()
    local line key val

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" == \$*=* ]] || continue
        key="${line%%=*}"
        key="${key#"${key%%[![:space:]]*}"}"
        key="${key%"${key##*[![:space:]]}"}"
        key="${key#\$}"
        val="${line#*=}"
        val="${val#"${val%%[![:space:]]*}"}"
        val="${val%"${val##*[![:space:]]}"}"
        raw["$key"]="$val"
    done <"$conf"

    # Resolve $name → hex (two passes for base16 → role indirection)
    _resolve_token() {
        local tok="$1" depth=0
        while [[ $depth -lt 8 ]]; do
            depth=$((depth + 1))
            tok="${tok#"${tok%%[![:space:]]*}"}"
            tok="${tok%"${tok##*[![:space:]]}"}"
            if hex=$(_hex_from_rgba_token "$tok" 2>/dev/null); then
                printf '%s\n' "$hex"
                return 0
            fi
            if [[ "$tok" == \$* ]]; then
                local ref="${tok#\$}"
                tok="${raw[$ref]:-}"
                [[ -n "$tok" ]] || return 1
                continue
            fi
            return 1
        done
        return 1
    }

    local k hex count=0
    for k in "${!raw[@]}"; do
        if hex="$(_resolve_token "${raw[$k]}")"; then
            MATUGEN_COLORS["$k"]="$hex"
            count=$((count + 1))
        fi
    done

    [[ $count -ge 4 ]] || return 1
    HYPRGRUV_COLOR_SOURCE="hypr-conf"
    return 0
}

_load_from_json() {
    [[ -f "$MATUGEN_JSON" ]] || return 1
    command -v jq >/dev/null 2>&1 || return 1
    if ! jq -e '.colors.default' "$MATUGEN_JSON" >/dev/null 2>&1; then
        return 1
    fi

    local colors
    colors=$(jq -r '
        .colors.default | to_entries[] |
        "\(.key) \(.value.hex // .value)"
    ' "$MATUGEN_JSON" 2>/dev/null) || return 1

    local name hex count=0
    while read -r name hex; do
        [[ -n "$name" ]] || continue
        hex="${hex//\"/}"
        [[ "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
        MATUGEN_COLORS["$name"]="$hex"
        count=$((count + 1))
    done <<< "$colors"

    [[ $count -ge 4 ]] || return 1
    HYPRGRUV_COLOR_SOURCE="json"
    return 0
}

_load_gruvbox_defaults() {
    if [[ -f "$MATUGEN_DEFAULT_COLORS" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$MATUGEN_DEFAULT_COLORS" 2>/dev/null || true
        set +a
    fi
    # Ensure map has values even if source failed partially
    MATUGEN_COLORS[primary]="${COLOR_PRIMARY:-#fe8019}"
    MATUGEN_COLORS[on_primary]="${COLOR_ON_PRIMARY:-#282828}"
    MATUGEN_COLORS[primary_container]="${COLOR_PRIMARY_CONTAINER:-#d65d0e}"
    MATUGEN_COLORS[on_primary_container]="${COLOR_ON_PRIMARY_CONTAINER:-#ebdbb2}"
    MATUGEN_COLORS[secondary]="${COLOR_SECONDARY:-#83a598}"
    MATUGEN_COLORS[on_secondary]="${COLOR_ON_SECONDARY:-#282828}"
    MATUGEN_COLORS[background]="${COLOR_BACKGROUND:-#282828}"
    MATUGEN_COLORS[on_background]="${COLOR_ON_BACKGROUND:-#ebdbb2}"
    MATUGEN_COLORS[surface]="${COLOR_SURFACE:-#282828}"
    MATUGEN_COLORS[on_surface]="${COLOR_ON_SURFACE:-#ebdbb2}"
    MATUGEN_COLORS[surface_variant]="${COLOR_SURFACE_VARIANT:-#504945}"
    MATUGEN_COLORS[on_surface_variant]="${COLOR_ON_SURFACE_VARIANT:-#a89984}"
    MATUGEN_COLORS[surface_container]="${COLOR_SURFACE_CONTAINER:-#3c3836}"
    MATUGEN_COLORS[surface_container_high]="${COLOR_SURFACE_CONTAINER_HIGH:-#504945}"
    MATUGEN_COLORS[surface_container_highest]="${COLOR_SURFACE_CONTAINER_HIGHEST:-#665c54}"
    MATUGEN_COLORS[outline]="${COLOR_OUTLINE:-#665c54}"
    MATUGEN_COLORS[error]="${COLOR_ERROR:-#fb4934}"
    MATUGEN_COLORS[on_error]="${COLOR_ON_ERROR:-#282828}"
    MATUGEN_COLORS[success]="${COLOR_SUCCESS:-#b8bb26}"
    MATUGEN_COLORS[warning]="${COLOR_WARNING:-#fabd2f}"
    MATUGEN_COLORS[info]="${COLOR_INFO:-#83a598}"
    HYPRGRUV_COLOR_SOURCE="gruvbox-default"
}

# Promote map → COLOR_* (gruvbox fallbacks on any missing key)
_promote_color_vars() {
    COLOR_PRIMARY="${MATUGEN_COLORS[primary]:-#fe8019}"
    COLOR_ON_PRIMARY="${MATUGEN_COLORS[on_primary]:-#282828}"
    COLOR_PRIMARY_CONTAINER="${MATUGEN_COLORS[primary_container]:-#d65d0e}"
    COLOR_ON_PRIMARY_CONTAINER="${MATUGEN_COLORS[on_primary_container]:-#ebdbb2}"

    COLOR_SECONDARY="${MATUGEN_COLORS[secondary]:-#83a598}"
    COLOR_ON_SECONDARY="${MATUGEN_COLORS[on_secondary]:-#282828}"

    COLOR_BACKGROUND="${MATUGEN_COLORS[background]:-#282828}"
    COLOR_ON_BACKGROUND="${MATUGEN_COLORS[on_background]:-#ebdbb2}"

    COLOR_SURFACE="${MATUGEN_COLORS[surface]:-#282828}"
    COLOR_ON_SURFACE="${MATUGEN_COLORS[on_surface]:-#ebdbb2}"
    COLOR_SURFACE_VARIANT="${MATUGEN_COLORS[surface_variant]:-#504945}"
    COLOR_ON_SURFACE_VARIANT="${MATUGEN_COLORS[on_surface_variant]:-#a89984}"

    COLOR_SURFACE_CONTAINER="${MATUGEN_COLORS[surface_container]:-#3c3836}"
    COLOR_SURFACE_CONTAINER_HIGH="${MATUGEN_COLORS[surface_container_high]:-#504945}"
    COLOR_SURFACE_CONTAINER_HIGHEST="${MATUGEN_COLORS[surface_container_highest]:-#665c54}"

    COLOR_OUTLINE="${MATUGEN_COLORS[outline]:-#665c54}"
    COLOR_ERROR="${MATUGEN_COLORS[error]:-#fb4934}"
    COLOR_ON_ERROR="${MATUGEN_COLORS[on_error]:-#282828}"

    COLOR_SUCCESS="${MATUGEN_COLORS[success]:-${MATUGEN_COLORS[tertiary]:-#b8bb26}}"
    COLOR_WARNING="${MATUGEN_COLORS[warning]:-${MATUGEN_COLORS[base0a]:-${MATUGEN_COLORS[base0A]:-#fabd2f}}}"
    COLOR_INFO="${MATUGEN_COLORS[info]:-$COLOR_SECONDARY}"

    COLOR_ACCENT="$COLOR_PRIMARY"
    COLOR_BG="$COLOR_SURFACE"
    COLOR_FG="$COLOR_ON_SURFACE"
    COLOR_TEXT="$COLOR_ON_SURFACE"
}

# Persist for gum/figlet/style.sh and next load (machine-local, not git)
write_matugen_shell_color_cache() {
    mkdir -p "$MATUGEN_CACHE_DIR" 2>/dev/null || return 0
    cat >"$MATUGEN_SHELL_CACHE" <<EOF
# Generated by hyprgruv colors.sh — live system palette (do not commit)
# source: ${HYPRGRUV_COLOR_SOURCE:-unknown}
export COLOR_PRIMARY="${COLOR_PRIMARY}"
export COLOR_ON_PRIMARY="${COLOR_ON_PRIMARY}"
export COLOR_PRIMARY_CONTAINER="${COLOR_PRIMARY_CONTAINER}"
export COLOR_ON_PRIMARY_CONTAINER="${COLOR_ON_PRIMARY_CONTAINER}"
export COLOR_SECONDARY="${COLOR_SECONDARY}"
export COLOR_ON_SECONDARY="${COLOR_ON_SECONDARY}"
export COLOR_BACKGROUND="${COLOR_BACKGROUND}"
export COLOR_ON_BACKGROUND="${COLOR_ON_BACKGROUND}"
export COLOR_SURFACE="${COLOR_SURFACE}"
export COLOR_ON_SURFACE="${COLOR_ON_SURFACE}"
export COLOR_SURFACE_VARIANT="${COLOR_SURFACE_VARIANT}"
export COLOR_ON_SURFACE_VARIANT="${COLOR_ON_SURFACE_VARIANT}"
export COLOR_SURFACE_CONTAINER="${COLOR_SURFACE_CONTAINER}"
export COLOR_SURFACE_CONTAINER_HIGH="${COLOR_SURFACE_CONTAINER_HIGH}"
export COLOR_SURFACE_CONTAINER_HIGHEST="${COLOR_SURFACE_CONTAINER_HIGHEST}"
export COLOR_OUTLINE="${COLOR_OUTLINE}"
export COLOR_ERROR="${COLOR_ERROR}"
export COLOR_ON_ERROR="${COLOR_ON_ERROR}"
export COLOR_SUCCESS="${COLOR_SUCCESS}"
export COLOR_WARNING="${COLOR_WARNING}"
export COLOR_INFO="${COLOR_INFO}"
export COLOR_ACCENT="${COLOR_ACCENT}"
export COLOR_BG="${COLOR_BG}"
export COLOR_FG="${COLOR_FG}"
export COLOR_TEXT="${COLOR_TEXT}"
export HYPRGRUV_COLOR_SOURCE="${HYPRGRUV_COLOR_SOURCE:-}"
EOF
}

load_matugen_colors() {
    MATUGEN_COLORS=()
    HYPRGRUV_COLOR_SOURCE=""

    if _load_from_cache_shell; then
        :
    elif _load_from_hypr_conf; then
        :
    elif _load_from_json; then
        :
    else
        _load_gruvbox_defaults
    fi

    _promote_color_vars

    # Keep shell cache in sync when we resolved from hypr/json (not when we
    # just re-read the cache itself — still refresh to fill new keys).
    write_matugen_shell_color_cache 2>/dev/null || true
}

# Gum theming — install, upkeep, and interactive scripts
gum_apply_matugen_theme() {
    # Ensure COLOR_* exist even if caller forgot to load
    if [[ -z "${COLOR_PRIMARY:-}" ]]; then
        load_matugen_colors
    fi

    export GUM_CONFIRM_PROMPT="? "
    export GUM_CONFIRM_SELECTED_BACKGROUND="${COLOR_PRIMARY}"
    export GUM_CONFIRM_SELECTED_FOREGROUND="${COLOR_ON_PRIMARY}"
    export GUM_CONFIRM_UNSELECTED_BACKGROUND="${COLOR_SURFACE_CONTAINER}"
    export GUM_CONFIRM_UNSELECTED_FOREGROUND="${COLOR_ON_SURFACE}"

    export GUM_INPUT_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_INPUT_PROMPT_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_INPUT_PLACEHOLDER_FOREGROUND="${COLOR_ON_SURFACE_VARIANT}"

    export GUM_CHOOSE_CURSOR_FOREGROUND="${COLOR_ON_PRIMARY}"
    export GUM_CHOOSE_CURSOR_BACKGROUND="${COLOR_PRIMARY}"
    export GUM_CHOOSE_SELECTED_FOREGROUND="${COLOR_ON_PRIMARY}"
    export GUM_CHOOSE_SELECTED_BACKGROUND="${COLOR_PRIMARY}"
    export GUM_CHOOSE_ITEM_FOREGROUND="${COLOR_ON_SURFACE}"
    export GUM_CHOOSE_CURSOR_PREFIX="› "
    export GUM_CHOOSE_SELECTED_PREFIX="✓ "
    export GUM_CHOOSE_UNSELECTED_PREFIX="  "
    export GUM_FILTER_MATCH_FOREGROUND="${COLOR_PRIMARY}"

    export GUM_SPIN_SPINNER_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_SPIN_TITLE_FOREGROUND="${COLOR_ON_SURFACE}"

    export GUM_TABLE_HEADER_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_PAGER_FOREGROUND="${COLOR_ON_SURFACE}"

    # Style / write helpers often used in install modules
    export GUM_WRITE_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_STYLE_FOREGROUND="${COLOR_ON_SURFACE}"
    export GUM_STYLE_BORDER_FOREGROUND="${COLOR_PRIMARY}"
}

gum_use_matugen() {
    load_matugen_colors
    gum_apply_matugen_theme
}

# Alias for clarity in new call sites
hyprgruv_apply_cli_theme() { gum_use_matugen; }

load_matugen_colors

if [[ "${1:-}" == "--gum" || "${1:-}" == "gum" ]]; then
    gum_apply_matugen_theme
fi
