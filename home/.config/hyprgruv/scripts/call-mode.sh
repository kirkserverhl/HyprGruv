#!/usr/bin/env bash
# call-mode.sh — flip the desk to even (call) workspaces + persistent notes editor.
#
#   call-mode.sh call     even workspaces, ensure CALL notes editor
#   call-mode.sh end      restore the workspaces that were showing
#   call-mode.sh toggle
#   call-mode.sh status
#
# Odd = chill, even = call. Per-monitor pairs are already 1-2, 3-4, 5-6, 7-8.
# CALL notes: farthest-left vertical (24CN65), even WS 4 — bottom of that
# panel. Kirk calls this monitor 2. Do not move it. Laptop fallback is WS 2.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv"
STATE_FILE="$STATE_DIR/call-mode.json"
NOTES_FILE="${HOME}/notes/work/call-scratch.md"
CLASS="call-notes"

need_jq() {
    command -v jq >/dev/null 2>&1 || {
        echo "jq required" >&2
        exit 1
    }
}

notify() {
    local title="$1" body="${2:-}"
    notify-send -e -u low "$title" "$body" 2>/dev/null || true
    hyprctl notify 0 1800 0 "$title${body:+ — $body}" >/dev/null 2>&1 || true
}

mode_now() {
    if [[ -f "$STATE_FILE" ]] && jq -e '.mode == "call"' "$STATE_FILE" >/dev/null 2>&1; then
        printf 'call'
    else
        printf 'chill'
    fi
}

notes_workspace() {
    if hyprctl workspaces -j 2>/dev/null | jq -e '.[] | select(.id == 4)' >/dev/null; then
        printf '4'
    else
        printf '2'
    fi
}

even_workspaces() {
    hyprctl monitors -j | jq -r '
        .[]
        | select((.activeWorkspace.id // 0) > 0)
        | .name as $mon
        | .activeWorkspace.id as $cur
        | if $cur % 2 == 0 then $cur else $cur + 1 end
    ' | sort -n | uniq
}

snapshot_monitors() {
    hyprctl monitors -j | jq '[
        .[] | {
            name: .name,
            description: .description,
            workspace: (.activeWorkspace.id // 0)
        }
    ]'
}

dispatch_ws() {
    local ws="$1"
    hyprctl dispatch "hl.dsp.focus({ workspace = ${ws} })" >/dev/null 2>&1 \
        || hyprctl dispatch workspace "$ws" >/dev/null 2>&1 || true
}

switch_evens() {
    local ws notes
    notes="$(notes_workspace)"
    while read -r ws; do
        [[ -n "$ws" ]] || continue
        [[ "$ws" == "$notes" ]] && continue
        dispatch_ws "$ws"
    done < <(even_workspaces)
    dispatch_ws "$notes"
}

restore_snapshot() {
    local name ws
    while IFS=$'\t' read -r name ws; do
        [[ -n "$name" && -n "$ws" && "$ws" != "0" ]] || continue
        hyprctl dispatch "hl.dsp.focus({ monitor = [[${name}]] })" >/dev/null 2>&1 || true
        dispatch_ws "$ws"
    done < <(jq -r '.monitors[] | "\(.name)\t\(.workspace)"' "$STATE_FILE")
}

editor_addr() {
    hyprctl clients -j | jq -r --arg c "$CLASS" '
        .[]
        | select((.class == $c) or (.initialClass == $c))
        | .address
    ' | head -1
}

spawn_editor() {
    local ws term editor
    ws="$(notes_workspace)"
    mkdir -p "$(dirname "$NOTES_FILE")"
    if [[ ! -f "$NOTES_FILE" ]]; then
        printf '# CALL notes\n\nPark call scratch here. New heading each shift is fine.\n\n' >"$NOTES_FILE"
    fi
    term="$("$SCRIPT_DIR/terminal.sh" --print)"
    editor="$("$SCRIPT_DIR/editor.sh" --print)"
    if [[ "$term" == *kitty ]]; then
        hyprctl dispatch "hl.dsp.exec_cmd([[${term} --class ${CLASS} --title CALL-notes -e ${editor} ${NOTES_FILE}]], { workspace = ${ws} })" >/dev/null
    else
        hyprctl dispatch "hl.dsp.exec_cmd([[${term} -e ${editor} ${NOTES_FILE}]], { workspace = ${ws} })" >/dev/null
    fi
}

ensure_editor() {
    local addr
    addr="$(editor_addr)"
    if [[ -n "$addr" ]]; then
        hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1 || true
        return 0
    fi
    spawn_editor
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        sleep 0.2
        addr="$(editor_addr)"
        if [[ -n "$addr" ]]; then
            hyprctl dispatch focuswindow "address:${addr}" >/dev/null 2>&1 || true
            return 0
        fi
    done
}

enter_call() {
    mkdir -p "$STATE_DIR"
    if [[ "$(mode_now)" == "call" ]]; then
        ensure_editor
        notify "CALL" "already on even workspaces"
        return 0
    fi
    snapshot_monitors | jq --argjson notes "$(notes_workspace)" \
        '{mode:"call", notes_workspace:$notes, monitors:.}' >"$STATE_FILE"
    switch_evens
    ensure_editor
    notify "CALL" "even workspaces + notes"
}

leave_call() {
    if [[ "$(mode_now)" != "call" ]]; then
        notify "CALL" "already off"
        return 0
    fi
    restore_snapshot
    rm -f "$STATE_FILE"
    notify "CALL" "restored"
}

need_jq

case "${1:-status}" in
    call | on | start) enter_call ;;
    end | off | restore) leave_call ;;
    toggle)
        if [[ "$(mode_now)" == "call" ]]; then
            leave_call
        else
            enter_call
        fi
        ;;
    status)
        addr="$(editor_addr)"
        printf 'mode=%s notes_ws=%s editor=%s\n' \
            "$(mode_now)" "$(notes_workspace)" "${addr:-none}"
        if [[ -f "$STATE_FILE" ]]; then
            jq -c '{mode, notes_workspace, monitors: [.monitors[] | {name, workspace}]}' "$STATE_FILE"
        fi
        ;;
    *)
        echo "usage: call-mode.sh call|end|toggle|status" >&2
        exit 2
        ;;
esac
