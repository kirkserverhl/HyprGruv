#!/usr/bin/env bash
# git-eod-remind.sh — role-aware daily nudge (SwayNC persistent)
#
# SOURCE (desktop): dirty followed repos → run git-eod
# DEPLOY (laptop):  followed repos behind remote → run git-eod-pull
#
# Usage:
#   git-eod-remind
#   git-eod-remind --force   # notify even when clean/up-to-date
#   git-eod-remind --test
#   git-eod-remind --clear

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
Role-aware git sync reminder (SwayNC critical = stays until dismissed)

  git-eod-remind
  git-eod-remind --force
  git-eod-remind --test
  git-eod-remind --clear

SOURCE → dirty repos → git-eod
DEPLOY → behind repos → git-eod-pull
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

    if [[ ! -f "$GIT_SYNC_CONF" ]]; then
        git_sync_init_conf "$(git_sync_detect_role)" 1
    fi
    git_sync_load
    local role="$GIT_SYNC_ROLE"

    if [[ $TEST -eq 1 ]]; then
        local tip="git-eod"
        [[ "$role" == "deploy" ]] && tip="git-eod-pull"
        persistent_send_notification \
            "Git EOD (test · $role)" \
            "Critical notifications stay until dismissed. Run: $tip" \
            "git" || exit 0
        exit 0
    fi

    local -a lines=()
    local title body action

    if [[ "$role" == "deploy" ]]; then
        action="git-eod-pull"
        title="Repos available for this machine"
        mapfile -t lines < <(git_eod_behind_repo_lines)
        if [[ ${#lines[@]} -eq 0 && $FORCE -eq 0 ]]; then
            persistent_close_notification
            exit 0
        fi
        if [[ ${#lines[@]} -eq 0 ]]; then
            body="Followed repos look up-to-date.\nScheduled reminder · Run: $action\n(Manage: git-sync list)"
        else
            body="$(printf '%s\n\nRun: %s\n(hyprgruv full: git-eod-pull --hyprgruv-full)' "$(printf '%s\n' "${lines[@]}")" "$action")"
        fi
    else
        action="git-eod"
        title="Git repos need a push"
        mapfile -t lines < <(git_eod_dirty_repo_lines)
        if [[ ${#lines[@]} -eq 0 && $FORCE -eq 0 ]]; then
            persistent_close_notification
            exit 0
        fi
        if [[ ${#lines[@]} -eq 0 ]]; then
            body="All followed repos are clean.\nScheduled reminder · Run: $action\n(Manage: git-sync list)"
        else
            body="$(printf '%s\n\nRun: %s' "$(printf '%s\n' "${lines[@]}")" "$action")"
        fi
    fi

    persistent_send_notification \
        "$title" \
        "$body" \
        "git" || exit 0
}

main
