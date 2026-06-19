#!/usr/bin/env bash
# Super+R — kill & recreate a dev tmux session, then re-attach in the focused terminal.
set -euo pipefail

DEV_WS="${HOME}/.config/tmux/dev-workspace.sh"
PREFIX="${TMUX_DEV_PREFIX:-dev}"
NOTIFY='hyprctl notify 0 2200 0'

is_dev_session() {
    [[ "$1" == "$PREFIX" || "$1" == "${PREFIX}-"* ]]
}

active_window_pid() {
    hyprctl activewindow -j 2>/dev/null \
        | sed -n 's/.*"pid"[[:space:]]*:[[:space:]]*\([0-9]*\).*/\1/p' \
        | head -n1
}

pid_uses_tty() {
    local pid="$1" tty_name="$2"
    local fd target
    [[ -n "$pid" && -d "/proc/$pid" ]] || return 1
    for fd in /proc/"$pid"/fd/*; do
        [[ -L "$fd" ]] || continue
        target="$(readlink "$fd" 2>/dev/null || true)"
        [[ "$target" == "/dev/$tty_name" ]] && return 0
    done
    return 1
}

session_for_focused_terminal() {
    local apid="$1" tty session
    [[ -n "$apid" ]] || return 0
    while IFS= read -r line; do
        tty="${line%% *}"
        session="${line#* }"
        is_dev_session "$session" || continue
        if pid_uses_tty "$apid" "$tty"; then
            printf '%s\n' "$session"
            return 0
        fi
    done < <(tmux list-clients -F '#{client_tty} #{session_name}' 2>/dev/null || true)
    return 1
}

attached_dev_session() {
    local name attached
    while IFS= read -r name attached; do
        [[ "$attached" == "1" ]] && is_dev_session "$name" && printf '%s\n' "$name" && return 0
    done < <(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null || true)
    return 1
}

latest_dev_session() {
    tmux list-sessions -F '#{session_name}' 2>/dev/null \
        | grep -E "^${PREFIX}(-[0-9]+)?$" \
        | tail -n1 || true
}

reattach_in_focus() {
    local session="$1"
    local apid tty
    apid="$(active_window_pid)"
    [[ -n "$apid" ]] || return 1

    while IFS= read -r tty _; do
        if pid_uses_tty "$apid" "$tty"; then
            printf 'exec tmux attach -t %q\n' "$session" >"/dev/$tty"
            return 0
        fi
    done < <(tmux list-clients -F '#{client_tty} #{session_name}' 2>/dev/null || true)

    local pts
    pts="$(readlink -f "/proc/$apid/fd/0" 2>/dev/null || true)"
    if [[ "$pts" == /dev/pts/* ]]; then
        printf 'tmux attach -t %q\n' "$session" >"$pts"
        return 0
    fi
    return 1
}

if [[ ! -x "$DEV_WS" ]]; then
    $NOTIFY "fontsize:13,Missing dev-workspace.sh"
    exit 1
fi

if ! command -v tmux >/dev/null 2>&1; then
    $NOTIFY "fontsize:13,tmux not installed"
    exit 1
fi

TARGET=""
APID="$(active_window_pid)"
if TARGET="$(session_for_focused_terminal "$APID" 2>/dev/null)"; then
    :
elif TARGET="$(attached_dev_session 2>/dev/null || true)"; then
    :
elif TARGET="$(latest_dev_session)"; then
    [[ -n "$TARGET" ]] || TARGET=""
fi

if [[ -z "$TARGET" ]]; then
    exec "${HOME}/.config/hyprgruv/scripts/dev-workspace.sh"
fi

bash "$DEV_WS" --reset --no-attach "$TARGET"
$NOTIFY "fontsize:13,Dev session reset: ${TARGET}"

if reattach_in_focus "$TARGET"; then
    :
else
    $NOTIFY "fontsize:13,Run: tmux attach -t ${TARGET}"
fi: ${TARGET}"

if reattach_in_focus "$TARGET"; then
    :
else
    $NOTIFY "fontsize:13,Run: tmux attach -t ${TARGET}"
fi