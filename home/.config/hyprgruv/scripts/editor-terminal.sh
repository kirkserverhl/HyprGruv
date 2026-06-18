#!/usr/bin/env bash
# editor-terminal.sh — open the configured editor inside the default terminal
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/terminal.sh" "$("$SCRIPT_DIR/editor.sh" --print)" "$@"