#!/usr/bin/env bash
# repo-update-check.sh — detect remote hyprgruv updates and prompt via rofi
#
# Usage:
#   repo-update-check.sh check              Exit 0 if updates available
#   repo-update-check.sh --notify           Desktop notification only
#   repo-update-check.sh --prompt           Always show rofi menu when behind
#   repo-update-check.sh --prompt-if-needed Skip if user dismissed this commit
#
# Enable periodic checks (laptop / test machine):
#   systemctl --user enable --now hyprgruv-update-check.timer

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
DISMISS_FILE="$STATE_DIR/dismissed_remote_commit"
LAST_NOTIFY_FILE="$STATE_DIR/last_notified_commit"
mkdir -p "$STATE_DIR"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"

MODE="${1:---prompt-if-needed}"
DEPLOY_MARKER="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/deploy-target"

is_deploy_target() {
    [[ "${HYPRGRUV_DEPLOY_TARGET:-0}" == "1" ]] && return 0
    [[ -f "$DEPLOY_MARKER" ]]
}

usage() {
    cat <<'EOF'
Hyprgruv update checker

Modes:
  check                 Exit 0 when remote has new commits
  --notify              Send libnotify alert
  --prompt              Show rofi menu when behind remote
  --prompt-if-needed    Notify + rofi unless dismissed for this commit
  --mark-current        Record current remote as seen (dismiss)
  --help

After desktop push, the laptop timer or login hook runs this script.

Laptop / deploy machine only (avoids prompts on your push desktop):
  mkdir -p ~/.config/hyprgruv
  touch ~/.config/hyprgruv/deploy-target
  systemctl --user enable --now hyprgruv-update-check.timer
EOF
}

skip_unless_deploy_target() {
    if is_deploy_target || [[ "${HYPRGRUV_FORCE_CHECK:-0}" == "1" ]]; then
        return 0
    fi
    exit 0
}

git_upstream_ref() {
    git -C "$HYPR_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null
}

remote_head_commit() {
    local upstream
    upstream="$(git_upstream_ref)" || return 1
    git -C "$HYPR_DIR" rev-parse "$upstream"
}

local_head_commit() {
    git -C "$HYPR_DIR" rev-parse HEAD
}

fetch_quiet() {
    git -C "$HYPR_DIR" fetch --prune origin &>/dev/null
}

updates_available() {
    local local_rev remote_rev
    local_rev="$(local_head_commit)"
    remote_rev="$(remote_head_commit)" || return 1
    [[ "$local_rev" != "$remote_rev" ]]
}

commit_summary() {
    local upstream
    upstream="$(git_upstream_ref)" || return 0
    git -C "$HYPR_DIR" log --oneline HEAD.."$upstream" 2>/dev/null | head -20
}

behind_count() {
    local upstream
    upstream="$(git_upstream_ref)" || echo 0
    git -C "$HYPR_DIR" rev-list --count HEAD.."$upstream" 2>/dev/null || echo 0
}

is_dismissed() {
    local remote_rev
    remote_rev="$(remote_head_commit)" || return 1
    [[ -f "$DISMISS_FILE" ]] && [[ "$(cat "$DISMISS_FILE")" == "$remote_rev" ]]
}

mark_dismissed() {
    remote_head_commit >"$DISMISS_FILE"
}

mark_notified() {
    remote_head_commit >"$LAST_NOTIFY_FILE"
}

pick_menu() {
    local count summary
    count="$(behind_count)"
    summary="$(commit_summary | head -5 | tr '\n' ' ' | cut -c1-120)"

    if command -v rofi &>/dev/null; then
        printf '%s\n' \
            "Pull updates ($count commits)" \
            "Pull + sync packages" \
            "Pull + sync packages + restow (full deploy)" \
            "View incoming commits" \
            "Dismiss until next push" \
            "Remind me in 1 hour" | rofi -dmenu -i -p "Hyprgruv updates available" -mesg "$summary"
        return
    fi

    echo "[ERROR] rofi required for interactive prompt" >&2
    return 1
}

send_notification() {
    local count msg
    count="$(behind_count)"
    msg="Hyprgruv: $count commit(s) ready on the laptop test machine."
    if command -v notify-send &>/dev/null; then
        notify-send -a "Hyprgruv" -i "system-software-update" \
            "Hyprgruv updates available" \
            "$msg Run: hyprgruv-update-check --prompt"
    else
        log_status "$msg"
    fi
    mark_notified
}

run_menu_action() {
    local choice="$1"
    local deploy="$HYPR_DIR/lib/scripts/repo-sync-deploy.sh"

    case "$choice" in
    "Pull updates"*)
        bash "$deploy" --pull
        mark_dismissed
        ;;
    "Pull + sync packages")
        bash "$deploy" --pull --packages
        mark_dismissed
        ;;
    "Pull + sync packages + restow"*)
        bash "$deploy" --full
        mark_dismissed
        ;;
    "View incoming commits")
        local upstream log_text
        upstream="$(git_upstream_ref)"
        log_text="$(git -C "$HYPR_DIR" log --oneline HEAD.."$upstream" 2>/dev/null || true)"
        if command -v rofi &>/dev/null; then
            printf '%s\n' "$log_text" | rofi -dmenu -i -p "Incoming commits" -lines 15
        else
            printf '%s\n' "$log_text"
        fi
        # Re-open menu after viewing
        prompt_user
        ;;
    "Dismiss until next push")
        mark_dismissed
        log_status "Dismissed until a newer commit is pushed"
        ;;
    "Remind me in 1 hour")
        mark_dismissed
        systemd-run --user --on-active=1h --unit=hyprgruv-update-remind \
            bash "$HYPR_DIR/lib/scripts/repo-update-check.sh" --prompt-if-needed 2>/dev/null \
            || log_status "Reminder scheduled in ~1 hour (via systemd-run)"
        ;;
    "" | *)
        :
        ;;
    esac
}

prompt_user() {
    local choice
    choice="$(pick_menu)" || return 0
    run_menu_action "$choice"
}

do_check() {
    [[ -d "$HYPR_DIR/.git" ]] || {
        log_error "Not a git repo: $HYPR_DIR"
        return 1
    }
    fetch_quiet
    updates_available
}

case "$MODE" in
check)
    do_check
    exit $?
    ;;
--notify)
    skip_unless_deploy_target
    if do_check; then
        send_notification
        exit 0
    fi
    exit 1
    ;;
--prompt)
    if do_check; then
        prompt_user
        exit 0
    fi
    log_status "Hyprgruv repo is up to date"
    exit 1
    ;;
--prompt-if-needed)
    skip_unless_deploy_target
    if ! do_check; then
        exit 1
    fi
    if is_dismissed; then
        exit 0
    fi
    send_notification
    prompt_user
    exit 0
    ;;
--mark-current)
    fetch_quiet
    mark_dismissed
    mark_notified
    log_success "Marked current remote commit as seen"
    exit 0
    ;;
--help | -h | help)
    usage
    exit 0
    ;;
*)
    echo "[ERROR] Unknown mode: $MODE" >&2
    usage
    exit 1
    ;;
esac