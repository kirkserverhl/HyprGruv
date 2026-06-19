#!/usr/bin/env bash
# Shared helpers for Waybar ↔ Hyprbars ↔ off cycling.

STATE_DIR="${XDG_STATE_HOME:-${HOME}/.local/state}/waybar"
BAR_MODE_FILE="${BAR_MODE_FILE:-$STATE_DIR/bar_mode}"
HYPRBARS="${HYPRBARS:-/var/cache/hyprpm/${USER}/hyprland-plugins/hyprbars.so}"

hyprbars_loaded() {
    hyprctl plugin list 2>/dev/null | grep -q "Plugin hyprbars"
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
    hyprbars_loaded || return 0
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
    sleep 0.2
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.2
    fi
}

load_hyprbars() {
    hyprctl eval 'reset_hyprbars_buttons()' >/dev/null 2>&1 || true
    if hyprbars_loaded; then
        hyprctl plugin unload "$HYPRBARS" >/dev/null 2>&1 || true
        sleep 0.2
    fi
    if [[ ! -f "$HYPRBARS" ]]; then
        echo "hyprbars plugin not found: $HYPRBARS" >&2
        return 1
    fi
    hyprctl plugin load "$HYPRBARS" >/dev/null 2>&1 || return 1
    sleep 0.15
    hyprctl eval 'reapply_hyprbars()' >/dev/null 2>&1 || true
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

    mkdir -p "$STATE_DIR"

    case "$mode" in
        waybar)
            echo "waybar" >"$BAR_MODE_FILE"
            unload_hyprbars
            stop_waybar || true
            start_waybar
            label="Waybar only"
            ;;
        hyprbars)
            echo "hyprbars" >"$BAR_MODE_FILE"
            if ! stop_waybar; then
                if waybar_d_state; then
                    [[ "$notify" == ":" ]] || $notify "Bar" "Waybar stuck (disk sleep) — log out/in to clear. Hyprbars loaded." -u critical -t 6000
                else
                    [[ "$notify" == ":" ]] || $notify "Bar" "Waybar still visible — try: killall -9 waybar" -u critical -t 5000
                fi
            fi
            if ! load_hyprbars; then
                [[ "$notify" == ":" ]] || $notify "Bar" "Hyprbars failed to load — check hyprpm" -u critical -t 4000
                return 1
            fi
            label="Hyprbars only"
            ;;
        off)
            echo "off" >"$BAR_MODE_FILE"
            stop_waybar || true
            unload_hyprbars
            label="Hidden"
            ;;
        *)
            echo "Unknown bar mode: $mode" >&2
            return 1
            ;;
    esac

    [[ "$notify" == ":" ]] || $notify "Bar" "$label" -t 1500
}