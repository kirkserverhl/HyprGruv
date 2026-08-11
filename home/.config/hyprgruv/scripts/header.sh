#!/usr/bin/env bash
# header.sh — Colorized ASCII headers (toilet + figlet)
#
# Uses live system palette (colors.sh) when available; gruvbox otherwise.
# Preferred: toilet graffiti | themed color. Fallback: figlet, then plain.
#
# Usage:
#   source "$HOME/.config/hyprgruv/scripts/header.sh"
#   display_header "Shell"

# Load COLOR_* if not already present (install/upkeep may have loaded via common.sh)
if [[ -z "${COLOR_PRIMARY:-}" ]]; then
    # shellcheck source=/dev/null
    source "${HOME}/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
fi
: "${COLOR_PRIMARY:=#fe8019}"
: "${COLOR_ON_SURFACE:=#ebdbb2}"

# Paint multi-line ASCII with gum (theme primary) or plain
_header_paint() {
    local line
    if command -v gum >/dev/null 2>&1; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # gum style on empty lines still advances
            printf '%s\n' "$line" | gum style --foreground "${COLOR_PRIMARY}" 2>/dev/null \
                || printf '%s\n' "$line"
        done
        return 0
    fi
    cat
}

_header_render_tool() {
    local title="$1"
    local out=""

    if command -v toilet >/dev/null 2>&1; then
        out=$(toilet -f graffiti "$title" 2>/dev/null) || out=$(toilet "$title" 2>/dev/null) || true
        if [[ -n "$out" ]]; then
            printf '%s\n' "$out"
            return 0
        fi
    fi

    if command -v figlet >/dev/null 2>&1; then
        local font
        for font in graffiti slant standard big small; do
            if out=$(figlet -f "$font" "$title" 2>/dev/null); then
                printf '%s\n' "$out"
                return 0
            fi
        done
        if out=$(figlet "$title" 2>/dev/null); then
            printf '%s\n' "$out"
            return 0
        fi
    fi

    return 1
}

print_header() {
    local title="${1:-}"
    [[ -z "$title" ]] && return 0

    echo ""
    if out=$(_header_render_tool "$title"); then
        # Prefer themed gum paint; lsd-print is rainbow (not palette-aware) — use only
        # when gum is missing so install still looks colorful.
        if command -v gum >/dev/null 2>&1; then
            printf '%s\n' "$out" | _header_paint
        elif command -v lsd-print >/dev/null 2>&1; then
            printf '%s\n' "$out" | lsd-print
        else
            printf '%s\n' "$out"
        fi
    else
        if command -v gum >/dev/null 2>&1; then
            printf '=== %s ===\n' "$title" | gum style --foreground "${COLOR_PRIMARY}" --bold 2>/dev/null \
                || printf '=== %s ===\n' "$title"
        elif command -v lsd-print >/dev/null 2>&1; then
            printf '=== %s ===\n' "$title" | lsd-print
        else
            printf '=== %s ===\n' "$title"
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
