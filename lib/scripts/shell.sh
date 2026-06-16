#!/usr/bin/env bash
# shell.sh — select and configure default shell (bash/zsh) with plugin setup
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/ and load helpers
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
}
[[ -f "$HYPR_DIR/lib/state.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
}
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# ------------------------------------------------------------
# Ensure prerequisites VERY EARLY (before any sourcing or gum usage)
# ------------------------------------------------------------
ensure_cmd() {
    local c="$1" install_msg="$2" pkg="$3"
    if command -v "$c" >/dev/null 2>&1; then
        return 0
    fi
    log_status "$install_msg"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "$pkg"
    else
        sudo pacman -S --needed --noconfirm "$pkg"
    fi
    hash -r 2>/dev/null || true
    if ! command -v "$c" >/dev/null 2>&1; then
        log_error "$pkg installed but '$c' is not available in PATH"
        return 1
    fi
}

resolve_shell_path() {
    local name="$1"
    local path=""

    if command -v "$name" >/dev/null 2>&1; then
        path="$(command -v "$name")"
    elif [[ -x "/usr/bin/$name" ]]; then
        path="/usr/bin/$name"
    elif [[ -x "/bin/$name" ]]; then
        path="/bin/$name"
    fi

    [[ -n "$path" && -x "$path" ]] || return 1
    echo "$path"
}

ensure_shell_allowed() {
    local shell_path="$1"
    if grep -Fxq "$shell_path" /etc/shells 2>/dev/null; then
        return 0
    fi
    log_warning "$shell_path is not listed in /etc/shells — adding it"
    echo "$shell_path" | sudo tee -a /etc/shells >/dev/null
}

ensure_zsh_ready() {
    ensure_cmd zsh "Installing zsh…" zsh

    if ! pacman -Qq zsh &>/dev/null 2>&1; then
        log_error "zsh package is not registered with pacman after install"
        return 1
    fi

    local zsh_path
    zsh_path="$(resolve_shell_path zsh)" || {
        log_error "zsh binary not found after install"
        return 1
    }

    ensure_shell_allowed "$zsh_path"
    log_success "zsh ready at $zsh_path ($(zsh --version 2>/dev/null | head -1 || echo 'version unknown'))"
    return 0
}

set_login_shell() {
    local target="$1"
    local user="${USER:-$(whoami)}"
    local current

    current="$(getent passwd "$user" | cut -d: -f7)"
    if [[ "$current" == "$target" ]]; then
        log_success "Login shell is already $target"
        return 0
    fi

    log_status "Changing login shell: $current → $target"
    echo "You may be prompted for your account password (not root)."
    # gum leaves the TTY in raw mode; restore it so chsh can read the password
    stty sane 2>/dev/null || true
    sleep 0.5

    if chsh -s "$target"; then
        current="$(getent passwd "$user" | cut -d: -f7)"
        if [[ "$current" == "$target" ]]; then
            log_success "Login shell updated to $target"
            log_status "Open a new terminal or log out/in for the change to apply"
            return 0
        fi
        log_warning "chsh reported success but login shell is still $current"
    else
        log_warning "chsh failed"
    fi

    log_warning "Login shell is still $current"
    if gum confirm "Try again using sudo?"; then
        if sudo chsh -s "$target" "$user" || sudo usermod -s "$target" "$user"; then
            current="$(getent passwd "$user" | cut -d: -f7)"
            if [[ "$current" == "$target" ]]; then
                log_success "Login shell updated via sudo to $target"
                log_status "Open a new terminal or log out/in for the change to apply"
                return 0
            fi
        fi
    fi

    log_error "Could not set login shell to $target (current: $current)"
    log_status "Run manually: chsh -s $target"
    return 1
}

ensure_cmd gum "Installing gum…" gum
ensure_cmd git "Installing git…" git

# ------------------------------------------------------------
# Theming for gum + headers
# ------------------------------------------------------------
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true
gum_apply_matugen_theme
export GUM_CONFIRM_PROMPT="? Would you like to change your default shell? "

display_header "SHELL"

# ------------------------------------------------------------
# Prompt user
# ------------------------------------------------------------
echo ""
echo "Please select your preferred shell"
sleep 0.5

shell="$(gum choose "zsh" "bash" "CANCEL")"
selected_shell_path=""

# ------------------------------------------------------------
# Activate bash
# ------------------------------------------------------------
if [[ "$shell" == "bash" ]]; then
    ensure_cmd bash "Installing bash…" bash
    selected_shell_path="$(resolve_shell_path bash)" || {
        log_error "bash binary not found"
        exit 1
    }
    ensure_shell_allowed "$selected_shell_path"
fi

# ------------------------------------------------------------
# Activate zsh
# ------------------------------------------------------------
if [[ "$shell" == "zsh" ]]; then
    ensure_zsh_ready || exit 1
    selected_shell_path="$(resolve_shell_path zsh)" || {
        log_error "Could not resolve zsh path after install"
        exit 1
    }

    # Oh My Zsh plugins (only if Oh My Zsh is installed)
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        mkdir -p "$ZSH_CUSTOM_DIR/plugins"

        if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]]; then
            echo "Installing zsh-autosuggestions"
            git clone https://github.com/zsh-users/zsh-autosuggestions \
                "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
        else
            echo "zsh-autosuggestions already installed"
        fi

        if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]]; then
            echo "Installing zsh-syntax-highlighting"
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
                "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
        else
            echo "zsh-syntax-highlighting already installed"
        fi

        if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting" ]]; then
            echo "Installing fast-syntax-highlighting"
            git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
                "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
        else
            echo "fast-syntax-highlighting already installed"
        fi

        echo ""
        log_status "Add the plugins to your ~/.zshrc, e.g.:"
        echo "  plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)"
    else
        log_status "Oh My Zsh not detected (~/.oh-my-zsh). Skipping plugin installs."
        echo "To install it later:  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\""
    fi
fi

# ------------------------------------------------------------
# Cancel
# ------------------------------------------------------------
if [[ "$shell" == "CANCEL" || -z "$selected_shell_path" ]]; then
    echo "Changing shell canceled."
    exit 0
fi

# ------------------------------------------------------------
# Change login shell last (after gum + plugin setup; needs a sane TTY)
# ------------------------------------------------------------
echo ""
log_status "Applying login shell change…"
set_login_shell "$selected_shell_path" || exit 1

gum spin --spinner dot --title "Shell changed. Please log out/in to apply." -- sleep 2
exit 0