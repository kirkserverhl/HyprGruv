#!/usr/bin/env bash
# hyprpm.sh — bootstrap Hyprland plugins for HyprGruv (03-setup / manual re-run)
#
# Registers hyprplug (hyprbars-only) + hymission, enables both, builds via hyprpm update.
# Does NOT call hyprpm reload — Hyprland is usually not running during install.
# Session reload: ~/.config/hyprgruv/scripts/hyprpm-reload.sh (autostart.lua)
#
# Design notes (avoid multi-update loops from Settings → Setup):
#   - At most ONE full `hyprpm update` on the happy path (build_plugins).
#   - Headers-only repair runs only when add fails with "headers outdated".
#   - Repos already in `hyprpm list` are never re-added (failed re-add used to
#     trigger another full update, looking like a stuck loop).
#   - Early-exit when .so files already exist (FORCE_HYPRPM=1 to rebuild).
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# hyprplug: hyprbars-only (avoids building unused monorepo plugins on every update).
# Prefer vendored tree in this repo (pinned to hyprland-plugins v0.56.0 for HL 0.56.x).
# Remote GitHub is optional fallback — you do NOT need SSH/GitHub push for hyprbars.
HYPRPLUG_SRC="${HYPR_DIR}/plugins/hyprplug"
HYPRPLUG_GIT_WORKDIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/hyprplug-src"
HYPRPLUG_REMOTE_FALLBACK="https://github.com/kirkserverhl/hyprplug"
HYPRPLUG_REPO="" # resolved by resolve_hyprplug_repo()
HYMISSION_REPO="https://github.com/gfhdhytghd/hymission"
ENABLED_PLUGINS=(hyprbars hymission)
# Cache dir name matches [repository].name in hyprplug's hyprpm.toml
HYPRBARS_CACHE_DIR="hyprplug"
HYPRPLUG_NAME="hyprplug"

# Set after any successful full update so we never rebuild twice in one run.
HYPRPM_UPDATE_DONE=0
# Set when we already attempted a headers repair (add-path only; once per run).
HYPRPM_HEADERS_ATTEMPTED=0

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
    [[ -n "${USER:-}" ]] || { log_error "USER is unset — cannot prepare hyprpm cache"; return 1; }
    local cache_root="/var/cache/hyprpm/${USER}"
    # /var/cache/hyprpm is root-owned on fresh installs; hyprpm needs a user-writable tree.
    # hyprpm update also installs .so files as root — re-chown so the user can write state.
    if [[ ! -d "$cache_root" ]]; then
        log_status "Preparing hyprpm cache: $cache_root"
        if ! sudo mkdir -p "$cache_root" || ! sudo chown -R "${USER}:${USER}" "$cache_root"; then
            log_warning "Could not create hyprpm cache (sudo failed)"
            return 1
        fi
        return 0
    fi
    if [[ ! -w "$cache_root" ]] || find "$cache_root" -user root -print -quit 2>/dev/null | grep -q .; then
        log_status "Fixing hyprpm cache ownership: $cache_root"
        if ! sudo chown -R "${USER}:${USER}" "$cache_root"; then
            log_warning "Could not fix hyprpm cache ownership (sudo failed)"
            return 1
        fi
    fi
    return 0
}

# hyprpm update runs `sudo` when installing headers; without a cached credential it
# hangs on a password prompt (especially under non-interactive wrappers).
ensure_sudo_for_hyprpm() {
    if sudo -n true 2>/dev/null; then
        return 0
    fi
    # Graphical/non-TTY (e.g. hyprpm-reload bootstrap): use askpass if configured.
    if [[ ! -t 0 ]] && [[ -n "${SUDO_ASKPASS:-}" ]] && [[ -x "${SUDO_ASKPASS}" ]]; then
        log_status "hyprpm needs sudo — prompting via askpass"
        if sudo -A -v; then
            return 0
        fi
        log_error "sudo askpass authentication failed — cannot build hyprpm headers/plugins"
        return 1
    fi
    if [[ ! -t 0 ]]; then
        log_error "sudo needs a password but no TTY/askpass — cannot build hyprpm plugins"
        return 1
    fi
    log_status "hyprpm needs sudo to install headers — enter your password when prompted"
    if ! sudo -v; then
        log_error "sudo authentication failed — cannot build hyprpm headers/plugins"
        return 1
    fi
    return 0
}

# Public plugin repos need no GitHub login. A broken credential.helper (e.g.
# "manager" without git-credential-manager installed) can make git try to prompt
# for a username — and when stdout is captured that prompt is invisible → hang.
# Force anonymous HTTPS + no terminal credential prompts for hyprpm git ops.
hyprpm_git_env() {
    # Empty helper overrides global credential.helper=manager etc.
    export GIT_CONFIG_COUNT=2
    export GIT_CONFIG_KEY_0="credential.helper"
    export GIT_CONFIG_VALUE_0=""
    export GIT_CONFIG_KEY_1="credential.interactive"
    export GIT_CONFIG_VALUE_1="never"
    export GIT_TERMINAL_PROMPT=0
    export GIT_ASKPASS=echo
    export SSH_ASKPASS=echo
    # Prefer not hanging on auth for public clones
    export GCM_INTERACTIVE=never 2>/dev/null || true
}

# Run hyprpm on a live TTY. Capturing stdout/stderr (cmd substitution) hides
# progress UI and can deadlock TUI code waiting on a pipe.
run_hyprpm() {
    hyprpm_git_env
    # stdbuf if available so progress lines flush
    if command -v stdbuf >/dev/null 2>&1; then
        stdbuf -oL -eL hyprpm "$@"
    else
        hyprpm "$@"
    fi
}

# One full `hyprpm update` (headers + rebuild). Never call twice without reason.
run_hyprpm_update() {
    local reason="${1:-plugins}"
    local force="${2:-0}"
    local -a args=(update)
    local sudo_keepalive_pid rc=0

    if [[ "$force" == "1" ]]; then
        args+=(-f)
    fi

    log_status "hyprpm ${args[*]} ($reason) — may take several minutes…"
    # Keep sudo timestamp alive across long header builds (default 15m can expire).
    ( while true; do sleep 60; sudo -n true 2>/dev/null || exit 0; done ) &
    sudo_keepalive_pid=$!
    hyprpm_git_env
    run_hyprpm "${args[@]}" || rc=$?
    kill "$sudo_keepalive_pid" 2>/dev/null || true
    wait "$sudo_keepalive_pid" 2>/dev/null || true
    ensure_hyprpm_cache_owned || true

    if [[ "$rc" -eq 0 ]]; then
        HYPRPM_UPDATE_DONE=1
        return 0
    fi
    log_warning "hyprpm update exited $rc ($reason)"
    return 1
}

# Headers repair for add failures only. Skips if we already ran a full update.
ensure_hyprpm_headers_once() {
    if [[ "$HYPRPM_UPDATE_DONE" -eq 1 ]]; then
        return 0
    fi
    if [[ "$HYPRPM_HEADERS_ATTEMPTED" -eq 1 ]]; then
        log_status "Headers update already attempted this run — not repeating"
        return 1
    fi
    HYPRPM_HEADERS_ATTEMPTED=1
    run_hyprpm_update "headers (required before add/enable)"
}

# Materialize a local git repo hyprpm can clone (sources live in HYPR_DIR/plugins/hyprplug).
# Avoids depending on GitHub SSH/HTTPS for the hyprbars pin that matches Hyprland 0.56.x.
ensure_local_hyprplug_git() {
    local src="$HYPRPLUG_SRC"
    local dest="$HYPRPLUG_GIT_WORKDIR"
    [[ -f "$src/hyprpm.toml" && -d "$src/hyprbars" ]] || return 1

    mkdir -p "$dest"
    # Copy sources; keep dest as a real git repo for `hyprpm add file://…`
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete --exclude '.git' --exclude '*.so' --exclude 'build/' "$src/" "$dest/"
    else
        find "$dest" -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} + 2>/dev/null || true
        cp -a "$src"/. "$dest"/
        rm -rf "$dest/.git" 2>/dev/null || true
    fi

    if [[ ! -d "$dest/.git" ]]; then
        git -C "$dest" init -b main >/dev/null
        git -C "$dest" config user.email "hyprgruv@local"
        git -C "$dest" config user.name "hyprgruv"
    fi
    git -C "$dest" add -A
    if ! git -C "$dest" diff --cached --quiet 2>/dev/null \
        || ! git -C "$dest" rev-parse HEAD >/dev/null 2>&1; then
        git -C "$dest" commit -m "hyprplug: sync from HyprGruv plugins/hyprplug" --allow-empty >/dev/null \
            || git -C "$dest" commit -m "hyprplug: sync from HyprGruv plugins/hyprplug" >/dev/null
    fi
    return 0
}

resolve_hyprplug_repo() {
    if ensure_local_hyprplug_git; then
        HYPRPLUG_REPO="file://${HYPRPLUG_GIT_WORKDIR}"
        log_status "Using local hyprplug (Hyprland 0.56.x pin): $HYPRPLUG_GIT_WORKDIR"
    else
        HYPRPLUG_REPO="$HYPRPLUG_REMOTE_FALLBACK"
        log_warning "Local plugins/hyprplug missing — falling back to $HYPRPLUG_REPO"
    fi
}

repo_registered() {
    local url_or_name="$1"
    local repo_name
    local list
    list="$(run_hyprpm list 2>/dev/null || true)"
    [[ -z "$list" ]] && return 1
    if grep -qF "$url_or_name" <<<"$list"; then
        return 0
    fi
    repo_name="$(basename "$url_or_name" .git)"
    # file://…/hyprplug-src → still match repository name "hyprplug"
    if [[ "$repo_name" == "hyprplug-src" ]]; then
        repo_name="$HYPRPLUG_NAME"
    fi
    # hyprpm list: "→ Repository hyprplug (by …)"
    grep -qiE "Repository[[:space:]]+${repo_name}([[:space:]]|\\()" <<<"$list"
}

remove_repo_if_present() {
    local name="$1"
    if run_hyprpm list 2>/dev/null | grep -qiE "Repository[[:space:]]+${name}([[:space:]]|\\()"; then
        log_status "Removing hyprpm repo: $name (will re-add from current source)"
        # hyprpm remove always prompts Y/n
        printf 'Y\n' | hyprpm remove "$name" >/dev/null 2>&1 || true
    fi
}

add_repo() {
    local url="$1"
    local rc=0
    local label
    label="$(basename "$url" .git)"
    [[ "$label" == "hyprplug-src" ]] && label="$HYPRPLUG_NAME"

    if repo_registered "$url" || repo_registered "$label"; then
        log_status "Repository already registered: $label"
        return 0
    fi

    log_status "Adding repository: $url"
    # Live output — do NOT capture; hyprpm's progress UI deadlocks on pipes.
    if run_hyprpm add "$url"; then
        return 0
    fi
    rc=$?

    # Race / list lag: may have been registered despite non-zero exit.
    if repo_registered "$url" || repo_registered "$label"; then
        log_status "Repository already registered: $label"
        return 0
    fi

    # Common on first run: headers not built yet.
    log_warning "hyprpm add failed (exit $rc) — updating headers once and retrying…"
    ensure_hyprpm_headers_once || true
    if run_hyprpm add "$url"; then
        return 0
    fi
    if repo_registered "$url" || repo_registered "$label"; then
        log_status "Repository already registered: $label"
        return 0
    fi

    log_error "hyprpm add failed for: $url"
    return 1
}

enable_plugin() {
    local name="$1"
    log_status "Enabling plugin: $name"
    if run_hyprpm enable "$name"; then
        return 0
    fi
    # list shows "enabled: true" or "enabled: Plugin failed to build" etc.
    if run_hyprpm list 2>/dev/null | grep -A2 -E "(^|[[:space:]])${name}([[:space:]]|$)" | grep -qi 'enabled:.*true'; then
        log_status "Plugin already enabled: $name"
        return 0
    fi
    log_error "Failed to enable plugin: $name"
    return 1
}

build_plugins() {
    # Happy path: a single update for the whole script run.
    if [[ "$HYPRPM_UPDATE_DONE" -eq 1 ]]; then
        if verify_plugins; then
            log_status "Plugins already built by earlier hyprpm update — skipping second rebuild"
            return 0
        fi
        # Headers update ran but a plugin still failed (e.g. hyprbars) — force once.
        log_warning "Prior update finished but plugin .so still missing — forcing rebuild once"
        run_hyprpm_update "force rebuild missing plugins" 1 || true
        return 0
    fi

    if ! run_hyprpm_update "build plugins"; then
        log_error "hyprpm update failed"
        return 1
    fi

    if ! verify_plugins; then
        # Some hyprpm versions leave failed=true and skip rebuild without -f.
        log_warning "Plugin .so missing after update — forcing rebuild once"
        run_hyprpm_update "force rebuild missing plugins" 1 || true
    fi
    return 0
}

verify_plugins() {
    local cache_root="/var/cache/hyprpm/${USER}"
    local ok=0

    if [[ ! -f "$cache_root/${HYPRBARS_CACHE_DIR}/hyprbars.so" ]]; then
        log_warning "hyprbars.so not found under $cache_root/${HYPRBARS_CACHE_DIR}/"
        ok=1
    fi
    if [[ ! -f "$cache_root/hymission/hymission.so" ]]; then
        log_warning "hymission.so not found under $cache_root/hymission/"
        ok=1
    fi

    return "$ok"
}

plugins_configured() {
    verify_plugins || return 1
    # Match by repo name (URL may be file:// local or github fallback).
    repo_registered "$HYPRPLUG_NAME" || return 1
    repo_registered "hymission" || return 1
    return 0
}

# True when hyprplug is registered but hyprbars failed / .so missing — need re-add from local pin.
hyprplug_needs_repin() {
    local cache_root="/var/cache/hyprpm/${USER}"
    if [[ -f "$cache_root/${HYPRBARS_CACHE_DIR}/hyprbars.so" ]]; then
        return 1
    fi
    # Missing binary + repo present (often old github tip that won't build on 0.56.2)
    repo_registered "$HYPRPLUG_NAME"
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

    if ! hyprland_session_ready; then
        # Best-effort cache fix (no hard fail without TTY/sudo during pre-graphical install).
        ensure_hyprpm_cache_owned || true
        if verify_plugins; then
            if ! hyprpm_quiet "${1:-}"; then
                log_success "Hyprpm plugins already built (will load on Hyprland login)"
            fi
            return 0
        fi
        defer_to_first_login "${1:-}"
        return 0
    fi

    # Settings → Setup re-runs this often. Skip multi-minute rebuild when healthy.
    # FORCE_HYPRPM=1 bash …/hyprpm.sh  to rebuild anyway.
    if [[ "${FORCE_HYPRPM:-0}" != "1" ]] && plugins_configured; then
        if ! hyprpm_quiet "${1:-}"; then
            log_success "Hyprpm plugins already configured (set FORCE_HYPRPM=1 to rebuild)"
        fi
        return 0
    fi

    ensure_build_deps
    ensure_sudo_for_hyprpm || {
        log_warning "No sudo — deferring hyprpm plugins to first Hyprland login"
        return 0
    }
    # Ensure headersRoot is user-writable before hyprpm tries to install into it.
    ensure_hyprpm_cache_owned || {
        log_warning "hyprpm cache not writable — deferring to first Hyprland login"
        return 0
    }

    # Do NOT run hyprpm update here. One update at the end builds headers + plugins.
    # A pre-update + post-update double-run is what made Settings setup feel stuck.

    resolve_hyprplug_repo

    # Drop official monorepo if present (builds unused plugins every update).
    # hyprpm remove always prompts Y/n — feed yes for non-interactive install.
    if hyprpm list 2>/dev/null | grep -qF 'hyprland-plugins'; then
        log_status "Removing official hyprland-plugins monorepo (replaced by hyprplug)"
        printf 'Y\n' | hyprpm remove hyprland-plugins >/dev/null 2>&1 || true
    fi

    # Old github tip of hyprplug fails on HL 0.56.2 (keybinds/Manager.hpp). Re-pin local.
    if hyprplug_needs_repin; then
        log_status "hyprbars missing/broken — re-pinning hyprplug from local 0.56.x sources"
        remove_repo_if_present "$HYPRPLUG_NAME"
    fi

    # Soft-fail repo/enable errors: first-login hyprpm-reload.sh can finish the job.
    if ! add_repo "$HYPRPLUG_REPO"; then
        log_warning "Could not add hyprplug — deferring plugin setup to first Hyprland login"
        return 0
    fi
    sleep 0.2
    if ! add_repo "$HYMISSION_REPO"; then
        log_warning "Could not add hymission — deferring remaining plugin setup to first login"
        return 0
    fi
    sleep 0.2

    local plugin
    for plugin in "${ENABLED_PLUGINS[@]}"; do
        if ! enable_plugin "$plugin"; then
            log_warning "Could not enable $plugin — will retry on first Hyprland login"
        fi
        sleep 0.1
    done

    # Re-chown after add/enable — hyprpm may have written root-owned state.
    ensure_hyprpm_cache_owned

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
