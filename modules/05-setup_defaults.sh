#!/bin/bash

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "${REPO_DOTFILES_SCRIPTS}/header.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "${REPO_DOTFILES_SCRIPTS}/colors.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
command -v gum_apply_matugen_theme >/dev/null 2>&1 && gum_apply_matugen_theme 2>/dev/null || true

display_header "Defaults"

SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/settings"

# Ensure gum is present (05 can be run standalone or after SKIP_PACKAGES)
if ! command -v gum >/dev/null 2>&1; then
    echo "gum not found, installing..."
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm gum || true
    else
        sudo pacman -S --needed --noconfirm gum || true
    fi
fi

# Style header (matugen primary)
gum style --foreground "${COLOR_PRIMARY:-#89b4fa}" --border double --border-foreground "${COLOR_OUTLINE:-#6c7086}" --align center --width 50 --margin "1 2" --padding "2 4" "Set Default Programs" 2>/dev/null || echo "=== Set Default Programs ==="

# Supported mappings (choice:package for install)
declare -A terms=(["kitty"]="kitty" ["alacritty"]="alacritty" ["ghostty"]="ghostty" ["wezterm"]="wezterm" ["foot"]="foot")
declare -A browsers=(["brave"]="brave-bin" ["firefox"]="firefox" ["chromium"]="chromium" ["chrome"]="google-chrome")
declare -A browser_cmds=(["brave"]="brave" ["firefox"]="firefox" ["chromium"]="chromium" ["chrome"]="google-chrome-stable")
declare -A editors=(["nvim"]="neovim" ["vim"]="vim" ["nano"]="nano")

write_setting() {
    local name="$1"
    local value="$2"
    mkdir -p "$SETTINGS_DIR"
    printf '%s\n' "$value" >"$SETTINGS_DIR/${name}.sh"
}

remove_legacy_defaults() {
    local dir
    for dir in \
        "$HYPR_DIR/defaults" \
        "$HYPR_DIR/modules/defaults" \
        "$HOME/defaults"; do
        [[ -d "$dir" ]] || continue
        rm -f "$dir/terminal.sh" "$dir/browser.sh" "$dir/editor.sh"
        rmdir "$dir" 2>/dev/null || true
    done
}

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
TERMINAL=$(gum choose "kitty" "alacritty" "ghostty" "wezterm" "foot" "other")
if [ "$TERMINAL" = "other" ]; then
    TERMINAL=$(gum input --placeholder "Enter terminal command")
fi

# Install if supported and missing
if [ "${terms[$TERMINAL]}" ] && ! command -v "$TERMINAL" >/dev/null; then
    gum confirm "Install $TERMINAL?" && install_pkg "${terms[$TERMINAL]}"
fi

# Choose browser (supported + other)
BROWSER_CHOICE=$(gum choose "brave" "firefox" "chromium" "chrome" "other")
if [ "$BROWSER_CHOICE" = "other" ]; then
    BROWSER_CMD=$(gum input --placeholder "Enter browser command")
else
    BROWSER_CMD="${browser_cmds[$BROWSER_CHOICE]}"
fi

# Install if supported and missing
if [ "${browsers[$BROWSER_CHOICE]}" ] && ! command -v "$BROWSER_CMD" >/dev/null; then
    gum confirm "Install $BROWSER_CHOICE?" && install_pkg "${browsers[$BROWSER_CHOICE]}"
fi

# Choose editor (supported + other)
EDITOR_CHOICE=$(gum choose "nvim" "vim" "nano" "other")
if [ "$EDITOR_CHOICE" = "other" ]; then
    EDITOR_CMD=$(gum input --placeholder "Enter editor command")
else
    EDITOR_CMD="$EDITOR_CHOICE"
fi

# Install if supported and missing
if [ "${editors[$EDITOR_CHOICE]}" ] && ! command -v "$EDITOR_CMD" >/dev/null; then
    gum confirm "Install $EDITOR_CHOICE?" && install_pkg "${editors[$EDITOR_CHOICE]}"
fi

write_setting terminal "$TERMINAL"
write_setting browser "$BROWSER_CMD"
write_setting editor "$EDITOR_CMD"
remove_legacy_defaults

gum style --foreground "${COLOR_SECONDARY:-${COLOR_PRIMARY:-#a6e3a1}}" "Defaults saved to $SETTINGS_DIR"
gum style --foreground "${COLOR_ON_SURFACE:-#cdd6f4}" "Terminal=$TERMINAL, Browser=$BROWSER_CMD, Editor=$EDITOR_CMD"

if declare -F mark_completed >/dev/null 2>&1; then
    mark_completed "Setup defaults"
fi