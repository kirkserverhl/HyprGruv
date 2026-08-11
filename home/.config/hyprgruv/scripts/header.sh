#!/usr/bin/env bash
# header.sh — toilet ASCII headers colored by system palette
#
# Policy (same as colors.sh / gum / ensure-local-palette):
#   1. Live matugen / user-selected preset palette if present
#   2. Else gruvbox-dark defaults
#
# Requires: toilet (+ toilet-fonts package). Does not call figlet(1).
#
# Usage:
#   source "$HOME/.config/hyprgruv/scripts/header.sh"
#   display_header "Shell"
#
# Env:
#   HYPRGRUV_TOILET_FONT  preferred toilet font (default: smblock → future → …)

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

# Parse #RRGGBB → R G B decimals for truecolor ANSI
_header_hex_rgb() {
    local h="${1#\#}"
    h="${h//\"/}"
    [[ ${#h} -eq 6 ]] || {
        printf '254 128 25' # gruvbox orange
        return
    }
    printf '%d %d %d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}"
}

# Paint multi-line ASCII with theme primary (gum preferred, else ANSI 24-bit)
_header_paint() {
    local r g b
    read -r r g b < <(_header_hex_rgb "${COLOR_PRIMARY}")

    if command -v gum >/dev/null 2>&1; then
        local line
        while IFS= read -r line || [[ -n "$line" ]]; do
            printf '%s\n' "$line" | gum style --foreground "${COLOR_PRIMARY}" 2>/dev/null \
                || printf '\e[38;2;%d;%d;%dm%s\e[0m\n' "$r" "$g" "$b" "$line"
        done
        return 0
    fi

    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        printf '\e[38;2;%d;%d;%dm%s\e[0m\n' "$r" "$g" "$b" "$line"
    done
}

# Prefer fonts from toilet-fonts / /usr/share/figlet (toilet reads .tlf and .flf)
_header_toilet_fonts() {
    if [[ -n "${HYPRGRUV_TOILET_FONT:-}" ]]; then
        printf '%s\n' "$HYPRGRUV_TOILET_FONT"
    fi
    # smblock/future/emboss from toilet-fonts; graffiti/slant/big also available system-wide
    printf '%s\n' smblock future emboss emboss2 mono12 bigmono12 pagga letter graffiti slant standard big
}

_header_render_toilet() {
    local title="$1"
    local font out

    command -v toilet >/dev/null 2>&1 || return 1

    while IFS= read -r font; do
        [[ -z "$font" ]] && continue
        if out=$(toilet -f "$font" --width "${COLUMNS:-120}" "$title" 2>/dev/null) && [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            return 0
        fi
    done < <(_header_toilet_fonts)

    if out=$(toilet --width "${COLUMNS:-120}" "$title" 2>/dev/null) && [[ -n "$out" ]]; then
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
        # No toilet (pre-packages): gum/ANSI title line still follows palette policy
        if command -v gum >/dev/null 2>&1; then
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
