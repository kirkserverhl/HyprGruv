#!/usr/bin/env bash
# header.sh — Reliable, easy figlet headers for your scripts
#
# Usage (recommended):
#   source "$HOME/.config/hypr/scripts/header.sh"
#   print_header "Updates"
#   print_header "My Cool Tool" | lsd-print
#
# Or for the old name many scripts already use:
#   display_header "Shell Setup"
#
# Convenience clear version:
#   clear_header "Title"
#
# This file:
#   - Finds your Graffiti.flf reliably (even if symlinks move)
#   - Sets up FIGLET_FONTDIR so `figlet -f graffiti` works in the future
#   - Has graceful fallbacks when system fonts are missing
#   - Does NOT clear the screen by default (safer for sourcing in libraries)

# -----------------------------------------------------------------------------
# Locate the Graffiti font (your custom one)
# -----------------------------------------------------------------------------
_resolve_graffiti_font() {
    local candidates=(
        "$HOME/.fonts/Graffiti.flf"
        "$HOME/.hyprgruv/home/.fonts/Graffiti.flf"
        "$HOME/.local/share/figlet/Graffiti.flf"
        "$HOME/.local/share/figlet/graffiti.flf"
    )

    for f in "${candidates[@]}"; do
        [[ -f "$f" ]] && { echo "$f"; return 0; }
    done

    # Follow the ~/.fonts symlink if it exists (your current setup)
    if [[ -L "$HOME/.fonts" ]]; then
        local real
        real=$(readlink -f "$HOME/.fonts/Graffiti.flf" 2>/dev/null || true)
        [[ -f "$real" ]] && { echo "$real"; return 0; }
    fi

    return 1
}

GRAFFITI_FONT=""
if GRAFFITI_FONT=$(_resolve_graffiti_font 2>/dev/null); then
    export GRAFFITI_FONT

    # Make the font available by short name "graffiti" for convenience
    mkdir -p "$HOME/.local/share/figlet"
    ln -sfn "$GRAFFITI_FONT" "$HOME/.local/share/figlet/graffiti.flf" 2>/dev/null || true
    ln -sfn "$GRAFFITI_FONT" "$HOME/.local/share/figlet/Graffiti.flf" 2>/dev/null || true

    # Tell figlet where to find user fonts (so -f graffiti works)
    export FIGLET_FONTDIR="$HOME/.local/share/figlet${FIGLET_FONTDIR:+:$FIGLET_FONTDIR}"
fi

# -----------------------------------------------------------------------------
# Main function - use this in new scripts
# -----------------------------------------------------------------------------
print_header() {
    local title="${1:-}"

    [[ -z "$title" ]] && return 0

    if command -v figlet >/dev/null 2>&1; then
        if [[ -n "$GRAFFITI_FONT" ]]; then
            # Best case: your custom Graffiti font
            figlet -f "$GRAFFITI_FONT" "$title"
        else
            # Try nice built-in fonts (in order of preference)
            for font in graffiti slant standard big small; do
                if figlet -f "$font" "$title" >/dev/null 2>&1; then
                    figlet -f "$font" "$title"
                    return 0
                fi
            done
            # Last resort - whatever default figlet has
            figlet "$title"
        fi
    else
        # No figlet installed at all - clean fallback
        echo
        printf '=== %s ===\n' "$title"
        echo
    fi
}

# -----------------------------------------------------------------------------
# Backward compatibility names (so existing scripts keep working)
# -----------------------------------------------------------------------------
display_header() {
    print_header "$@"
}

# -----------------------------------------------------------------------------
# Convenience: clear screen + header (many of your scripts like this pattern)
# -----------------------------------------------------------------------------
clear_header() {
    clear
    print_header "$@"
    echo
}

# Short friendly alias
header() {
    print_header "$@"
}

# Export the functions so they are available after sourcing
export -f print_header display_header clear_header header 2>/dev/null || true

# Optional: if someone sources this with --clear, show a header immediately
if [[ "${1:-}" == "--clear" || "${1:-}" == "clear" ]]; then
    shift
    clear_header "${1:-Header}"
fi
