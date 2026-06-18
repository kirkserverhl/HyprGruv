#!/usr/bin/env bash
# filemanager.sh — launch the user's preferred file manager
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_filemanager() {
    local fm
    fm="$("$SCRIPT_DIR/read-setting.sh" filemanager thunar)"

    for candidate in "$fm" thunar nautilus dolphin nemo pcmanfm; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    printf '%s\n' "thunar"
}

FM_CMD="$(resolve_filemanager)"

if [[ "${1:-}" == "--print" ]]; then
    printf '%s\n' "$FM_CMD"
    exit 0
fi

exec "$FM_CMD" "$@"