#!/usr/bin/env bash
# header.sh — Colorized ASCII headers (toilet + lsd-print, figlet fallback)
#
# Usage:
#   source "$HOME/.config/hypr/scripts/header.sh"
#   display_header "Shell"
#   print_header "My Tool" | lsd-print   # pipe only if you skipped built-in color
#
# Preferred output:
#   toilet -f graffiti "$title" | lsd-print

# -----------------------------------------------------------------------------
# Main function
# -----------------------------------------------------------------------------
print_header() {
    local title="${1:-}"
    [[ -z "$title" ]] && return 0

    # Best case: toilet graffiti font + lsd-print colorization
    if command -v toilet >/dev/null 2>&1; then
        if command -v lsd-print >/dev/null 2>&1; then
            toilet -f graffiti "$title" | lsd-print
        else
            toilet -f graffiti "$title"
        fi
        return 0
    fi

    # Legacy figlet fallback (older installs / missing toilet)
    if command -v figlet >/dev/null 2>&1; then
        for font in graffiti slant standard big small; do
            if figlet -f "$font" "$title" >/dev/null 2>&1; then
                if command -v lsd-print >/dev/null 2>&1; then
                    figlet -f "$font" "$title" | lsd-print
                else
                    figlet -f "$font" "$title"
                fi
                return 0
            fi
        done
        if command -v lsd-print >/dev/null 2>&1; then
            figlet "$title" | lsd-print
        else
            figlet "$title"
        fi
        return 0
    fi

    # Plain fallback
    echo
    if command -v lsd-print >/dev/null 2>&1; then
        printf '=== %s ===\n' "$title" | lsd-print
    else
        printf '=== %s ===\n' "$title"
    fi
    echo
}

# -----------------------------------------------------------------------------
# Backward compatibility names
# -----------------------------------------------------------------------------
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