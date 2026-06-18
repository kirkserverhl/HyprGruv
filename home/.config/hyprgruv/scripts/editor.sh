#!/usr/bin/env bash
# editor.sh — launch the user's preferred editor
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_editor() {
    local editor
    editor="$("$SCRIPT_DIR/read-setting.sh" editor nvim)"

    for candidate in "$editor" nvim vim nano vi; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    printf '%s\n' "vi"
}

EDITOR_CMD="$(resolve_editor)"

if [[ "${1:-}" == "--print" ]]; then
    printf '%s\n' "$EDITOR_CMD"
    exit 0
fi

exec "$EDITOR_CMD" "$@"