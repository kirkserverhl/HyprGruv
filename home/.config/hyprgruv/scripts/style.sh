#!/bin/bash
# Universal Styling Library for Hypr Scripts
# matugen colors + toilet/lsd-print headers + gum

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true

if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
else
    export COLOR_PRIMARY="#89b4fa"
    export COLOR_SUCCESS="#a6e3a1"
    export COLOR_ERROR="#f38ba8"
    export COLOR_TEXT="#cdd6f4"
    export COLOR_SURFACE="#1e1e2e"
fi

print_header() {
    local title="$1"
    clear
    if declare -f display_header >/dev/null 2>&1; then
        display_header "$title"
    elif command -v toilet >/dev/null 2>&1; then
        if command -v lsd-print >/dev/null 2>&1; then
            toilet -f graffiti "$title" | lsd-print
        else
            toilet -f graffiti "$title"
        fi
    else
        echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
    fi
    echo ""
}

print_section() {
    local title="$1"
    echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
}

print_box() {
    local content="$1"
    echo "$content" | gum style \
        --foreground "$COLOR_TEXT" \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 3"
}

confirm_action() {
    gum confirm --affirmative "Yes" --negative "Cancel" "$1"
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold "✗ $1"
}