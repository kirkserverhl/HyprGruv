#!/bin/bash
# =============================================
# Universal Styling Library for Hypr Scripts
# Uses matugen colors + consistent figlet + gum
# =============================================

# Source matugen colors
if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
else
    # Fallback colors
    export COLOR_PRIMARY="#89b4fa"
    export COLOR_SUCCESS="#a6e3a1"
    export COLOR_ERROR="#f38ba8"
    export COLOR_TEXT="#cdd6f4"
    export COLOR_SURFACE="#1e1e2e"
fi

# Figlet font (you mentioned graffiti style)
export FIGLET_FONT="graffiti" # You can change to "slant", "big", "doh", etc.

# Common gum styling functions
print_header() {
    local title="$1"
    clear
    figlet -f "$FIGLET_FONT" "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
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
