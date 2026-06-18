#!/usr/bin/env bash
# browser.sh — launch the user's preferred browser
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

resolve_browser() {
    local browser
    browser="$("$SCRIPT_DIR/read-setting.sh" browser firefox)"

    for candidate in "$browser" brave firefox google-chrome-stable chromium; do
        if command -v "$candidate" >/dev/null 2>&1; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    printf '%s\n' "firefox"
}

BROWSER_CMD="$(resolve_browser)"

if [[ "${1:-}" == "--print" ]]; then
    printf '%s\n' "$BROWSER_CMD"
    exit 0
fi

exec "$BROWSER_CMD" "$@"