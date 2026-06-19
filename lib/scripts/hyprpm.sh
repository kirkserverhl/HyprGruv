#!/usr/bin/env bash
# hyprpm.sh — bootstrap Hyprland plugins for HyprGruv (03-setup / manual re-run)
#
# Fetches plugin repos, enables hyprbars + hymission, builds via hyprpm update.
# Does NOT call hyprpm reload — Hyprland is usually not running during install.
# Session reload: ~/.config/hyprgruv/scripts/hyprpm-reload.sh (autostart.lua)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

HYPRLAND_PLUGINS_REPO="https://github.com/hyprwm/hyprland-plugins"
HYMISSION_REPO="https://github.com/gfhdhytghd/hymission"
ENABLED_PLUGINS=(hyprbars hymission)

hyprpm_quiet() {
    [[ "${HYPRPM_QUIET:-0}" == "1" || "${1:-}" == "--quiet" ]]
}

# hyprpm needs a live Hyprland socket for version/hash and state writes.
hyprland_session_ready() {
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl version >/dev/null 2>&1
}

ensure_hyprpm() {
    ensure_hyprpm_cmd
}

ensure_build_deps() {
    local pkgs=()
    local p
    for p in hyprland-protocols cmake; do
        pacman -Qq "$p" &>/dev/null || pkgs+=("$p")
    done
    if ((${#pkgs[@]})); then
        log_status "Installing hyprpm build dependencies: ${pkgs[*]}"
        sudo pacman -S --needed --noconfirm "${pkgs[@]}"
    fi
}

ensure_hyprpm_cache_owned() {
    local cache_root="/var/cache/hyprpm/${USER}"
    if [[ -d "$cache_root" ]] && [[ ! -w "$cache_root" ]]; then
        log_status "Fixing hyprpm cache ownership (root-owned cache blocks plugin state writes)"
        sudo chown -R "${USER}:${USER}" "$cache_root"
    fi
    mkdir -p "$cache_root"
}

add_repo() {
    local url="$1"
    log_status "Adding repository: $url"
    if hyprpm add "$url" 2>/dev/null; then
        return 0
    fi
    # Repo may already be registered — confirm it appears in hyprpm list.
    if hyprpm list 2>/dev/null | grep -qF "$url"; then
        log_status "Repository already registered: $url"
        return 0
    fi
    log_error "hyprpm add failed for: $url"
    return 1
}

enable_plugin() {
    local name="$1"
    log_status "Enabling plugin: $name"
    if hyprpm enable "$name"; then
        return 0
    fi
    if hyprpm list 2>/dev/null | grep -qE "(^|[[:space:]])${name}([[:space:]]|$)"; then
        log_status "Plugin already enabled: $name"
        return 0
    fi
    log_error "Failed to enable plugin: $name"
    return 1
}

build_plugins() {
    log_status "Building hyprpm plugins (hyprpm update)…"
    local output
    if output=$(hyprpm update 2>&1); then
        if command -v lsd-print >/dev/null 2>&1; then
            echo "$output" | lsd-print
        else
            echo "$output"
        fi
        return 0
    fi
    log_error "hyprpm update failed"
    echo "$output" | tail -20 | sed 's/^/    | /'
    return 1
}

verify_plugins() {
    local cache_root="/var/cache/hyprpm/${USER}"
    local ok=0

    if [[ ! -f "$cache_root/hyprland-plugins/hyprbars.so" ]]; then
        log_warning "hyprbars.so not found under $cache_root/hyprland-plugins/"
        ok=1
    fi
    if [[ ! -f "$cache_root/hymission/hymission.so" ]]; then
        log_warning "hymission.so not found under $cache_root/hymission/"
        ok=1
    fi

    return "$ok"
}

defer_to_first_login() {
    if ! hyprpm_quiet "${1:-}"; then
        log_warning "Hyprland is not running — cannot build hyprpm plugins during install."
        log_status "Plugins (hyprbars, hymission) will be built on first Hyprland login (hyprpm-reload.sh)."
    fi
    return 0
}

main() {
    if ! hyprpm_quiet "${1:-}"; then
        display_header "Hyprpm Plugins"
    fi

    ensure_hyprpm
    ensure_hyprpm_cache_owned

    if ! hyprland_session_ready; then
        if verify_plugins; then
            if ! hyprpm_quiet "${1:-}"; then
                log_success "Hyprpm plugins already built (will load on Hyprland login)"
            fi
            return 0
        fi
        defer_to_first_login "${1:-}"
        return 0
    fi

    ensure_build_deps

    add_repo "$HYPRLAND_PLUGINS_REPO" || return 1
    sleep 0.2
    add_repo "$HYMISSION_REPO" || return 1
    sleep 0.2

    local plugin
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        enable_plugin "$plugin" || return 1
        sleep 0.1
    done

    if ! build_plugins; then
        log_warning "Plugin build failed during install — deferring to first Hyprland login (hyprpm-reload.sh)"
        return 0
    fi

    if ! verify_plugins; then
        log_warning "Plugin binaries missing after build — deferring to first Hyprland login (hyprpm-reload.sh)"
        return 0
    fi

    log_success "Hyprpm plugins configured (reload on first Hyprland login)"
}

main "$@"