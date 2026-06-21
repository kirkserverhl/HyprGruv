#!/usr/bin/env bash
# system-maintain-remind.sh — daily sticky reminder for updates + cleanup
#
# Usage:
#   system-maintain-remind.sh
#   system-maintain-remind.sh --test
#   system-maintain-remind.sh --clear

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
PERSISTENT_NOTIFY_ID_FILE="$STATE_DIR/system-maintain-notify-id"
PERSISTENT_NOTIFY_APP_NAME="System maintenance"

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/swaync-persistent-remind.sh"
persistent_notify_init

TEST=0
CLEAR=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --test) TEST=1; shift ;;
    --clear) CLEAR=1; shift ;;
    -h | --help)
        cat <<'EOF'
Daily system maintenance reminder (updates + cleanup)

  system-maintain-remind.sh
  system-maintain-remind.sh --test
  system-maintain-remind.sh --clear
EOF
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown option: $1" >&2
        exit 1
        ;;
    esac
done

update_summary_line() {
    local scripts="${HOME}/.config/hyprgruv/scripts"
    local platform aur_helper arch_list aur_list arch_count aur_count total

    platform="$(cat "$scripts/platform.sh" 2>/dev/null || echo arch)"
    aur_helper="$(cat "$scripts/aur.sh" 2>/dev/null || echo yay)"

    case "$platform" in
    arch)
        arch_list="$(timeout 45 checkupdates 2>/dev/null || true)"
        aur_list="$(timeout 45 "$aur_helper" -Qu --aur 2>/dev/null || true)"
        arch_count=0
        aur_count=0
        [[ -n "$arch_list" ]] && arch_count="$(printf '%s\n' "$arch_list" | sed '/^$/d' | wc -l | tr -d ' ')"
        [[ -n "$aur_list" ]] && aur_count="$(printf '%s\n' "$aur_list" | sed '/^$/d' | wc -l | tr -d ' ')"
        total=$((arch_count + aur_count))
        if [[ "$total" -gt 0 ]]; then
            printf 'Updates: %s pending (arch: %s, aur: %s)' "$total" "$arch_count" "$aur_count"
        else
            printf 'Updates: none detected right now'
        fi
        ;;
    fedora)
        total="$(timeout 45 dnf check-update -q 2>/dev/null | grep -c '^[a-z0-9]' || echo 0)"
        if [[ "$total" -gt 0 ]]; then
            printf 'Updates: %s pending' "$total"
        else
            printf 'Updates: none detected right now'
        fi
        ;;
    *)
        printf 'Updates: run your platform update command'
        ;;
    esac
}

build_body() {
    local summary
    summary="$(update_summary_line)"
    cat <<EOF
Time for system maintenance.

${summary}
Run: updates

Clear package caches
Run: cleanup
EOF
}

main() {
    if [[ $CLEAR -eq 1 ]]; then
        persistent_close_notification
        exit 0
    fi

    if ! command -v notify-send &>/dev/null; then
        echo "[WARNING] notify-send not found" >&2
        exit 0
    fi

    if [[ $TEST -eq 1 ]]; then
        persistent_send_notification \
            "System maintenance (test)" \
            "Critical notifications stay until you click them.\nRun: updates\nRun: cleanup" \
            "system-software-update" || exit 0
        exit 0
    fi

    persistent_send_notification \
        "System maintenance due" \
        "$(build_body)" \
        "system-software-update" || exit 0
}

main