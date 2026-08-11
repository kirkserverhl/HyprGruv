#!/usr/bin/env bash
# oh_my_tmux.sh — install Oh My Tmux (gpakosz/.tmux) for Hyprgruv
#
# Dotfiles expect:
#   ~/.config/tmux/tmux.conf → ~/.local/share/tmux/oh-my-tmux/.tmux.conf
#   ~/.config/tmux/tmux.conf.local  (stowed local overrides)
#
# Without this clone the symlink is broken and stock tmux pane-base-index (0)
# breaks dev-workspace.sh assumptions that oh-my-tmux's base-index 1 would set.
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
command -v gum_apply_matugen_theme >/dev/null 2>&1 && gum_apply_matugen_theme 2>/dev/null || true

OMT_DIR="${HYPRGRUV_OMT_DIR:-$HOME/.local/share/tmux/oh-my-tmux}"
OMT_REPO="${HYPRGRUV_OMT_REPO:-https://github.com/gpakosz/.tmux.git}"
TMUX_CONF_LINK="${XDG_CONFIG_HOME:-$HOME/.config}/tmux/tmux.conf"
TMUX_CONF_TARGET="$OMT_DIR/.tmux.conf"

oh_my_tmux_installed() {
    [[ -f "$TMUX_CONF_TARGET" ]]
}

ensure_tmux_pkg() {
    if command -v tmux >/dev/null 2>&1; then
        return 0
    fi
    log_status "tmux not found — installing…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm tmux || {
            log_error "Failed to install tmux"
            return 1
        }
    else
        sudo pacman -S --needed --noconfirm tmux || {
            log_error "Failed to install tmux"
            return 1
        }
    fi
    hash -r 2>/dev/null || true
    command -v tmux >/dev/null 2>&1 || {
        log_error "tmux installed but not on PATH"
        return 1
    }
}

ensure_tmux_conf_symlink() {
    local link_dir
    link_dir="$(dirname "$TMUX_CONF_LINK")"
    mkdir -p "$link_dir"

    if [[ -L "$TMUX_CONF_LINK" ]]; then
        local current
        current="$(readlink -f "$TMUX_CONF_LINK" 2>/dev/null || true)"
        local expected
        expected="$(readlink -f "$TMUX_CONF_TARGET" 2>/dev/null || true)"
        if [[ -n "$current" && -n "$expected" && "$current" == "$expected" ]]; then
            return 0
        fi
        # Broken or wrong target — replace
        rm -f "$TMUX_CONF_LINK"
    elif [[ -e "$TMUX_CONF_LINK" ]]; then
        log_warning "Leaving existing non-symlink $TMUX_CONF_LINK in place"
        return 0
    fi

    # Prefer relative-stable absolute path matching the stowed layout
    ln -sfn "$TMUX_CONF_TARGET" "$TMUX_CONF_LINK"
    log_status "Linked $TMUX_CONF_LINK → $TMUX_CONF_TARGET"
}

install_oh_my_tmux() {
    ensure_tmux_pkg || return 1

    command -v git >/dev/null 2>&1 || {
        log_error "git is required to install Oh My Tmux"
        return 1
    }

    if oh_my_tmux_installed; then
        log_success "Oh My Tmux already installed at $OMT_DIR"
        # Still refresh if empty/corrupt
        if [[ ! -d "$OMT_DIR/.git" ]]; then
            log_warning "$OMT_DIR exists but is not a git clone — leaving as-is"
        fi
    else
        if [[ -d "$OMT_DIR" && ! -f "$TMUX_CONF_TARGET" ]]; then
            log_warning "Removing incomplete Oh My Tmux dir: $OMT_DIR"
            rm -rf "$OMT_DIR"
        fi

        log_status "Cloning Oh My Tmux → $OMT_DIR …"
        mkdir -p "$(dirname "$OMT_DIR")"
        git clone --depth 1 "$OMT_REPO" "$OMT_DIR" || {
            log_error "git clone failed: $OMT_REPO"
            return 1
        }
        log_success "Oh My Tmux installed"
    fi

    if ! oh_my_tmux_installed; then
        log_error "Oh My Tmux install finished but $TMUX_CONF_TARGET is missing"
        return 1
    fi

    ensure_tmux_conf_symlink

    # Local overrides are stowed by the repo; warn if missing (dev-workspace still works).
    local local_conf="${TMUX_CONF_LINK}.local"
    if [[ ! -f "$local_conf" ]]; then
        log_warning "Missing $local_conf (expected after stow). Oh My Tmux will run with defaults."
    fi

    log_success "Oh My Tmux ready (pane-base-index 1 when conf is loaded)"
    return 0
}

# Allow sourcing for helpers, or running as a setup script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_oh_my_tmux
fi
