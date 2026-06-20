#!/usr/bin/env bash
# shell.sh — select and configure default shell (fish/zsh/bash) with plugin setup
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
    local candidate

    # Prefer distro binaries over ~/.local/bin wrappers (fish launcher script).
    for candidate in "/usr/bin/$name" "/bin/$name"; do
        if [[ -x "$candidate" ]]; then
            path="$candidate"
            break
        fi
    done

    if [[ -z "$path" ]] && command -v "$name" >/dev/null 2>&1; then
        path="$(command -v "$name")"
        if [[ "$name" == "fish" && "$path" == "$HOME/.local/bin/fish" ]]; then
            path=""
        fi
    fi

    if [[ -z "$path" && "$name" == "fish" && -x "$HOME/.local/fish-root/usr/bin/fish" ]]; then
        path="$HOME/.local/fish-root/usr/bin/fish"
    fi

    [[ -n "$path" && -x "$path" ]] || return 1
    echo "$path"
}

canonical_shell_path() {
    local path="$1"
    local real=""

    if command -v realpath >/dev/null 2>&1; then
        real="$(realpath "$path" 2>/dev/null || true)"
    elif command -v readlink >/dev/null 2>&1; then
        real="$(readlink -f "$path" 2>/dev/null || true)"
    fi

    [[ -n "$real" && -x "$real" ]] && echo "$real" && return 0
    echo "$path"
}

ensure_shell_allowed() {
    local shell_path="$1"
    local canonical
    canonical="$(canonical_shell_path "$shell_path")"

    if grep -Fxq "$canonical" /etc/shells 2>/dev/null; then
        return 0
    fi
    if [[ "$canonical" != "$shell_path" ]] && grep -Fxq "$shell_path" /etc/shells 2>/dev/null; then
        return 0
    fi

    log_warning "$canonical is not listed in /etc/shells — adding it"
    echo "$canonical" | sudo tee -a /etc/shells >/dev/null
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

ensure_fish_ready() {
    local fish_path=""

    fish_path="$(resolve_shell_path fish)" || true

    if [[ -z "$fish_path" ]]; then
        log_status "Installing fish system-wide (required for login shell after reboot)…"
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm fish || true
        else
            sudo pacman -S --needed --noconfirm fish || true
        fi
        hash -r 2>/dev/null || true
        fish_path="$(resolve_shell_path fish)" || true
    fi

    if [[ -z "$fish_path" && -x "$HOME/.local/fish-root/usr/bin/fish" ]]; then
        fish_path="$HOME/.local/fish-root/usr/bin/fish"
        log_warning "Using user-local fish at $fish_path — install system fish for best reboot reliability"
        log_status "System install: yay -S fish"
    fi

    [[ -n "$fish_path" ]] || {
        log_error "fish binary not found — run: yay -S fish"
        return 1
    }

    # chsh rejects wrapper scripts; always register the real binary.
    fish_path="$(canonical_shell_path "$fish_path")"
    ensure_shell_allowed "$fish_path"
    log_success "fish ready at $fish_path ($("$fish_path" --version 2>/dev/null | head -1 || echo 'version unknown'))"
    return 0
}

deploy_shell_configs() {
    local shell_name="$1"
    local repo_home="$HYPR_DIR/home"
    local linked=0

    link_repo_file() {
        local rel="$1"
        local src="$repo_home/$rel"
        local dest="$HOME/$rel"

        [[ -e "$src" ]] || return 0

        if [[ -L "$dest" ]]; then
            local current
            current="$(readlink "$dest" 2>/dev/null || true)"
            if [[ "$current" == "$src" || "$current" == "../.hyprgruv/home/$rel" ]]; then
                return 0
            fi
        fi

        if [[ -e "$dest" && ! -L "$dest" ]]; then
            log_status "Keeping existing ~/$rel (not overwriting regular file)"
            return 0
        fi

        mkdir -p "$(dirname "$dest")"
        ln -sfn "$src" "$dest"
        log_success "Linked ~/$rel → repo"
        linked=1
    }

    case "$shell_name" in
        zsh)
            link_repo_file ".zshrc"
            link_repo_file ".zprofile"
            link_repo_file ".zshenv"
            ;;
        fish)
            if [[ -d "$repo_home/.config/fish" ]]; then
                if [[ -e "$HOME/.config/fish" && ! -L "$HOME/.config/fish" ]]; then
                    log_status "Keeping existing ~/.config/fish directory"
                else
                    mkdir -p "$HOME/.config"
                    ln -sfn "$repo_home/.config/fish" "$HOME/.config/fish"
                    log_success "Linked ~/.config/fish → repo"
                    linked=1
                fi
            fi
            ;;
    esac

    if [[ "$linked" -eq 1 ]]; then
        log_status "Shell config deployed — new terminals will pick this up after reboot"
    fi
}

verify_shell_startup() {
    local shell_name="$1"
    local shell_path="$2"

    case "$shell_name" in
        zsh)
            [[ -f "$HOME/.zshrc" ]] || log_warning "~/.zshrc missing — zsh will start with minimal config"
            ;;
        fish)
            [[ -d "$HOME/.config/fish" ]] || log_warning "~/.config/fish missing — fish will use defaults only"
            ;;
    esac

    if ! grep -Fxq "$(canonical_shell_path "$shell_path")" /etc/shells 2>/dev/null; then
        log_warning "$shell_path is not in /etc/shells — login may fall back after reboot"
    fi
}

pick_shell() {
    local choice=""
    local gum_status=0

    # Prior gum prompts can leave the TTY in raw mode and break choose (empty selection).
    stty sane 2>/dev/null || true

    if command -v gum >/dev/null 2>&1; then
        set +e
        if _hyprgruv_has_tty; then
            choice="$(
                gum choose \
                    --header "Default shell (↑↓ to move, Enter to confirm, Esc to cancel):" \
                    --height 6 \
                    "fish" "zsh" "bash" "CANCEL" \
                    </dev/tty 2>/dev/tty
            )"
        else
            choice="$(
                gum choose \
                    --header "Default shell:" \
                    --height 6 \
                    "fish" "zsh" "bash" "CANCEL"
            )"
        fi
        gum_status=$?
        set -e
    fi

    choice="${choice//$'\r'/}"
    choice="${choice#"${choice%%[![:space:]]*}"}"
    choice="${choice%"${choice##*[![:space:]]}"}"

    if [[ $gum_status -ne 0 || -z "$choice" ]]; then
        log_warning "Gum menu unavailable or canceled — falling back to text menu"
        echo ""
        echo "  1) fish"
        echo "  2) zsh"
        echo "  3) bash"
        echo "  q) cancel"
        echo ""
        local reply=""
        if _hyprgruv_has_tty; then
            read -rp "Choose [1-3/q]: " reply </dev/tty
        else
            read -rp "Choose [1-3/q]: " reply
        fi
        case "${reply,,}" in
            1|fish) choice="fish" ;;
            2|zsh) choice="zsh" ;;
            3|bash) choice="bash" ;;
            q|quit|"") choice="CANCEL" ;;
            *) choice="" ;;
        esac
    fi

    [[ -n "$choice" ]] || return 1
    echo "$choice"
}

set_login_shell() {
    local target="$1"
    local user="${USER:-$(whoami)}"
    local current

    target="$(canonical_shell_path "$target")"
    ensure_shell_allowed "$target"

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
            log_status "Reboot or log out/in so new terminals use $target"
            return 0
        fi
        log_warning "chsh reported success but login shell is still $current"
    else
        log_warning "chsh failed"
    fi

    log_warning "Login shell is still $current"
    if gum_confirm_prompt "Try again using sudo?"; then
        if sudo chsh -s "$target" "$user" || sudo usermod -s "$target" "$user"; then
            current="$(getent passwd "$user" | cut -d: -f7)"
            if [[ "$current" == "$target" ]]; then
                log_success "Login shell updated via sudo to $target"
                log_status "Reboot or log out/in so new terminals use $target"
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
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
gum_apply_matugen_theme
export GUM_CONFIRM_PROMPT="? Would you like to change your default shell? "

if [[ "${HYPRGRUV_FROM_CONFIG:-0}" != "1" ]]; then
    hyprgruv_section_intro "Shell"
fi

# ------------------------------------------------------------
# Prompt user
# ------------------------------------------------------------
echo "Please select your preferred shell"
echo ""

shell="$(pick_shell)" || {
    echo "No shell selected."
    exit 0
}
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
    selected_shell_path="$(canonical_shell_path "$selected_shell_path")"

    deploy_shell_configs zsh
    verify_shell_startup zsh "$selected_shell_path"
fi

# ------------------------------------------------------------
# Activate fish
# ------------------------------------------------------------
if [[ "$shell" == "fish" ]]; then
    ensure_fish_ready || exit 1
    selected_shell_path="$(resolve_shell_path fish)" || {
        log_error "Could not resolve fish path after install"
        exit 1
    }
    selected_shell_path="$(canonical_shell_path "$selected_shell_path")"

    deploy_shell_configs fish
    verify_shell_startup fish "$selected_shell_path"
fi

# ------------------------------------------------------------
# Cancel
# ------------------------------------------------------------
if [[ "$shell" == "CANCEL" ]]; then
    echo "Shell change canceled."
    exit 0
fi

if [[ -z "$selected_shell_path" ]]; then
    log_error "Setup failed for '$shell' — login shell was not changed"
    log_status "Try again in a fresh terminal: bash ~/.hyprgruv/lib/scripts/shell.sh"
    exit 1
fi

# ------------------------------------------------------------
# Change login shell last (after gum + plugin setup; needs a sane TTY)
# ------------------------------------------------------------
echo ""
log_status "Applying login shell change…"
set_login_shell "$selected_shell_path" || exit 1

gum spin --spinner dot --title "Shell changed. Reboot or log out/in to apply." -- sleep 2
exit 0