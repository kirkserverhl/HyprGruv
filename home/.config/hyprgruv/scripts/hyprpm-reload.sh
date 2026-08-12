#!/usr/bin/env bash
# hyprpm-reload.sh — load hyprpm plugins once Hyprland's socket is ready.
#
# Called on session start only (autostart.lua). Do NOT hook this on every
# config.reloaded — plugin unload reloads config and used to loop forever.
#
# Flow:
#   1. Wait for Hyprland socket + HYPRLAND_INSTANCE_SIGNATURE
#   2. Bootstrap plugin repos if the .so cache is empty
#   3. hyprpm reload
#   4. If reload fails (outdated headers / ABI / missing plugins) → hyprpm update → reload
#   5. Re-apply bar mode / hyprbars so title bars work after late plugin load
set -euo pipefail

USER_NAME="${USER:-$(id -un)}"
HOME="${HOME:-$(getent passwd "$USER_NAME" | cut -d: -f6)}"
export HOME
XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_RUNTIME_DIR
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

STATE_DIR="$XDG_STATE_HOME/hyprgruv"
LOG_FILE="$STATE_DIR/hyprpm-reload.log"
GUARD_FILE="$XDG_STATE_HOME/waybar/bar_mode_guard"
CACHE_ROOT="/var/cache/hyprpm/${USER_NAME}"
# Cache dir = [repository].name from https://github.com/kirkserverhl/hyprplug
HYPRBARS_SO="$CACHE_ROOT/hyprplug/hyprbars.so"
HYMISSION_SO="$CACHE_ROOT/hymission/hymission.so"
HYPRPM_BOOTSTRAP="${HOME}/.hyprgruv/lib/scripts/hyprpm.sh"
SCRIPTS="${HOME}/.config/hyprgruv/scripts"
ASKPASS="$SCRIPTS/sudo-askpass-zenity.sh"

mkdir -p "$STATE_DIR"
# Rotate log if huge
if [[ -f "$LOG_FILE" ]] && [[ "$(wc -c <"$LOG_FILE" 2>/dev/null || echo 0)" -gt 200000 ]]; then
    mv -f "$LOG_FILE" "${LOG_FILE}.old" 2>/dev/null || true
fi

log() {
    printf '%s %s\n' "$(date -Iseconds)" "$*" >>"$LOG_FILE"
}

notify() {
    local msg=$1
    local timeout=${2:-4000}
    # icon: 0 info, 1 warning, 2 error (hyprctl notify)
    local icon=${3:-1}
    hyprctl notify "$icon" "$timeout" 0 "fontsize:13,${msg}" >/dev/null 2>&1 || true
}

if [[ -f "$GUARD_FILE" ]]; then
    log "skip: bar_mode_guard present"
    exit 0
fi

if ! command -v hyprpm >/dev/null 2>&1; then
    log "skip: hyprpm not in PATH"
    exit 0
fi

# ── env: hyprpm requires HYPRLAND_INSTANCE_SIGNATURE (hyprctl alone is not enough) ──
ensure_hyprland_env() {
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        return 0
    fi
    local dir newest="" newest_t=0 t
    shopt -s nullglob
    for dir in "$XDG_RUNTIME_DIR"/hypr/*/; do
        [[ -S "${dir}.socket.sock" ]] || continue
        t=$(stat -c %Y "$dir" 2>/dev/null || echo 0)
        if (( t >= newest_t )); then
            newest_t=$t
            newest=$dir
        fi
    done
    shopt -u nullglob
    if [[ -n "$newest" ]]; then
        export HYPRLAND_INSTANCE_SIGNATURE
        HYPRLAND_INSTANCE_SIGNATURE="$(basename "$newest")"
        log "discovered HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE"
        return 0
    fi
    return 1
}

wait_for_hyprland() {
    local i
    for i in $(seq 1 100); do
        if ensure_hyprland_env && hyprctl version >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done
    return 1
}

plugins_loaded() {
    local list
    list="$(hyprctl plugin list 2>/dev/null || true)"
    # hymission is always desired when built. hyprbars is bar-mode-dependent
    # (waybar/off unload it after reload) — do not require it here.
    if [[ -f "$HYMISSION_SO" ]] && ! grep -q 'Plugin hymission' <<<"$list"; then
        return 1
    fi
    # hyprbars-only installs: success if hyprbars loaded when hymission absent
    if [[ -f "$HYPRBARS_SO" ]] && [[ ! -f "$HYMISSION_SO" ]]; then
        grep -q 'Plugin hyprbars' <<<"$list" || return 1
    fi
    # If neither .so exists yet, treat as not loaded
    if [[ ! -f "$HYPRBARS_SO" && ! -f "$HYMISSION_SO" ]]; then
        return 1
    fi
    return 0
}

needs_rebuild() {
    local text=$1
    grep -qiE \
        'outdated headers|headers (corrupted|missing|version mismatch)|ABI is mismatched|Please run hyprpm update|Failed to load plugins|headers are not up-to-date' \
        <<<"$text"
}

run_reload() {
    local out rc=0
    log "hyprpm reload…"
    # Capture output; hyprpm still sends error notifications itself
    set +e
    out="$(hyprpm reload -v 2>&1)"
    rc=$?
    set -e
    printf '%s\n' "$out" >>"$LOG_FILE"
    if plugins_loaded; then
        log "reload ok (plugins present)"
        return 0
    fi
    if needs_rebuild "$out"; then
        log "reload indicates rebuild needed (rc=$rc)"
        return 2
    fi
    if (( rc != 0 )); then
        log "reload failed rc=$rc"
        return 1
    fi
    log "reload returned 0 but plugins not listed yet"
    return 1
}

setup_sudo_askpass() {
    # hyprpm update needs sudo for installheaders / installing .so as root.
    # At graphical login there is no TTY — use zenity if available.
    if [[ ! -t 0 ]] && [[ -x "$ASKPASS" ]] && command -v zenity >/dev/null 2>&1; then
        export SUDO_ASKPASS="$ASKPASS"
        export SUDO_ASKPASS_TITLE="Hyprland plugin update (hyprpm)"
        # sudo 1.9+: force askpass even if a controlling tty exists in weird cases
        export SUDO_ASKPASS_REQUIRE="${SUDO_ASKPASS_REQUIRE:-force}"
        log "using SUDO_ASKPASS=$SUDO_ASKPASS"
    fi
}

run_update() {
    local out rc=0
    log "hyprpm update (rebuild plugins for this Hyprland)…"
    notify "Rebuilding Hyprland plugins…" 6000 1
    setup_sudo_askpass
    set +e
    out="$(hyprpm update 2>&1)"
    rc=$?
    set -e
    printf '%s\n' "$out" >>"$LOG_FILE"
    if (( rc == 0 )); then
        log "update ok"
        return 0
    fi
    log "update failed rc=$rc"
    if grep -qiE 'superuser|password|sudo' <<<"$out"; then
        notify "hyprpm update needs sudo — run: hyprpm update" 8000 2
    fi
    return 1
}

reapply_plugin_ui() {
    # Plugins often load after the first config pass. hyprpm reload always loads
    # enabled plugins (including hyprbars) — that races with autostart's early
    # waybar launch and used to leave BOTH bars visible.
    #
    # Safe to call apply-bar-mode here: hyprpm only runs on hyprland.start (not
    # config.reloaded), so unload → config reload cannot re-trigger this script.
    # apply-bar-mode is exclusive: waybar | hyprbars | off — never both.
    if hyprctl plugin list 2>/dev/null | grep -q 'Plugin hymission'; then
        log "reapply hymission config"
        hyprctl eval 'if type(reapply_hymission) == "function" then reapply_hymission() end' \
            >/dev/null 2>&1 || true
    else
        log "hymission not in plugin list after reload"
    fi

    if [[ -x "$SCRIPTS/apply-bar-mode.sh" ]]; then
        local mode
        mode=$(tr -d '[:space:]' <"${XDG_STATE_HOME}/waybar/bar_mode" 2>/dev/null || true)
        [[ -n "$mode" ]] || mode="waybar"
        log "enforce saved bar mode (${mode})"
        NOTIFY=: bash "$SCRIPTS/apply-bar-mode.sh" >>"$LOG_FILE" 2>&1 || true
    else
        log "apply-bar-mode.sh missing — cannot enforce exclusive bar mode"
    fi
}

# ── main ──────────────────────────────────────────────────────────────────────
log "=== hyprpm-reload start ==="

if ! wait_for_hyprland; then
    log "timeout waiting for Hyprland socket / HYPRLAND_INSTANCE_SIGNATURE"
    notify "hyprpm: Hyprland not ready — plugins not loaded" 6000 2
    exit 0
fi
log "Hyprland ready (sig=${HYPRLAND_INSTANCE_SIGNATURE})"

# First login after install: fetch/build if cache empty.
# Bootstrap needs sudo for headers; set askpass first (no TTY at graphical login).
if [[ ! -f "$HYPRBARS_SO" && -x "$HYPRPM_BOOTSTRAP" ]]; then
    log "missing hyprbars.so — running bootstrap"
    setup_sudo_askpass
    # Live stdio when possible so hyprpm progress UI does not deadlock on pipes.
    # Still tee to the log. HYPRPM_QUIET only suppresses banners, not hyprpm itself.
    if [[ -t 1 ]]; then
        HYPRPM_QUIET=1 bash "$HYPRPM_BOOTSTRAP" --quiet 2>&1 | tee -a "$LOG_FILE" || true
    else
        # No TTY: bootstrap will use SUDO_ASKPASS; hyprpm output goes to log only.
        HYPRPM_QUIET=1 bash "$HYPRPM_BOOTSTRAP" --quiet >>"$LOG_FILE" 2>&1 || true
    fi
fi

if run_reload; then
    reapply_plugin_ui
    log "=== done (reload) ==="
    exit 0
fi
reload_rc=$?

# Rebuild when headers/ABI mismatch or plugins simply did not load
if (( reload_rc == 2 )) || ! plugins_loaded; then
    if run_update; then
        if run_reload; then
            reapply_plugin_ui
            notify "Hyprland plugins loaded" 3000 1
            log "=== done (update+reload) ==="
            exit 0
        fi
    fi
fi

log "=== FAILED — plugins not loaded ==="
if ! plugins_loaded; then
    notify "hyprpm failed — see ~/.local/state/hyprgruv/hyprpm-reload.log" 8000 2
fi
exit 0
