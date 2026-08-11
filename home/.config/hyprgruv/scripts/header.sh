#!/usr/bin/env bash
# header.sh — system-wide toilet "graffiti" headers for install + upkeep
#
# Style:
#   • Font: graffiti (toilet-fonts) everywhere — install, modules, git-eod, etc.
#   • Color: lsd-print if available; else gum with system palette; else ANSI
#
# Palette policy (when not using lsd-print):
#   gruvbox-dark default → live matugen / user-selected theme if present
#
# Requires: toilet + toilet-fonts. Does not call figlet(1).
#
# Usage:
#   source "$HOME/.config/hyprgruv/scripts/header.sh"
#   display_header "Shell"
#
# Env:
#   HYPRGRUV_TOILET_FONT   override font (default: graffiti)
#   HYPRGRUV_HEADER_STYLE  auto|lsd|gum|ansi|plain  (default: auto)

# Load COLOR_* if not already present (install may have loaded via common.sh)
if [[ -z "${COLOR_PRIMARY:-}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.config/hyprgruv/scripts/colors.sh" 2>/dev/null \
        || source "${HYPR_DIR:-$HOME/.hyprgruv}/home/.config/hyprgruv/scripts/colors.sh" 2>/dev/null \
        || true
fi
# Gruvbox hard fallbacks if colors.sh missing (very early install)
: "${COLOR_PRIMARY:=#fe8019}"
: "${COLOR_ON_SURFACE:=#ebdbb2}"
: "${COLOR_TEXT:=${COLOR_ON_SURFACE}}"
: "${HYPRGRUV_HEADER_STYLE:=auto}"

_header_hex_rgb() {
    local h="${1#\#}"
    h="${h//\"/}"
    [[ ${#h} -eq 6 ]] || {
        printf '254 128 25'
        return
    }
    printf '%d %d %d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# Styling pipeline for multi-line toilet art
_header_paint() {
    local style="${HYPRGRUV_HEADER_STYLE:-auto}"

    # auto: lsd-print → gum (palette) → ANSI truecolor primary
    if [[ "$style" == "auto" ]]; then
        if command -v lsd-print >/dev/null 2>&1; then
            style=lsd
        elif command -v gum >/dev/null 2>&1; then
            style=gum
        else
            style=ansi
        fi
    fi

    case "$style" in
    lsd)
        if command -v lsd-print >/dev/null 2>&1; then
            lsd-print
            return 0
        fi
        # fall through if forced lsd but missing
        ;;&
    gum)
        if command -v gum >/dev/null 2>&1; then
            local line r g b
            read -r r g b < <(_header_hex_rgb "${COLOR_PRIMARY}")
            while IFS= read -r line || [[ -n "$line" ]]; do
                printf '%s\n' "$line" | gum style --foreground "${COLOR_PRIMARY}" 2>/dev/null \
                    || printf '\e[38;2;%d;%d;%dm%s\e[0m\n' "$r" "$g" "$b" "$line"
            done
            return 0
        fi
        ;;&
    ansi)
        local line r g b
        read -r r g b < <(_header_hex_rgb "${COLOR_PRIMARY}")
        while IFS= read -r line || [[ -n "$line" ]]; do
            printf '\e[38;2;%d;%d;%dm%s\e[0m\n' "$r" "$g" "$b" "$line"
        done
        return 0
        ;;
    plain)
        cat
        return 0
        ;;
    *)
        cat
        return 0
        ;;
    esac
}

# System-wide standard: graffiti first, then safe fallbacks
_header_toilet_fonts() {
    if [[ -n "${HYPRGRUV_TOILET_FONT:-}" ]]; then
        printf '%s\n' "$HYPRGRUV_TOILET_FONT"
    fi
    # graffiti is the HyprGruv house style (toilet-fonts package)
    printf '%s\n' graffiti slant standard big smblock future emboss mono12
}

_header_render_toilet() {
    local title="$1"
    local font out
    local width="${COLUMNS:-120}"

    command -v toilet >/dev/null 2>&1 || return 1

    while IFS= read -r font; do
        [[ -z "$font" ]] && continue
        if out=$(toilet -f "$font" --width "$width" "$title" 2>/dev/null) && [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            return 0
        fi
    done < <(_header_toilet_fonts)

    if out=$(toilet --width "$width" "$title" 2>/dev/null) && [[ -n "$out" ]]; then
        printf '%s\n' "$out"
        return 0
    fi
    return 1
}

print_header() {
    local title="${1:-}"
    [[ -z "$title" ]] && return 0

    echo ""
    if out=$(_header_render_toilet "$title"); then
        printf '%s\n' "$out" | _header_paint
    else
        # Pre-packages / no toilet: still style the plain title
        if command -v lsd-print >/dev/null 2>&1 && [[ "${HYPRGRUV_HEADER_STYLE:-auto}" != "gum" ]]; then
            printf '=== %s ===\n' "$title" | lsd-print
        elif command -v gum >/dev/null 2>&1; then
            printf '=== %s ===\n' "$title" | gum style --foreground "${COLOR_PRIMARY}" --bold 2>/dev/null \
                || printf '=== %s ===\n' "$title"
        else
            local r g b
            read -r r g b < <(_header_hex_rgb "${COLOR_PRIMARY}")
            printf '\e[38;2;%d;%d;%dm=== %s ===\e[0m\n' "$r" "$g" "$b" "$title"
        fi
    fi
    echo ""
}

display_header() {
    print_header "$@"
}

clear_header() {
    clear
    print_header "$@"
    echo
}

header() {
    print_header "$@"
}

export -f print_header display_header clear_header header 2>/dev/null || true

if [[ "${1:-}" == "--clear" || "${1:-}" == "clear" ]]; then
    shift
    clear_header "${1:-Header}"
fi
