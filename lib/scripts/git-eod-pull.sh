#!/usr/bin/env bash
# git-eod-pull.sh — DEPLOY role: fetch + pull followed repos
#
# Opposite of git-eod (source push). For hyprgruv, can hand off to full deploy.
#
# Usage:
#   git-eod-pull
#   git-eod-pull --only hyprgruv
#   git-eod-pull --hyprgruv-full   # pull + packages + restow for hyprgruv
#   git-eod-pull --dry-run
#   git-eod-pull --force           # allow on source role

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"

DRY_RUN=0
ONLY_FILTER=""
FORCE_ROLE=0
HYPRGRUV_FULL=0

usage() {
    cat <<'EOF'
EOD git pull (DEPLOY / laptop) — pull followed repos

Options:
  --only NAMES        Comma-separated subset of followed repos
  --hyprgruv-full     For hyprgruv: repo-sync-deploy --full (pull+packages+stow)
  --dry-run           Show planned actions only
  --force             Allow run even if ROLE=source
  -h, --help

Manage follows:
  git-sync list | follow | unfollow | local-only | inventory

Source / desktop machines should use:  git-eod
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --only)
        [[ $# -ge 2 ]] || {
            log_error "Missing value for $1"
            exit 1
        }
        ONLY_FILTER="$2"
        shift 2
        ;;
    --hyprgruv-full) HYPRGRUV_FULL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --force) FORCE_ROLE=1; shift ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

if [[ ! -f "$GIT_SYNC_CONF" ]]; then
    git_sync_init_conf "$(git_sync_detect_role)" 1
fi
git_sync_load

if [[ "$GIT_SYNC_ROLE" != "deploy" && $FORCE_ROLE -eq 0 ]]; then
    log_error "This machine is ROLE=$GIT_SYNC_ROLE (source/push)."
    log_status "Use:  git-eod"
    log_status "Or:   git-eod-pull --force"
    exit 2
fi

REPO_NAMES=("${GIT_EOD_REPO_NAMES[@]}")
REPO_PATHS=("${GIT_EOD_REPO_PATHS[@]}")

if [[ ${#REPO_NAMES[@]} -eq 0 ]]; then
    log_warning "No followed repos. Run: git-sync follow hyprgruv"
    exit 0
fi

repo_selected() {
    local name="$1"
    [[ -z "$ONLY_FILTER" ]] && return 0
    local item
    IFS=',' read -ra items <<<"$ONLY_FILTER"
    for item in "${items[@]}"; do
        item="$(git_sync_trim "$item")"
        [[ "$item" == "$name" ]] && return 0
    done
    return 1
}

run_cmd() {
    if [[ $DRY_RUN -eq 1 ]]; then
        # IFS is newline/tab — join args with spaces for display
        local joined=""
        local a
        for a in "$@"; do
            joined+="$a "
        done
        log_status "[dry-run] $joined"
        return 0
    fi
    "$@"
}

pull_repo() {
    local name="$1"
    local path="$2"

    if [[ ! -d "$path/.git" ]]; then
        log_warning "Skipping $name — not a git repo: $path"
        log_status "Clone it first, or: git-sync unfollow $name"
        return 1
    fi

    # hyprgruv full deploy path
    if [[ "$name" == "hyprgruv" && $HYPRGRUV_FULL -eq 1 ]]; then
        log_status "$name — full deploy (pull + packages + stow)"
        if [[ $DRY_RUN -eq 1 ]]; then
            log_status "[dry-run] repo-sync-deploy.sh --full"
            return 0
        fi
        bash "$HYPR_DIR/lib/scripts/repo-sync-deploy.sh" --full
        return $?
    fi

    log_status "$name — fetch + pull --ff-only"

    run_cmd git -C "$path" fetch --prune

    if [[ $DRY_RUN -eq 1 ]]; then
        if git_eod_repo_behind "$path"; then
            log_status "[dry-run] would pull: $(git_eod_behind_summary "$path")"
        else
            log_status "[dry-run] already up-to-date"
        fi
        return 0
    fi

    # Stash local dirt so pull can proceed on deploy machines
    local stashed=0
    if git_eod_repo_has_changes "$path"; then
        log_warning "$name has local changes — stashing before pull"
        git -C "$path" stash push -u -m "git-eod-pull: $(date -Iseconds)" || true
        stashed=1
    fi

    if git -C "$path" rev-parse --abbrev-ref '@{u}' &>/dev/null; then
        if git -C "$path" pull --ff-only; then
            log_success "$name — pulled"
            if [[ $stashed -eq 1 ]]; then
                log_status "$name — stash kept (git -C $path stash list)"
            fi
            # Live matugen outputs are machine-local (gitignored). After a
            # hyprgruv pull they may be missing or still from a pre-ignore era;
            # re-seed only when markers are absent so we never clobber a local theme.
            if [[ "$name" == "hyprgruv" ]]; then
                local ensure="$HYPR_DIR/lib/scripts/ensure-local-palette.sh"
                if [[ -f "$ensure" ]]; then
                    log_status "$name — ensuring local theme palette (gruvbox default if missing)"
                    bash "$ensure" || log_warning "$name — ensure-local-palette failed (run apply-theme.sh manually)"
                fi
            fi
            return 0
        fi
        log_error "$name — pull failed"
        return 1
    fi

    log_warning "$name — no upstream set; fetch only"
    return 0
}

main() {
    display_header "EOD Git Pull (deploy)" 2>/dev/null || true
    log_status "Role: $GIT_SYNC_ROLE"
    log_status "Followed: ${REPO_NAMES[*]}"
    [[ $DRY_RUN -eq 1 ]] && log_status "Dry run — no changes will be made"

    local failures=0
    local i name path

    for i in "${!REPO_NAMES[@]}"; do
        name="${REPO_NAMES[$i]}"
        path="${REPO_PATHS[$i]}"
        if ! repo_selected "$name"; then
            continue
        fi
        echo ""
        log_status "=== $name ($path) ==="
        if ! pull_repo "$name" "$path"; then
            failures=$((failures + 1))
        fi
    done

    echo ""
    if [[ $failures -eq 0 ]]; then
        bash "$HYPR_DIR/lib/scripts/git-eod-remind.sh" --clear 2>/dev/null || true
        # Surface cross-device handoffs for the other Grok / human session
        if [[ -f "$HYPR_DIR/lib/scripts/git-sync.sh" ]]; then
            echo ""
            log_status "Cross-device handoffs:"
            if bash "$HYPR_DIR/lib/scripts/git-sync.sh" unread 2>/dev/null; then
                :
            fi
            log_status "Full brief: git-sync brief   (or open docs/device-sync/LATEST.md)"
        fi
        log_success "EOD pull finished"
        exit 0
    fi
    log_error "EOD pull finished with $failures failure(s)"
    exit 1
}

main
