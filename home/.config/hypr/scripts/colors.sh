#!/usr/bin/env bash
# colors.sh — Load current matugen/Material You palette into shell variables
#
# Usage:
#   source ~/.config/hypr/scripts/colors.sh
#
#   # Now you have COLOR_PRIMARY, COLOR_SURFACE, etc.
#
#   # Apply to gum (and any other tools) explicitly:
#   gum_apply_matugen_theme
#
#   # Or auto-apply on source:
#   source ~/.config/hypr/scripts/colors.sh --gum
#
#   # Or for one-liner in other scripts:
#   source ~/.config/hypr/scripts/colors.sh && gum_apply_matugen_theme
#
# The parser prefers:
#   1. ~/.config/hypr/colors/custom/matugen.conf  (most reliable in this setup)
#   2. ~/.cache/matugen/current.json              (when valid)
#
# This file is safe to source multiple times.

set -euo pipefail

# -----------------------------------------------------------------------------
# Paths
# -----------------------------------------------------------------------------
MATUGEN_HYPR_CONF="${HOME}/.config/hypr/colors/custom/matugen.conf"
MATUGEN_JSON="${HOME}/.cache/matugen/current.json"
MATUGEN_CACHE_DIR="${HOME}/.cache/matugen"

# -----------------------------------------------------------------------------
# Color storage (populated by load_matugen_colors)
# -----------------------------------------------------------------------------
declare -gA MATUGEN_COLORS=()

# Common convenient aliases (populated after load)
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
COLOR_SURFACE_CONTAINER=""
COLOR_SURFACE_CONTAINER_HIGH=""
COLOR_SURFACE_CONTAINER_HIGHEST=""
COLOR_OUTLINE=""
COLOR_ERROR=""
COLOR_ON_ERROR=""

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
_hex_from_rgba_line() {
    # Input:  $primary = rgba(ffb4a3ff)
    # Output: #ffb4a3
    sed -nE 's/.*rgba\(([0-9a-fA-F]{6}).*/#\1/p' <<< "$1"
}

# Fast path: the posthook writes this directly after every wallpaper change
_load_from_cache_shell() {
    local shell_cache="${HOME}/.cache/matugen/colors.sh"
    [[ -f "$shell_cache" ]] || return 1

    # Source it in a subshell first to capture the exports without polluting
    # our namespace yet, then promote the ones we care about.
    local tmp
    tmp=$(bash -c "
        set -a
        source '$shell_cache' 2>/dev/null || exit 1
        set +a
        # Emit the COLOR_* variables we actually want
        env | grep -E '^COLOR_[A-Z_]+=' | sort
    " 2>/dev/null) || return 1

    while IFS='=' read -r var value; do
        [[ -n "$var" ]] || continue
        local key="${var#COLOR_}"
        key="${key,,}"          # lowercase for internal map
        MATUGEN_COLORS["$key"]="${value//\"/}"
    done <<< "$tmp"

    return 0
}

_load_from_hypr_conf() {
    [[ -f "$MATUGEN_HYPR_CONF" ]] || return 1

    while IFS= read -r line || [[ -n "$line" ]]; do
        case "$line" in
            '$primary ='*)                 MATUGEN_COLORS[primary]=$(_hex_from_rgba_line "$line") ;;
            '$on_primary ='*)              MATUGEN_COLORS[on_primary]=$(_hex_from_rgba_line "$line") ;;
            '$primary_container ='*)       MATUGEN_COLORS[primary_container]=$(_hex_from_rgba_line "$line") ;;
            '$on_primary_container ='*)    MATUGEN_COLORS[on_primary_container]=$(_hex_from_rgba_line "$line") ;;
            '$secondary ='*)               MATUGEN_COLORS[secondary]=$(_hex_from_rgba_line "$line") ;;
            '$on_secondary ='*)            MATUGEN_COLORS[on_secondary]=$(_hex_from_rgba_line "$line") ;;
            '$background ='*)              MATUGEN_COLORS[background]=$(_hex_from_rgba_line "$line") ;;
            '$on_background ='*)           MATUGEN_COLORS[on_background]=$(_hex_from_rgba_line "$line") ;;
            '$surface ='*)                 MATUGEN_COLORS[surface]=$(_hex_from_rgba_line "$line") ;;
            '$on_surface ='*)              MATUGEN_COLORS[on_surface]=$(_hex_from_rgba_line "$line") ;;
            '$surface_variant ='*)         MATUGEN_COLORS[surface_variant]=$(_hex_from_rgba_line "$line") ;;
            '$on_surface_variant ='*)      MATUGEN_COLORS[on_surface_variant]=$(_hex_from_rgba_line "$line") ;;
            '$surface_container ='*)       MATUGEN_COLORS[surface_container]=$(_hex_from_rgba_line "$line") ;;
            '$surface_container_high ='*)  MATUGEN_COLORS[surface_container_high]=$(_hex_from_rgba_line "$line") ;;
            '$surface_container_highest ='*) MATUGEN_COLORS[surface_container_highest]=$(_hex_from_rgba_line "$line") ;;
            '$outline ='*)                 MATUGEN_COLORS[outline]=$(_hex_from_rgba_line "$line") ;;
            '$outline_variant ='*)         MATUGEN_COLORS[outline_variant]=$(_hex_from_rgba_line "$line") ;;
            '$error ='*)                   MATUGEN_COLORS[error]=$(_hex_from_rgba_line "$line") ;;
            '$on_error ='*)                MATUGEN_COLORS[on_error]=$(_hex_from_rgba_line "$line") ;;
            '$surface_dim ='*)             MATUGEN_COLORS[surface_dim]=$(_hex_from_rgba_line "$line") ;;
            '$surface_bright ='*)          MATUGEN_COLORS[surface_bright]=$(_hex_from_rgba_line "$line") ;;
        esac
    done < "$MATUGEN_HYPR_CONF"

    return 0
}

_load_from_json() {
    [[ -f "$MATUGEN_JSON" ]] || return 1
    command -v jq >/dev/null 2>&1 || return 1

    # Only use if it looks like real JSON (not error text from a failed run)
    if ! jq -e '.colors.default' "$MATUGEN_JSON" >/dev/null 2>&1; then
        return 1
    fi

    local colors
    colors=$(jq -r '
        .colors.default | to_entries[] |
        "\(.key) \(.value.hex)"
    ' "$MATUGEN_JSON" 2>/dev/null) || return 1

    while read -r name hex; do
        [[ -n "$name" && "$hex" =~ ^#[0-9a-fA-F]{6}$ ]] || continue
        MATUGEN_COLORS["$name"]="$hex"
    done <<< "$colors"

    return 0
}

# -----------------------------------------------------------------------------
# Main loader
# -----------------------------------------------------------------------------
load_matugen_colors() {
    MATUGEN_COLORS=()

    # Fast path: directly generated shell file from posthook (preferred)
    if _load_from_cache_shell; then
        : # excellent, we have fresh exports
    # Fallbacks
    elif _load_from_hypr_conf; then
        : # success from hyprland matugen.conf
    elif _load_from_json; then
        : # fell back to JSON cache
    else
        # Last resort: try to ask matugen for the current wallpaper's colors
        # (slow, only if everything else failed)
        if command -v matugen >/dev/null 2>&1; then
            local wp
            wp=$(hyprctl hyprpaper listactive 2>/dev/null | awk -F' = ' 'NR==1{print $2}' | head -1 || true)
            if [[ -n "$wp" && -f "$wp" ]]; then
                local json
                json=$(matugen image "$wp" --mode dark --json hex 2>/dev/null | sed '/^ok$/d' | jq -c '.colors.default' 2>/dev/null || true)
                if [[ -n "$json" && "$json" != "null" ]]; then
                    while IFS= read -r name hex; do
                        MATUGEN_COLORS["$name"]="$hex"
                    done < <(jq -r 'to_entries[] | "\(.key) \(.value.hex)"' <<< "$json" 2>/dev/null || true)
                fi
            fi
        fi
    fi

    # Promote into convenient top-level variables (with safe fallbacks)
    COLOR_PRIMARY="${MATUGEN_COLORS[primary]:-#c792ea}"
    COLOR_ON_PRIMARY="${MATUGEN_COLORS[on_primary]:-#1e1e2e}"
    COLOR_PRIMARY_CONTAINER="${MATUGEN_COLORS[primary_container]:-#4a2c6a}"
    COLOR_ON_PRIMARY_CONTAINER="${MATUGEN_COLORS[on_primary_container]:-#f5e1ff}"

    COLOR_SECONDARY="${MATUGEN_COLORS[secondary]:-#89b4fa}"
    COLOR_ON_SECONDARY="${MATUGEN_COLORS[on_secondary]:-#1e1e2e}"

    COLOR_BACKGROUND="${MATUGEN_COLORS[background]:-#1e1e2e}"
    COLOR_ON_BACKGROUND="${MATUGEN_COLORS[on_background]:-#cdd6f4}"

    COLOR_SURFACE="${MATUGEN_COLORS[surface]:-#1e1e2e}"
    COLOR_ON_SURFACE="${MATUGEN_COLORS[on_surface]:-#cdd6f4}"
    COLOR_SURFACE_VARIANT="${MATUGEN_COLORS[surface_variant]:-#45475a}"
    COLOR_ON_SURFACE_VARIANT="${MATUGEN_COLORS[on_surface_variant]:-#bac2de}"

    COLOR_SURFACE_CONTAINER="${MATUGEN_COLORS[surface_container]:-#252535}"
    COLOR_SURFACE_CONTAINER_HIGH="${MATUGEN_COLORS[surface_container_high]:-#2d2d3f}"
    COLOR_SURFACE_CONTAINER_HIGHEST="${MATUGEN_COLORS[surface_container_highest]:-#36364a}"

    COLOR_OUTLINE="${MATUGEN_COLORS[outline]:-#6c7086}"
    COLOR_ERROR="${MATUGEN_COLORS[error]:-#f38ba8}"
    COLOR_ON_ERROR="${MATUGEN_COLORS[on_error]:-#1e1e2e}"

    # Handy semantic aliases
    COLOR_ACCENT="$COLOR_PRIMARY"
    COLOR_BG="$COLOR_SURFACE"
    COLOR_FG="$COLOR_ON_SURFACE"
    COLOR_TEXT="$COLOR_ON_SURFACE"
}

# -----------------------------------------------------------------------------
# Gum theming — call this after sourcing to make gum follow matugen
# -----------------------------------------------------------------------------
gum_apply_matugen_theme() {
    # Core confirm dialog
    export GUM_CONFIRM_PROMPT="? "
    export GUM_CONFIRM_SELECTED_BACKGROUND="${COLOR_PRIMARY}"
    export GUM_CONFIRM_SELECTED_FOREGROUND="${COLOR_ON_PRIMARY}"
    export GUM_CONFIRM_UNSELECTED_BACKGROUND="${COLOR_SURFACE_CONTAINER}"
    export GUM_CONFIRM_UNSELECTED_FOREGROUND="${COLOR_ON_SURFACE}"

    # Input / text entry
    export GUM_INPUT_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_INPUT_PROMPT_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_INPUT_PLACEHOLDER_FOREGROUND="${COLOR_ON_SURFACE_VARIANT}"

    # Choose / filter
    export GUM_CHOOSE_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_CHOOSE_SELECTED_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_FILTER_MATCH_FOREGROUND="${COLOR_PRIMARY}"

    # Spinner / progress
    export GUM_SPIN_SPINNER_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_SPIN_TITLE_FOREGROUND="${COLOR_ON_SURFACE}"

    # Table / pager
    export GUM_TABLE_HEADER_FOREGROUND="${COLOR_PRIMARY}"
    export GUM_PAGER_FOREGROUND="${COLOR_ON_SURFACE}"
}

# -----------------------------------------------------------------------------
# Convenience: one-shot "I just want gum to look right"
# -----------------------------------------------------------------------------
gum_use_matugen() {
    load_matugen_colors
    gum_apply_matugen_theme
}

# -----------------------------------------------------------------------------
# Auto-load colors when this file is sourced
# -----------------------------------------------------------------------------
load_matugen_colors

# If sourced with --gum or gum as first argument, apply immediately
if [[ "${1:-}" == "--gum" || "${1:-}" == "gum" ]]; then
    gum_apply_matugen_theme
fi

# Export the main function names so they are available after sourcing
export -f load_matugen_colors gum_apply_matugen_theme gum_use_matugen 2>/dev/null || true
