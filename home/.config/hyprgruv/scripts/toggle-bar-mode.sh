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
# A hung previous toggle (hyprpm enable/disable) used to leave this dir forever
# so later Alt+W presses exited immediately and looked like a dead bind.
if [[ -d "$LOCK_DIR" ]]; then
    lock_age=$(( $(date +%s) - $(stat -c %Y "$LOCK_DIR" 2>/dev/null || echo 0) ))
    if (( lock_age > 3 )); then
        rmdir "$LOCK_DIR" 2>/dev/null || rm -rf "$LOCK_DIR" 2>/dev/null || true
    fi
fi
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