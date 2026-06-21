#!/usr/bin/env bash
# git-eod-remind.sh — persistent SwayNC nudge when repos have uncommitted work
#
# Usage:
#   git-eod-remind.sh
#   git-eod-remind.sh --force   # notify even when all repos are clean
#   git-eod-remind.sh --test    # send a test notification
#   git-eod-remind.sh --clear   # dismiss any saved reminder

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
PERSISTENT_NOTIFY_ID_FILE="$STATE_DIR/git-eod-notify-id"
PERSISTENT_NOTIFY_APP_NAME="Git EOD"

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/swaync-persistent-remind.sh"
persistent_notify_init

FORCE=0
TEST=0
CLEAR=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --force) FORCE=1; shift ;;
    --test) TEST=1; shift ;;
    --clear) CLEAR=1; shift ;;
    -h | --help)
        cat <<'EOF'
Persistent git-eod reminder (SwayNC critical = stays until dismissed)

  git-eod-remind.sh
  git-eod-remind.sh --force
  git-eod-remind.sh --test
  git-eod-remind.sh --clear
EOF
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown option: $1" >&2
        exit 1
        ;;
    esac
done

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
            "Git EOD (test)" \
            "Critical notifications stay until you click them. Run: git-eod" \
            "git" || exit 0
        exit 0
    fi

    mapfile -t dirty_lines < <(git_eod_dirty_repo_lines)

    if [[ ${#dirty_lines[@]} -eq 0 && $FORCE -eq 0 ]]; then
        persistent_close_notification
        exit 0
    fi

    local body
    if [[ ${#dirty_lines[@]} -eq 0 ]]; then
        body="All repos are clean, but here is your scheduled reminder.\nRun: git-eod"
    else
        body="$(printf '%s\n\nRun: git-eod' "$(printf '%s\n' "${dirty_lines[@]}")")"
    fi

    persistent_send_notification \
        "Git repos need a sync" \
        "$body" \
        "git" || exit 0
}

main