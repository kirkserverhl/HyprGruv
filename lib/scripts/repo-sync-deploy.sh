#!/usr/bin/env bash
# repo-sync-deploy.sh — stash local changes, pull hyprgruv, optional stow + package sync
#
# Usage:
#   bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh
#   bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh --packages --stow
#   bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh --dry-run

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
LOG_DIR="$STATE_DIR/logs"
mkdir -p "$LOG_DIR"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"

DO_PULL=1
DO_PACKAGES=0
DO_STOW=0
DRY_RUN=0

usage() {
    cat <<'EOF'
Hyprgruv repo deploy — pull updates and apply them on this machine

Options:
  --pull        Fetch + pull with stash (default: on)
  --no-pull     Skip git pull (only run packages/stow)
  --packages    Run sync-packages.sh after pull
  --stow        Restow home/ with stow --adopt after pull
  --full        Shorthand for --pull --packages --stow
  --dry-run     Show planned actions only
  --help        Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --pull) DO_PULL=1 ;;
    --no-pull) DO_PULL=0 ;;
    --packages) DO_PACKAGES=1 ;;
    --stow) DO_STOW=1 ;;
    --full)
        DO_PULL=1
        DO_PACKAGES=1
        DO_STOW=1
        ;;
    --dry-run) DRY_RUN=1 ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown option: $1" >&2
        usage
        exit 1
        ;;
    esac
    shift
done

run_cmd() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_status "[dry-run] $*"
        return 0
    fi
    "$@"
}

git_upstream_ref() {
    local ref
    ref="$(git -C "$HYPR_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || return 1
    printf '%s\n' "$ref"
}

repo_pull_with_stash() {
    local branch upstream stash_msg logfile
    branch="$(git -C "$HYPR_DIR" rev-parse --abbrev-ref HEAD)"
    upstream="$(git_upstream_ref)" || {
        log_error "No upstream configured for branch $branch"
        log_status "Set upstream: git -C ~/.hyprgruv branch --set-upstream-to=origin/$branch"
        return 1
    }

    log_status "Fetching from remote…"
    run_cmd git -C "$HYPR_DIR" fetch --prune origin

    if git -C "$HYPR_DIR" diff --quiet && git -C "$HYPR_DIR" diff --cached --quiet; then
        :
    else
        stash_msg="hyprgruv deploy $(date +%Y%m%d-%H%M%S)"
        log_status "Local changes detected — stashing before pull"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_status "[dry-run] git stash push -u -m '$stash_msg'"
        else
            git -C "$HYPR_DIR" stash push -u -m "$stash_msg" || log_warning "Stash failed or nothing to stash"
        fi
    fi

    logfile="$LOG_DIR/pull_$(date +%Y%m%d_%H%M%S).log"
    log_status "Pulling $upstream into $branch"
    if [[ $DRY_RUN -eq 1 ]]; then
        log_status "[dry-run] git -C $HYPR_DIR pull --rebase"
        return 0
    fi

    if git -C "$HYPR_DIR" pull --rebase 2>&1 | tee "$logfile"; then
        log_success "Repository updated"
        printf '%s\n' "$(git -C "$HYPR_DIR" rev-parse HEAD)" >"$STATE_DIR/last_deployed_commit"
        return 0
    fi

    log_error "git pull failed — see $logfile"
    return 1
}

repo_restow_home() {
    local pkg_dir="$HYPR_DIR/home"
    [[ -d "$pkg_dir" ]] || {
        log_error "Missing stow package: $pkg_dir"
        return 1
    }
    command -v stow &>/dev/null || {
        log_error "stow not found"
        return 1
    }

    log_status "Restowing home/ into $HOME (stow --adopt)"
    if [[ $DRY_RUN -eq 1 ]]; then
        run_cmd stow -n -v --adopt -R -t "$HOME" -d "$HYPR_DIR" home
        return 0
    fi

    (
        cd "$HYPR_DIR"
        stow --adopt -R -t "$HOME" home
    )
    log_success "Stow complete — review with: cd ~/.hyprgruv && git status"
}

main() {
    display_header "Hyprgruv Deploy" 2>/dev/null || true
    log_status "Repo: $HYPR_DIR"

    if [[ $DO_PULL -eq 1 ]]; then
        repo_pull_with_stash
    fi

    if [[ $DO_STOW -eq 1 ]]; then
        repo_restow_home
    fi

    if [[ $DO_PACKAGES -eq 1 ]]; then
        log_status "Syncing packages from manifest…"
        if [[ $DRY_RUN -eq 1 ]]; then
            run_cmd bash "$HYPR_DIR/lib/scripts/sync-packages.sh" --dry-run
        else
            bash "$HYPR_DIR/lib/scripts/sync-packages.sh"
        fi
    fi

    log_success "Deploy finished"
}

main