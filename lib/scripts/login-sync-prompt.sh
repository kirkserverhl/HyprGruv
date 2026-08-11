#!/usr/bin/env bash
# login-sync-prompt.sh — role-aware sync nudge shortly after graphical login
#
# Called from Hyprland autostart (both machines). Also safe to run manually.
#
#   ROLE=deploy  → if hyprgruv is behind origin: rofi update menu
#                  + persistent notify when any followed repo is behind
#   ROLE=source  → persistent notify when any followed repo is dirty (run git-eod)
#
# Periodic backups (independent of this script):
#   git-eod-remind.timer              (both roles)
#   hyprgruv-update-check.timer       (deploy only)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
mkdir -p "$STATE_DIR"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"

wait_for_network() {
    local i
    for i in 1 2 3 4 5 6 7 8 9 10; do
        if git -C "$HYPR_DIR" ls-remote --heads origin HEAD &>/dev/null; then
            return 0
        fi
        sleep 2
    done
    return 1
}

ensure_timers() {
    # Both roles: daily / boot catch-up for dirty-or-behind followed repos
    systemctl --user enable --now git-eod-remind.timer 2>/dev/null || true

    # Deploy only: periodic hyprgruv remote update checks
    if [[ "${GIT_SYNC_ROLE:-}" == "deploy" ]] || [[ -f "$STATE_DIR/deploy-target" ]]; then
        systemctl --user enable --now hyprgruv-update-check.timer 2>/dev/null || true
    fi
}

main() {
    if [[ ! -f "$GIT_SYNC_CONF" ]]; then
        git_sync_init_conf "$(git_sync_detect_role)" 1
    fi
    git_sync_load

    ensure_timers

    # Need a session for rofi / notify; skip pure TTY logins
    if [[ -z "${WAYLAND_DISPLAY:-}${DISPLAY:-}" ]]; then
        exit 0
    fi

    wait_for_network || true

    # 1) Deploy: interactive hyprgruv pull menu when main has new commits
    if [[ "$GIT_SYNC_ROLE" == "deploy" ]] || [[ -f "$STATE_DIR/deploy-target" ]]; then
        if [[ -x "$HYPR_DIR/lib/scripts/repo-update-check.sh" ]]; then
            # --prompt-if-needed respects dismiss + only runs on deploy markers
            bash "$HYPR_DIR/lib/scripts/repo-update-check.sh" --prompt-if-needed \
                || true
        fi
    fi

    # 2) Both roles: persistent SwayNC when followed repos need push or pull
    if [[ -x "$HYPR_DIR/lib/scripts/git-eod-remind.sh" ]]; then
        bash "$HYPR_DIR/lib/scripts/git-eod-remind.sh" || true
    fi
}

main "$@"
