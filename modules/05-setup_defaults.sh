#!/bin/bash

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

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

hyprgruv_section_intro "Set default programs"
echo ""

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
hyprgruv_section_intro "Terminal"
TERMINAL=$(gum_choose_prompt --header "Default terminal:" "kitty" "alacritty" "ghostty" "wezterm" "foot" "other")
if [ "$TERMINAL" = "other" ]; then
    TERMINAL=$(gum input --placeholder "Enter terminal command")
fi

# Install if supported and missing
if [ "${terms[$TERMINAL]}" ] && ! command -v "$TERMINAL" >/dev/null; then
    gum_confirm_prompt "Install $TERMINAL?" && install_pkg "${terms[$TERMINAL]}"
fi
hyprgruv_section_transition "Terminal set to $TERMINAL"

# Choose browser (supported + other)
hyprgruv_section_intro "Browser"
BROWSER_CHOICE=$(gum_choose_prompt --header "Default browser:" "brave" "firefox" "chromium" "chrome" "other")
if [ "$BROWSER_CHOICE" = "other" ]; then
    BROWSER_CMD=$(gum input --placeholder "Enter browser command")
else
    BROWSER_CMD="${browser_cmds[$BROWSER_CHOICE]}"
fi

# Install if supported and missing
if [ "${browsers[$BROWSER_CHOICE]}" ] && ! command -v "$BROWSER_CMD" >/dev/null; then
    gum_confirm_prompt "Install $BROWSER_CHOICE?" && install_pkg "${browsers[$BROWSER_CHOICE]}"
fi
hyprgruv_section_transition "Browser set to $BROWSER_CMD"

# Choose editor (supported + other)
hyprgruv_section_intro "Editor"
EDITOR_CHOICE=$(gum_choose_prompt --header "Default editor:" "nvim" "vim" "nano" "other")
if [ "$EDITOR_CHOICE" = "other" ]; then
    EDITOR_CMD=$(gum input --placeholder "Enter editor command")
else
    EDITOR_CMD="$EDITOR_CHOICE"
fi

# Install if supported and missing
if [ "${editors[$EDITOR_CHOICE]}" ] && ! command -v "$EDITOR_CMD" >/dev/null; then
    gum_confirm_prompt "Install $EDITOR_CHOICE?" && install_pkg "${editors[$EDITOR_CHOICE]}"
fi
hyprgruv_section_transition "Editor set to $EDITOR_CMD"

write_setting terminal "$TERMINAL"
write_setting browser "$BROWSER_CMD"
write_setting editor "$EDITOR_CMD"
remove_legacy_defaults

hyprgruv_section_transition "Defaults saved"
gum style --foreground "${COLOR_SECONDARY:-#83a598}" "Saved to $SETTINGS_DIR" 2>/dev/null \
    || log_success "Saved to $SETTINGS_DIR"
gum style --foreground "${COLOR_ON_SURFACE:-#cdd6f4}" "Terminal=$TERMINAL, Browser=$BROWSER_CMD, Editor=$EDITOR_CMD"

if declare -F mark_completed >/dev/null 2>&1; then
    mark_completed "Setup defaults"
fi