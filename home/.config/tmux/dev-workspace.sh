#!/usr/bin/env bash
# dev-workspace.sh — tmux dev layout (3 panes):
#   +----------+----------+
#   | nvim     | yazi     |  top-right (2/3 height)
#   | (left    +----------+
#   |  half)   | cmatrix  |  bottom-right (1/3 height)
#   |          |          |
#   +----------+----------+
#
# Each run creates a new session (dev-1, dev-2, …). Switch between them with Ctrl-b s.
#
# Pane targeting uses pane IDs (%N), so this works with any pane-base-index
# (stock tmux = 0, oh-my-tmux = 1).
#
# Usage:
#   dev-workspace.sh [start_dir]        create a new dev session and attach
#   dev-workspace.sh --reset [session]  rebuild the layout for the current or named session
set -euo pipefail

SESSION_PREFIX="${TMUX_DEV_PREFIX:-dev}"
WINDOW_NAME="${TMUX_DEV_WINDOW:-workspace}"
EXPECTED_PANES=3
CMATRIX_PANE="${HOME}/.config/tmux/cmatrix-pane.sh"
EDITOR_CMD="${HOME}/.config/hyprgruv/scripts/editor.sh"
RESET=false
NO_ATTACH=false
RESET_SESSION=""
START_DIR=""

usage() {
    cat <<EOF
Usage: $(basename "$0") [--reset|-r] [session_or_dir]

  (no args)       create a new dev-N session and attach
  --reset, -r     rebuild the 3-pane layout for the current tmux session
  --reset NAME    rebuild a specific dev session (e.g. dev-2)
  --no-attach     with --reset: recreate only (for Hyprland Super+R reload)
  start_dir       working directory for new shells (default: \$PWD or \$HOME)

Switch sessions anytime with Ctrl-b s (session picker).
EOF
}

is_dev_session() {
    local name="$1"
    [[ "$name" == "$SESSION_PREFIX" || "$name" == "${SESSION_PREFIX}-"* ]]
}

next_dev_session_name() {
    local max=0 n name
    while IFS= read -r name; do
        if [[ "$name" == "$SESSION_PREFIX" ]]; then
            max=$((max < 1 ? 1 : max))
        elif [[ "$name" =~ ^${SESSION_PREFIX}-([0-9]+)$ ]]; then
            n="${BASH_REMATCH[1]}"
            ((n > max)) && max=$n
        fi
    done < <(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)
    echo "${SESSION_PREFIX}-$((max + 1))"
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -r|--reset)
            RESET=true
            shift
            if [[ $# -gt 0 && "$1" != -* && -d "$1" ]]; then
                START_DIR="$1"
                shift
            elif [[ $# -gt 0 && "$1" != -* ]]; then
                RESET_SESSION="$1"
                shift
            fi
            ;;
        --no-attach)
            NO_ATTACH=true
            shift
            ;;
        --)
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            START_DIR="$1"
            shift
            break
            ;;
    esac
done

if [[ -z "$START_DIR" ]]; then
    START_DIR="${PWD:-$HOME}"
fi

if [[ ! -d "$START_DIR" ]]; then
    START_DIR="$HOME"
fi

create_dev_session() {
    local left_pane right_pane bottom_pane pane_count

    tmux new-session -d -s "$SESSION_NAME" -c "$START_DIR" -n "$WINDOW_NAME"
    tmux set-option -t "$SESSION_NAME" @learning_cheatsheet off 2>/dev/null || true

    # Pane IDs (%N) are independent of pane-base-index (0 vs 1).
    left_pane="$(tmux display -p -t "${SESSION_NAME}:${WINDOW_NAME}" '#{pane_id}')"
    # -P/-F print the newly created pane id
    right_pane="$(tmux split-window -h -t "$left_pane" -P -F '#{pane_id}' -p 50 -c "$START_DIR")"
    bottom_pane="$(tmux split-window -v -t "$right_pane" -P -F '#{pane_id}' -p 34 -c "$START_DIR")"

    pane_count="$(tmux list-panes -t "${SESSION_NAME}:${WINDOW_NAME}" 2>/dev/null | wc -l)"
    if [[ "${pane_count// /}" -lt "$EXPECTED_PANES" ]]; then
        echo "dev-workspace: expected $EXPECTED_PANES panes, got $pane_count" >&2
        tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
        exit 1
    fi

    # left: editor | top-right: yazi | bottom-right: cmatrix
    if [[ -x "$EDITOR_CMD" ]]; then
        tmux send-keys -t "$left_pane" \
            "$("$EDITOR_CMD" --print)" Enter
    elif command -v nvim >/dev/null; then
        tmux send-keys -t "$left_pane" "nvim" Enter
    fi

    if [[ -x "${HOME}/.config/hyprgruv/scripts/yazi-matugen.sh" ]]; then
        tmux send-keys -t "$right_pane" \
            "${HOME}/.config/hyprgruv/scripts/yazi-matugen.sh" Enter
    elif command -v yazi >/dev/null; then
        tmux send-keys -t "$right_pane" "yazi" Enter
    fi

    if [[ -x "$CMATRIX_PANE" ]]; then
        tmux send-keys -t "$bottom_pane" "$CMATRIX_PANE" Enter
    elif command -v cmatrix >/dev/null; then
        tmux send-keys -t "$bottom_pane" "cmatrix -s" Enter
    fi

    tmux select-pane -t "$left_pane"
    tmux select-window -t "${SESSION_NAME}:${WINDOW_NAME}"
}

attach_or_switch() {
    if [[ -n "${TMUX:-}" ]]; then
        tmux switch-client -t "$SESSION_NAME"
    else
        exec tmux attach -t "$SESSION_NAME"
    fi
}

if [[ "$RESET" == true ]]; then
    if [[ -z "$RESET_SESSION" && -n "${TMUX:-}" ]]; then
        RESET_SESSION="$(tmux display -p '#{session_name}' 2>/dev/null || true)"
    fi

    if [[ -z "$RESET_SESSION" ]]; then
        echo "Specify a session: $(basename "$0") --reset dev-2" >&2
        echo "Or run from inside a dev session to reset it in place." >&2
        exit 1
    fi

    if ! is_dev_session "$RESET_SESSION"; then
        echo "Not a dev session: $RESET_SESSION" >&2
        exit 1
    fi

    if tmux has-session -t "$RESET_SESSION" 2>/dev/null; then
        START_DIR="$(tmux display -p -t "$RESET_SESSION" '#{pane_current_path}' 2>/dev/null || echo "$START_DIR")"
        tmux kill-session -t "$RESET_SESSION"
    fi

    SESSION_NAME="$RESET_SESSION"
    create_dev_session
    if [[ "$NO_ATTACH" == true ]]; then
        exit 0
    fi
    attach_or_switch
    exit 0
fi

SESSION_NAME="$(next_dev_session_name)"
create_dev_session
attach_or_switch
