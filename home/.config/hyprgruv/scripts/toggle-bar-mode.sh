#!/usr/bin/env bash
# Cycle bar mode: Waybar only → Hyprbars only → neither → repeat. Bound to ALT+W.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bar-mode-common.sh
source "$SCRIPT_DIR/bar-mode-common.sh"

LOG_FILE="$STATE_DIR/toggle.log"
LOCK_DIR="$STATE_DIR/toggle.lock.d"
mkdir -p "$STATE_DIR"

cleanup_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

# Ignore overlapping toggles (key repeat / double-tap races).
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    exit 0
fi
trap cleanup_lock EXIT

{
    echo "$(date -Iseconds) toggle start saved=$(read_bar_mode)"
} >>"$LOG_FILE"

next=$(next_bar_mode)
apply_bar_mode "$next" >>"$LOG_FILE" 2>&1 || true

{
    echo "$(date -Iseconds) toggle done mode=$(read_bar_mode)"
} >>"$LOG_FILE"