#!/usr/bin/env bash
# ssh_key.sh — SSH key + GitHub login helper (install wizard + Settings menu)
#
# - Creates ~/.ssh/id4me (ed25519) if missing
# - Ensures OpenSSH user agent (not gpg-agent ssh socket)
# - Writes Host github.com IdentityFile in ~/.ssh/config
# - Trusts github.com host keys
# - Loads key, copies pubkey, opens GitHub SSH settings, tests auth
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
gum_apply_matugen_theme 2>/dev/null || true

display_header "SSH / GitHub Login"

SSH_DIR="$HOME/.ssh"
SSH_KEY="$SSH_DIR/id4me"
SSH_CONFIG="$SSH_DIR/config"
KNOWN_HOSTS="$SSH_DIR/known_hosts"
GITHUB_KEYS_URL="https://github.com/settings/ssh/new"
REPO_SSH="git@github.com:kirkserverhl/hyprgruv.git"
REPO_HTTPS="https://github.com/kirkserverhl/hyprgruv.git"
OPENSSH_SOCK="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/ssh-agent.socket"

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

copy_pubkey() {
    if [[ ! -f "${SSH_KEY}.pub" ]]; then
        log_warning "No public key at ${SSH_KEY}.pub"
        return 1
    fi
    if command -v wl-copy >/dev/null 2>&1 && wl-copy <"${SSH_KEY}.pub" 2>/dev/null; then
        log_success "Public key copied to clipboard"
        return 0
    fi
    if command -v xclip >/dev/null 2>&1 && xclip -selection clipboard <"${SSH_KEY}.pub" 2>/dev/null; then
        log_success "Public key copied to clipboard (xclip)"
        return 0
    fi
    log_warning "Clipboard tool not found — copy manually:"
    cat "${SSH_KEY}.pub"
    return 1
}

open_url() {
    local url="$1"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
    elif command -v firefox >/dev/null 2>&1; then
        firefox "$url" &
    elif command -v brave >/dev/null 2>&1; then
        brave "$url" &
    else
        log_status "Open in your browser: $url"
    fi
}

# Prefer systemd OpenSSH agent so fish/gpg do not break ssh-add.
ensure_openssh_agent() {
    if systemctl --user enable --now ssh-agent.socket >/dev/null 2>&1; then
        :
    fi
    if [[ -S "$OPENSSH_SOCK" ]]; then
        export SSH_AUTH_SOCK="$OPENSSH_SOCK"
        unset SSH_AGENT_PID 2>/dev/null || true
        log_status "Using OpenSSH agent: $SSH_AUTH_SOCK"
        return 0
    fi
    # Last resort: ephemeral agent for this terminal only
    log_warning "ssh-agent.socket not ready — starting temporary agent for this session"
    # shellcheck disable=SC2046
    eval "$(ssh-agent -s)" >/dev/null
    return 0
}

ensure_github_known_hosts() {
    touch "$KNOWN_HOSTS"
    chmod 644 "$KNOWN_HOSTS"
    if grep -qE '^github\.com[[:space:]]' "$KNOWN_HOSTS" 2>/dev/null; then
        return 0
    fi
    log_status "Adding github.com host keys to known_hosts…"
    if ssh-keyscan -t ed25519,rsa github.com >>"$KNOWN_HOSTS" 2>/dev/null; then
        log_success "github.com host keys trusted"
    else
        log_warning "ssh-keyscan failed — first GitHub connect may prompt to trust host key"
    fi
}

ensure_github_ssh_config() {
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    if grep -qE '^Host[[:space:]]+github\.com[[:space:]]*$' "$SSH_CONFIG" 2>/dev/null \
        || grep -qE '^Host[[:space:]]+github\.com[[:space:]]' "$SSH_CONFIG" 2>/dev/null; then
        # Ensure IdentityFile points at id4me when present
        if [[ -f "$SSH_KEY" ]] && ! grep -q "IdentityFile.*id4me" "$SSH_CONFIG" 2>/dev/null; then
            log_status "Updating GitHub IdentityFile → $SSH_KEY"
            # Append a dedicated block rather than rewriting unknown config
            {
                echo ""
                echo "# HyprGruv — GitHub (id4me)"
                echo "Host github.com"
                echo "  HostName github.com"
                echo "  User git"
                echo "  IdentityFile $SSH_KEY"
                echo "  IdentitiesOnly yes"
            } >>"$SSH_CONFIG"
        fi
        return 0
    fi
    log_status "Writing GitHub block to ~/.ssh/config"
    {
        echo ""
        echo "# HyprGruv — GitHub SSH"
        echo "Host github.com"
        echo "  HostName github.com"
        echo "  User git"
        echo "  IdentityFile $SSH_KEY"
        echo "  IdentitiesOnly yes"
    } >>"$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
    log_success "Configured Host github.com → IdentityFile $SSH_KEY"
}

load_key_into_agent() {
    [[ -f "$SSH_KEY" ]] || return 1
    ensure_openssh_agent
    if ssh-add -l 2>/dev/null | grep -qF "$SSH_KEY"; then
        log_status "Key already loaded in agent"
        return 0
    fi
    # Match by fingerprint if path form differs
    local fp
    fp="$(ssh-keygen -lf "$SSH_KEY" 2>/dev/null | awk '{print $2}')"
    if [[ -n "$fp" ]] && ssh-add -l 2>/dev/null | grep -qF "$fp"; then
        log_status "Key already loaded in agent"
        return 0
    fi
    if ssh-add "$SSH_KEY" 2>/dev/null; then
        log_success "Loaded key into ssh-agent"
        return 0
    fi
    log_error "ssh-add failed (agent refused?). Try a new terminal after HyprGruv fish config update."
    log_status "Manual:  export SSH_AUTH_SOCK=\$XDG_RUNTIME_DIR/ssh-agent.socket && ssh-add $SSH_KEY"
    return 1
}

test_github_auth() {
    ensure_openssh_agent
    log_status "Testing GitHub SSH (ssh -T git@github.com)…"
    local out
    set +e
    out="$(ssh -o BatchMode=yes -o ConnectTimeout=12 -T git@github.com 2>&1)"
    local rc=$?
    set -e
    # GitHub returns 1 on success with the "Hi user!" message
    if grep -qiE 'successfully authenticated|Hi[[:space:]]+[A-Za-z0-9_-]+!' <<<"$out"; then
        log_success "GitHub SSH works: $(grep -oE 'Hi [^!]+!' <<<"$out" | head -1 || echo authenticated)"
        return 0
    fi
    echo "$out" | sed 's/^/  | /'
    if [[ "$rc" -eq 255 ]]; then
        log_warning "Could not reach GitHub over SSH (network / host key / no key on account yet)"
    else
        log_warning "GitHub did not accept this key yet — add the public key at $GITHUB_KEYS_URL"
    fi
    return 1
}

maybe_switch_hyprgruv_remote() {
    local repo="${HYPR_DIR}"
    [[ -d "$repo/.git" ]] || return 0
    local url
    url="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
    [[ -n "$url" ]] || return 0
    if [[ "$url" == git@github.com:* || "$url" == ssh://git@github.com/* ]]; then
        log_status "hyprgruv origin already SSH: $url"
        return 0
    fi
    if [[ "$url" == https://github.com/* || "$url" == http://github.com/* ]]; then
        if gum confirm "Switch hyprgruv origin from HTTPS → SSH?"; then
            git -C "$repo" remote set-url origin "$REPO_SSH"
            log_success "origin → $REPO_SSH"
        fi
    fi
}

# ── main flow ──────────────────────────────────────────────────────────────
echo ""
echo "Set up SSH for GitHub (clone / push hyprgruv and other repos)."
echo "Default key: $SSH_KEY"
echo ""

ensure_openssh_agent
ensure_github_known_hosts

if [[ -f "${SSH_KEY}.pub" ]]; then
    log_status "Existing key found: ${SSH_KEY}.pub"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
elif compgen -G "$SSH_DIR/id_*.pub" >/dev/null 2>&1; then
    log_status "Other SSH public keys found in $SSH_DIR (not id4me)"
    ls -1 "$SSH_DIR"/id_*.pub 2>/dev/null || true
    if gum confirm "Create HyprGruv key at $SSH_KEY anyway?"; then
        ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$SSH_KEY" -N ""
        log_success "SSH key created"
        cat "${SSH_KEY}.pub"
        echo ""
    fi
else
    log_status "Generating new ed25519 key (no passphrase)…"
    ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)" -f "$SSH_KEY" -N ""
    log_success "SSH key created"
    echo ""
    cat "${SSH_KEY}.pub"
    echo ""
fi

ensure_github_ssh_config
load_key_into_agent || true

if [[ -f "${SSH_KEY}.pub" ]]; then
    if gum confirm "Copy public key to clipboard?"; then
        copy_pubkey || true
    fi
fi

echo ""
echo "Add this key on GitHub: $GITHUB_KEYS_URL"
echo "Repo (SSH): $REPO_SSH"
echo ""

if gum confirm "Open GitHub SSH key settings in browser?"; then
    open_url "$GITHUB_KEYS_URL"
    echo "After pasting the key on GitHub, press Enter here to test…"
    read -r _
fi

if gum confirm "Test GitHub SSH authentication now?"; then
    if ! test_github_auth; then
        if gum confirm "Open GitHub SSH settings again?"; then
            open_url "$GITHUB_KEYS_URL"
        fi
    fi
fi

maybe_switch_hyprgruv_remote

if gum confirm "Open hyprgruv repository page?"; then
    open_url "$REPO_HTTPS"
fi

echo ""
log_success "SSH / GitHub setup step complete"
echo "New terminals use OpenSSH agent via fish config (SSH_AUTH_SOCK)."
echo "This session: export SSH_AUTH_SOCK=\$XDG_RUNTIME_DIR/ssh-agent.socket"
echo ""
