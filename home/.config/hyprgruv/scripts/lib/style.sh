#!/bin/bash
# Universal styling library — live palette + toilet/figlet headers + gum
#
# Default: gruvbox. Follows system when matugen/preset colors are present
# (via colors.sh → hypr matugen.conf / shell cache).

# shellcheck source=/dev/null
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
# shellcheck source=/dev/null
source "$HOME/.config/hyprgruv/scripts/colors.sh" --gum 2>/dev/null || true

# Gruvbox fallbacks if colors.sh missing (pre-stow)
: "${COLOR_PRIMARY:="#fe8019"}"
: "${COLOR_SUCCESS:="#b8bb26"}"
: "${COLOR_ERROR:="#fb4934"}"
: "${COLOR_TEXT:="#ebdbb2"}"
: "${COLOR_ON_SURFACE:="#ebdbb2"}"
: "${COLOR_SURFACE_CONTAINER:="#3c3836"}"

print_header() {
    local title="$1"
    clear
    if declare -f display_header >/dev/null 2>&1; then
        display_header "$title"
    elif command -v toilet >/dev/null 2>&1; then
        toilet -f graffiti "$title" 2>/dev/null | while IFS= read -r line; do
            printf '%s\n' "$line" | gum style --foreground "$COLOR_PRIMARY" 2>/dev/null || printf '%s\n' "$line"
        done
    else
        echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold 2>/dev/null || echo "=== $title ==="
    fi
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold 2>/dev/null || echo "== $title =="
}

print_box() {
    local content="$1"
    echo "$content" | gum style \
        --foreground "$COLOR_TEXT" \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 3" \
        --width 95 2>/dev/null || echo "$content"
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ $1" 2>/dev/null || echo "✓ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold "✗ $1" 2>/dev/null || echo "✗ $1"
}
