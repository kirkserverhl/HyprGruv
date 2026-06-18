#!/bin/bash

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

display_header "Defaults"

# Ensure gum is present (05 can be run standalone or after SKIP_PACKAGES)
if ! command -v gum >/dev/null 2>&1; then
    echo "gum not found, installing..."
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm gum || true
    else
        sudo pacman -S --needed --noconfirm gum || true
    fi
fi

# Style header
gum style --foreground 212 --border double --align center --width 50 --margin "1 2" --padding "2 4" "Set Default Programs" 2>/dev/null || echo "=== Set Default Programs ==="

# Supported mappings (cmd:pkg)
declare -A terms=(["kitty"]="kitty" ["alacritty"]="alacritty" ["wezterm"]="wezterm" ["foot"]="foot")
declare -A browsers=(["brave"]="brave-bin" ["firefox"]="firefox" ["chromium"]="chromium" ["chrome"]="google-chrome")
declare -A editors=(["nvim"]="neovim" ["vim"]="vim" ["nano"]="nano")

# Install function (pacman for official, yay for AUR if available)
install_pkg() {
    local pkg=$1
    if pacman -Si "$pkg" >/dev/null 2>&1; then
        sudo pacman -Syu --noconfirm "$pkg"
    elif command -v yay >/dev/null; then
        yay -S --noconfirm "$pkg"
    else
        echo "AUR package $pkg requires yay or manual install."
    fi
}

# Choose terminal (supported + other)
TERMINAL=$(gum choose "kitty" "alacritty" "wezterm" "foot" "other")
if [ "$TERMINAL" = "other" ]; then
    TERMINAL=$(gum input --placeholder "Enter terminal command")
fi

# Install if supported and missing
if [ "${terms[$TERMINAL]}" ] && ! command -v "$TERMINAL" >/dev/null; then
    gum confirm "Install $TERMINAL?" && install_pkg "${terms[$TERMINAL]}"
fi

# Choose browser (supported + other)
BROWSER=$(gum choose "brave" "firefox" "chromium" "chrome" "other")
if [ "$BROWSER" = "other" ]; then
    BROWSER=$(gum input --placeholder "Enter browser command")
fi

# Install if supported and missing
if [ "${browsers[$BROWSER]}" ] && ! command -v "$BROWSER" >/dev/null; then
    gum confirm "Install $BROWSER?" && install_pkg "${browsers[$BROWSER]}"
fi

# Choose editor (supported + other)
EDITOR_CHOICE=$(gum choose "nvim" "vim" "nano" "other")
if [ "$EDITOR_CHOICE" = "other" ]; then
    EDITOR_CHOICE=$(gum input --placeholder "Enter editor command")
fi

# Install if supported and missing
if [ "${editors[$EDITOR_CHOICE]}" ] && ! command -v "$EDITOR_CHOICE" >/dev/null; then
    gum confirm "Install $EDITOR_CHOICE?" && install_pkg "${editors[$EDITOR_CHOICE]}"
fi

# Create defaults dir
mkdir -p defaults

# Write terminal.sh
cat >defaults/terminal.sh <<EOF
#!/bin/sh
echo "$TERMINAL"
EOF
chmod +x defaults/terminal.sh

# Write browser.sh
cat >defaults/browser.sh <<EOF
#!/bin/sh
echo "$BROWSER"
EOF
chmod +x defaults/browser.sh

# Write editor.sh
cat >defaults/editor.sh <<EOF
#!/bin/sh
echo "$EDITOR_CHOICE"
EOF
chmod +x defaults/editor.sh

gum style --foreground green "Defaults set: Terminal=$TERMINAL, Browser=$BROWSER, Editor=$EDITOR_CHOICE"

if declare -F mark_completed >/dev/null 2>&1; then
    mark_completed "Setup defaults"
fi
