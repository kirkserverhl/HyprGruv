#!/usr/bin/env bash
# Print the tmux cheat sheet in-pane (like fastfetch), then return to the shell prompt.
set -euo pipefail

CHEAT="${HOME}/.config/tmux/cheatsheet.txt"

if [[ ! -f "$CHEAT" ]]; then
  exit 0
fi

show="$(tmux show-option -gv @learning_cheatsheet 2>/dev/null || echo on)"
case "$show" in
  0|off|false|disabled) exit 0 ;;
esac

pane="${1:-$(tmux display -p '#{pane_id}')}"

sess="$(tmux display -p -t "$pane" '#{session_name}' 2>/dev/null || true)"
[[ "$sess" == "dev" ]] && exit 0

# Wait for an interactive shell so the command runs at a real prompt.
for _ in {1..50}; do
  cmd="$(tmux display -p -t "$pane" '#{pane_current_command}' 2>/dev/null || true)"
  [[ "$cmd" =~ ^(zsh|bash|fish|sh)$ ]] && break
  sleep 0.1
done

if command -v bat >/dev/null 2>&1; then
  run_cmd="PAGER=cat bat --paging=never --decorations=never $(printf '%q' "$CHEAT"); echo"
else
  run_cmd="cat $(printf '%q' "$CHEAT"); echo"
fi

tmux send-keys -t "$pane" -l "$run_cmd"
tmux send-keys -t "$pane" Enter