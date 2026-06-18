#!/usr/bin/env bash
# ssh_key.sh — optional SSH key generation + GitHub setup helper
set -euo pipefail
IFS=$'\n\t'

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

ensure_cmd() {
    local c="$1" install_msg="$2" pkg="$3"
    if ! command -v "$c" >/dev/null 2>&1; then
        log_status "$install_msg"
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm "$pkg"
        else
            sudo pacman -S --needed --noconfirm "$pkg"
        fi
    fi
}

ensure_cmd gum "Installing gum…" gum
ensure_cmd ssh-keygen "Installing openssh…" openssh

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
gum_apply_matugen_theme

display_header "SSH Key"

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id4me"
GITHUB_KEYS_URL="https://github.com/settings/ssh/new"
REPO_URL="https://github.com/kirkserverhl/hyprgruv.git"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

copy_pubkey() {
    if [[ ! -f "${SSH_KEY}.pub" ]]; then
        log_warning "No public key at ${SSH_KEY}.pub"
        return 1
    fi
    if wl-copy <"${SSH_KEY}.pub" 2>/dev/null; then
        log_success "Public key copied to clipboard (wl-copy)"
        return 0
    fi
    if xclip -selection clipboard <"${SSH_KEY}.pub" 2>/dev/null; then
        log_success "Public key copied to clipboard (xclip)"
        return 0
    fi
    log_warning "Clipboard tool not found — copy manually:"
    cat "${SSH_KEY}.pub"
    return 1
}

open_url() {
    local url="$1"
    if command -v firefox >/dev/null 2>&1; then
        firefox "$url" &
    elif command -v brave >/dev/null 2>&1; then
        brave "$url" &
    elif command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" &
    else
        log_status "Open in your browser: $url"
    fi
}

echo ""
echo "Set up an SSH key for GitHub (clone/push hyprgruv and other repos)."
echo "Default key path: $SSH_KEY"
sleep 0.5

if [[ -f "${SSH_KEY}.pub" ]] || compgen -G "$SSH_DIR/id_*.pub" >/dev/null 2>&1; then
    log_status "Existing SSH key(s) found in $SSH_DIR"
    if [[ -f "${SSH_KEY}.pub" ]]; then
        echo ""
        cat "${SSH_KEY}.pub"
        echo ""
    fi
    if gum confirm "Copy your SSH public key to the clipboard?"; then
        copy_pubkey || true
    fi
else
    log_status "Generating new ed25519 key…"
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$SSH_KEY" -N ""
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$SSH_KEY" 2>/dev/null || true
    log_success "SSH key created"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
    copy_pubkey || true
fi

echo ""
echo "Add the public key at: $GITHUB_KEYS_URL"
echo "Repo (SSH): git@github.com:kirkserverhl/hyprgruv.git"
sleep 0.5

if gum confirm "Open GitHub SSH key settings in your browser?"; then
    open_url "$GITHUB_KEYS_URL"
fi

if gum confirm "Open the hyprgruv repository page?"; then
    open_url "$REPO_URL"
fi

log_success "SSH key setup step complete"

