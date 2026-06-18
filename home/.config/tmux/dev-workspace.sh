#!/usr/bin/env bash
# dev-workspace.sh — tmux dev layout:
#   +----------+----------+
#   |          | nvim     |  top-right
#   | shell    +----------+
#   | (left)   | yazi     |  bottom-right
#   +----------+----------+
set -euo pipefail

SESSION_NAME="${TMUX_DEV_SESSION:-dev}"
WINDOW_NAME="${TMUX_DEV_WINDOW:-workspace}"
START_DIR="${1:-${PWD:-$HOME}}"
NVIM_CMD="${EDITOR:-nvim}"

if [[ ! -d "$START_DIR" ]]; then
    START_DIR="$HOME"
fi

# Already inside this session → attach only
if [[ -n "${TMUX:-}" ]] && [[ "$(tmux display -p '#{session_name}' 2>/dev/null)" == "$SESSION_NAME" ]]; then
    exit 0
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    exec tmux attach -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -c "$START_DIR" -n "$WINDOW_NAME"
tmux set-option -t "$SESSION_NAME" @learning_cheatsheet off

# Pane 1: left (shell). Pane 2: top-right (nvim). Pane 3: bottom-right (yazi).
# (oh-my-tmux uses base-index 1 for panes/windows.)
tmux split-window -h -t "${SESSION_NAME}:${WINDOW_NAME}" -p 45 -c "$START_DIR"
tmux split-window -v -t "${SESSION_NAME}:${WINDOW_NAME}.2" -p 33 -c "$START_DIR"

tmux send-keys -t "${SESSION_NAME}:${WINDOW_NAME}.2" "$NVIM_CMD" Enter
tmux send-keys -t "${SESSION_NAME}:${WINDOW_NAME}.3" "yazi" Enter

tmux select-pane -t "${SESSION_NAME}:${WINDOW_NAME}.1"
tmux select-window -t "${SESSION_NAME}:${WINDOW_NAME}"

exec tmux attach -t "$SESSION_NAME"