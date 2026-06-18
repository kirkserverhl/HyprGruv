#!/usr/bin/env bash
# terminal.sh — launch the user's preferred terminal (Super+Return, scratchpad, etc.)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_terminal() {
    local term
    term="$("$SCRIPT_DIR/read-setting.sh" terminal kitty)"

    for candidate in "$term" ghostty kitty alacritty foot wezterm; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    printf '%s\n' "xterm"
}

TERM_CMD="$(resolve_terminal)"

if [[ "${1:-}" == "--print" ]]; then
    printf '%s\n' "$TERM_CMD"
    exit 0
fi

exec "$TERM_CMD" "$@"