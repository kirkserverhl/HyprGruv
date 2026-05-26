#!/bin/bash
# =============================================
# Universal Styling Library (matches your other scripts)
# =============================================

# Source matugen colors
if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
fi

# Fallback colors
: "${COLOR_PRIMARY:="#89b4fa"}"
: "${COLOR_SUCCESS:="#a6e3a1"}"
: "${COLOR_ERROR:="#f38ba8"}"
: "${COLOR_TEXT:="#cdd6f4"}"

# Figlet configuration - matching your working scripts
export FIGLET_FONT="$HOME/.fonts/Graffiti.flf"

print_header() {
    local title="$1"
    clear
    
    if [ -f "$FIGLET_FONT" ]; then
        figlet -f "$cat > ~/.config/hypr/scripts/lib/style.sh << 'EOF'
#!/bin/bash
# =============================================
# Universal Styling Library
# =============================================

# Source matugen colors
if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
fi

# Fallback colors
: "${COLOR_PRIMARY:="#89b4fa"}"
: "${COLOR_SUCCESS:="#a6e3a1"}"
: "${COLOR_ERROR:="#f38ba8"}"
: "${COLOR_TEXT:="#cdd6f4"}"

# Figlet font (your graffiti)
export FIGLET_FONT="$HOME/.fonts/Graffiti.flf"

print_header() {
    local title="$1"
    clear
    if [ -f "$FIGLET_FONT" ]; then
        figlet -f "$FIGLET_FONT" "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
    else
        figlet -f standard "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
    fi
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
}

print_box() {
    local content="$1"
    echo "$content" | gum style \
        --foreground "$COLOR_TEXT" \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 3" \
        --width 95
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold "✗ $1"
}
cat > ~/.config/hypr/scripts/lib/style.sh << 'EOF'
#!/bin/bash
# =============================================
# Universal Styling Library
# =============================================

# Source matugen colors
if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
fi

# Fallback colors
: "${COLOR_PRIMARY:="#89b4fa"}"
: "${COLOR_SUCCESS:="#a6e3a1"}"
: "${COLOR_ERROR:="#f38ba8"}"
: "${COLOR_TEXT:="#cdd6f4"}"

# Figlet font (your graffiti)
export FIGLET_FONT="$HOME/.fonts/Graffiti.flf"

print_header() {
    local title="$1"
    clear
    if [ -f "$FIGLET_FONT" ]; then
        figlet -f "$FIGLET_FONT" "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
    else
        figlet -f standard "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
    fi
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
}

print_box() {
    local content="$1"
    echo "$content" | gum style \
        --foreground "$COLOR_TEXT" \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 3" \
        --width 95
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold "✗ $1"
}
EOF
