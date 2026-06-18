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

ensure_hyprpm() {
    if command -v hyprpm >/dev/null 2>&1; then
        return 0
    fi
    log_error "hyprpm not found — install hyprland first (00-preflight / 01-packages)"
    return 1
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

add_repo() {
    local url="$1"
    log_status "Adding repository: $url"
    hyprpm add "$url" 2>/dev/null || true
}

enable_plugin() {
    local name="$1"
    log_status "Enabling plugin: $name"
    hyprpm enable "$name" 2>/dev/null || true
}

build_plugins() {
    log_status "Building hyprpm plugins (hyprpm update)…"
    if command -v lsd-print >/dev/null 2>&1; then
        hyprpm update | lsd-print
    else
        hyprpm update
    fi
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

main() {
    if ! hyprpm_quiet "${1:-}"; then
        display_header "Hyprpm Plugins"
    fi

    ensure_hyprpm
    ensure_build_deps

    add_repo "$HYPRLAND_PLUGINS_REPO"
    sleep 0.2
    add_repo "$HYMISSION_REPO"
    sleep 0.2

    local plugin
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        enable_plugin "$plugin"
        sleep 0.1
    done

    build_plugins

    if verify_plugins; then
        log_error "Plugin build verification failed — check hyprpm output above"
        return 1
    fi

    log_success "Hyprpm plugins configured (reload on first Hyprland login)"
}

main "$@"