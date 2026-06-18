#!/usr/bin/env bash
# dev-workspace.sh — open the dev tmux layout in the user's terminal
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_DEV="${HOME}/.config/tmux/dev-workspace.sh"
START_DIR="${1:-$HOME}"

[[ -f "$TMUX_DEV" ]] || {
    echo "Missing: $TMUX_DEV" >&2
    exit 1
}

TERM_CMD="$("$SCRIPT_DIR/terminal.sh" --print)"
exec "$TERM_CMD" -e bash -lc "$(printf '%q' "$TMUX_DEV") $(printf '%q' "$START_DIR")"