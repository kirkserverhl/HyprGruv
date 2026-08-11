#!/usr/bin/env bash
# Shared helpers for Waybar ↔ Hyprbars ↔ off cycling.
#
# Hyprbars path: HyprGruv builds from kirkserverhl/hyprplug →
#   /var/cache/hyprpm/$USER/hyprplug/hyprbars.so
# Upstream/default hyprland-plugins layout is a fallback only.
# Wrong path → unload/load no-ops → cycle shows both bars or stuck hyprbars.

STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/waybar"
BAR_MODE_FILE="${BAR_MODE_FILE:-$STATE_DIR/bar_mode}"
CACHE_ROOT="/var/cache/hyprpm/${USER:-$(id -un)}"

# Resolve hyprbars.so once (override with HYPRBARS=... if needed).
resolve_hyprbars_so() {
    local candidate
    if [[ -n "${HYPRBARS:-}" && -f "$HYPRBARS" ]]; then
        printf '%s\n' "$HYPRBARS"
        return 0
    fi
    for candidate in \
        "$CACHE_ROOT/hyprplug/hyprbars.so" \
        "$CACHE_ROOT/hyprland-plugins/hyprbars.so" \
        "$CACHE_ROOT/hyprbars/hyprbars.so"
    do
        if [[ -f "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    # Last resort: any hyprbars.so under this user's hyprpm cache
    while IFS= read -r candidate; do
        [[ -n "$candidate" && -f "$candidate" ]] || continue
        printf '%s\n' "$candidate"
        return 0
    done < <(find "$CACHE_ROOT" -maxdepth 3 -type f -name 'hyprbars.so' 2>/dev/null)
    return 1
}

HYPRBARS="$(resolve_hyprbars_so 2>/dev/null || true)"

hyprbars_loaded() {
    hyprctl plugin list 2>/dev/null | grep -q "Plugin hyprbars"
}

# All known .so paths to try on unload (plugin was loaded with one of these).
hyprbars_so_candidates() {
    local c seen=""
    for c in \
        "$HYPRBARS" \
        "$CACHE_ROOT/hyprplug/hyprbars.so" \
        "$CACHE_ROOT/hyprland-plugins/hyprbars.so" \
        "$CACHE_ROOT/hyprbars/hyprbars.so"
    do
        [[ -n "$c" && -f "$c" ]] || continue
        [[ " $seen " == *" $c "* ]] && continue
        printf '%s\n' "$c"
        seen+=" $c"
    done
}

_waybar_pids() {
    local f comm pid
    for f in /proc/[0-9]*/comm; do
        [[ -r "$f" ]] || continue
        comm=$(<"$f")
        [[ "$comm" == "waybar" ]] || continue
        pid=$(basename "$(dirname "$f")")
        printf '%s\n' "$pid"
    done
}

waybar_running() {
    local f
    for f in /proc/[0-9]*/comm; do
        [[ -r "$f" && "$(<"$f")" == "waybar" ]] && return 0
    done
    return 1
}

waybar_layer_visible() {
    hyprctl layers 2>/dev/null | grep -q 'namespace: waybar'
}

waybar_d_state() {
    local f status state
    for f in /proc/[0-9]*/status; do
        [[ -r "$f" ]] || continue
        grep -q '^Name:[[:space:]]*waybar$' "$f" || continue
        state=$(awk '/^State:/{print $2}' "$f")
        [[ "$state" == "D" ]] && return 0
    done
    return 1
}

hide_waybar() {
    local pid
    while read -r pid; do
        [[ -n "$pid" ]] || continue
        kill -USR1 "$pid" 2>/dev/null || true
    done < <(_waybar_pids)
}

stop_waybar() {
    local i pid log_pids="" hidden_ok=0

    # Fast path — this is what worked before the /proc refactor.
    killall -9 waybar 2>/dev/null || true
    while read -r pid; do
        [[ -n "$pid" ]] || continue
        kill -9 "$pid" 2>/dev/null || true
    done < <(_waybar_pids)

    for i in $(seq 1 12); do
        waybar_running || return 0
        sleep 0.05
        killall -9 waybar 2>/dev/null || true
    done

    # Kill failed — hide via Waybar's native SIGUSR1 (show/hide toggle).
    hide_waybar
    sleep 0.1
    if ! waybar_layer_visible; then
        return 0
    fi

    # Still visible: stuck D-state processes cannot receive signals until I/O completes.
    if waybar_d_state; then
        while read -r pid; do
            [[ -n "$pid" ]] && log_pids+="$pid "
        done < <(_waybar_pids)
        echo "$(date -Iseconds) stop_waybar: waybar stuck in disk sleep (unkillable) pids:${log_pids}" >>"${STATE_DIR}/toggle.log"
        return 1
    fi

    while read -r pid; do
        [[ -n "$pid" ]] && log_pids+="$pid "
    done < <(_waybar_pids)
    echo "$(date -Iseconds) stop_waybar failed — pids:${log_pids:-none}" >>"${STATE_DIR}/toggle.log"
    return 1
}

unload_hyprbars() {
    local so attempt
    hyprbars_loaded || return 0
    hyprctl eval 'if type(reset_hyprbars_buttons) == "function" then reset_hyprbars_buttons() end' \
        >/dev/null 2>&1 || true

    for attempt in 1 2; do
        hyprbars_loaded || return 0
        while IFS= read -r so; do
            [[ -n "$so" ]] || continue
            hyprctl plugin unload "$so" >/dev/null 2>&1 || true
        done < <(hyprbars_so_candidates)
        sleep 0.2
    done

    if hyprbars_loaded; then
        echo "unload_hyprbars: plugin still loaded after unload attempts" >&2
        return 1
    fi
    return 0
}

load_hyprbars() {
    local so
    hyprctl eval 'if type(reset_hyprbars_buttons) == "function" then reset_hyprbars_buttons() end' \
        >/dev/null 2>&1 || true

    # Drop any already-loaded instance so buttons re-register cleanly
    if hyprbars_loaded; then
        unload_hyprbars || true
        sleep 0.15
    fi

    so="$(resolve_hyprbars_so 2>/dev/null || true)"
    if [[ -z "$so" || ! -f "$so" ]]; then
        echo "hyprbars plugin not found under $CACHE_ROOT (expected hyprplug/hyprbars.so)" >&2
        return 1
    fi
    HYPRBARS="$so"

    if ! hyprctl plugin load "$HYPRBARS" >/dev/null 2>&1; then
        echo "hyprctl plugin load failed: $HYPRBARS" >&2
        return 1
    fi
    sleep 0.15
    if ! hyprbars_loaded; then
        echo "hyprbars failed to appear in plugin list after load" >&2
        return 1
    fi
    hyprctl eval 'if type(reapply_hyprbars) == "function" then reapply_hyprbars() end' \
        >/dev/null 2>&1 || true
}

start_waybar() {
    if waybar_mode_blocks_launch; then
        return 0
    fi
    unload_hyprbars
    sleep 0.1
    "$HOME/.config/waybar/scripts/launch.sh"
}

read_bar_mode() {
    local mode="waybar"
    if [[ -f "$BAR_MODE_FILE" ]]; then
        mode=$(tr -d '[:space:]' <"$BAR_MODE_FILE")
    fi
    case "$mode" in
        waybar | hyprbars | off) printf '%s\n' "$mode" ;;
        *) printf '%s\n' "waybar" ;;
    esac
}

waybar_mode_blocks_launch() {
    local mode
    mode=$(read_bar_mode)
    [[ "$mode" == "hyprbars" || "$mode" == "off" ]]
}

next_bar_mode() {
    case "$(read_bar_mode)" in
        waybar) printf '%s\n' "hyprbars" ;;
        hyprbars) printf '%s\n' "off" ;;
        off | *) printf '%s\n' "waybar" ;;
    esac
}

apply_bar_mode() {
    local mode="$1"
    local notify="${NOTIFY:-notify-send}"
    local label
    local prev

    mkdir -p "$STATE_DIR"
    prev="$(read_bar_mode)"

    case "$mode" in
        waybar)
            # Persist first so start_waybar / launch.sh see the intended mode
            echo "waybar" >"$BAR_MODE_FILE"
            unload_hyprbars || true
            stop_waybar || true
            start_waybar
            if hyprbars_loaded; then
                [[ "$notify" == ":" ]] || $notify "Bar" "Waybar on, but hyprbars still loaded" -u critical -t 4000
            fi
            label="Waybar only"
            ;;
        hyprbars)
            echo "hyprbars" >"$BAR_MODE_FILE"
            if ! stop_waybar; then
                if waybar_d_state; then
                    [[ "$notify" == ":" ]] || $notify "Bar" "Waybar stuck (disk sleep) — log out/in to clear." -u critical -t 6000
                else
                    [[ "$notify" == ":" ]] || $notify "Bar" "Waybar still visible — try: killall -9 waybar" -u critical -t 5000
                fi
            fi
            if ! load_hyprbars; then
                # Roll back mode so Alt+W does not get stuck on a failed state
                echo "$prev" >"$BAR_MODE_FILE"
                [[ "$notify" == ":" ]] || $notify "Bar" "Hyprbars failed to load — run: hyprpm reload" -u critical -t 5000
                return 1
            fi
            label="Hyprbars only"
            ;;
        off)
            echo "off" >"$BAR_MODE_FILE"
            stop_waybar || true
            if ! unload_hyprbars; then
                [[ "$notify" == ":" ]] || $notify "Bar" "Could not unload hyprbars — check plugin path" -u critical -t 5000
                return 1
            fi
            label="Hidden"
            ;;
        *)
            echo "Unknown bar mode: $mode" >&2
            return 1
            ;;
    esac

    [[ "$notify" == ":" ]] || $notify "Bar" "$label" -t 1500
}