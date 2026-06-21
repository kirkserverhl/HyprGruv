#!/usr/bin/env bash
# git-eod.sh — stage, commit, and push personal repos when you've been slacking
#
# Repos: hyprgruv (~/.hyprgruv), Wallpapers, notes
#
# Usage:
#   git-eod.sh
#   git-eod.sh -m "catch-up"
#   git-eod.sh --dry-run
#   git-eod.sh --only hyprgruv,notes
#   git-eod.sh --no-push

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"

declare -a REPO_NAMES=()
declare -a REPO_PATHS=()

REPO_NAMES+=(hyprgruv Wallpapers notes)
REPO_PATHS+=("$HOME/.hyprgruv" "$HOME/Wallpapers" "$HOME/notes")

COMMIT_MSG=""
DRY_RUN=0
DO_PUSH=1
ONLY_FILTER=""

usage() {
    cat <<'EOF'
EOD git sync — commit and push hyprgruv, Wallpapers, and notes

Options:
  -m, --message MSG   Commit message (default: eod: YYYY-MM-DD)
  --only NAMES        Comma-separated subset: hyprgruv, Wallpapers, notes
  --no-push           Commit locally only
  --dry-run           Show planned actions without changing anything
  -h, --help          Show this help

Examples:
  git-eod.sh
  git-eod.sh -m "theme tweaks + new wallpapers"
  git-eod.sh --only notes --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    -m | --message)
        [[ $# -ge 2 ]] || {
            log_error "Missing value for $1"
            exit 1
        }
        COMMIT_MSG="$2"
        shift 2
        ;;
    --only)
        [[ $# -ge 2 ]] || {
            log_error "Missing value for --only"
            exit 1
        }
        ONLY_FILTER="$2"
        shift 2
        ;;
    --no-push) DO_PUSH=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
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

[[ -n "$COMMIT_MSG" ]] || COMMIT_MSG="eod: $(date +%Y-%m-%d)"

repo_selected() {
    local name="$1"
    [[ -z "$ONLY_FILTER" ]] && return 0
    local item
    IFS=',' read -ra items <<<"$ONLY_FILTER"
    for item in "${items[@]}"; do
        item="${item#"${item%%[![:space:]]*}"}"
        item="${item%"${item##*[![:space:]]}"}"
        [[ "$item" == "$name" ]] && return 0
    done
    return 1
}

repo_has_changes() {
    local path="$1"
    ! git -C "$path" diff --quiet 2>/dev/null ||
        ! git -C "$path" diff --cached --quiet 2>/dev/null ||
        [[ -n "$(git -C "$path" ls-files --others --exclude-standard 2>/dev/null)" ]]
}

change_summary() {
    local path="$1"
    local modified staged untracked
    modified="$(git -C "$path" diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
    staged="$(git -C "$path" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
    untracked="$(git -C "$path" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"
    printf '%s modified, %s staged, %s untracked' "$modified" "$staged" "$untracked"
}

run_cmd() {
    if [[ $DRY_RUN -eq 1 ]]; then
        log_status "[dry-run] $*"
        return 0
    fi
    "$@"
}

sync_repo() {
    local name="$1"
    local path="$2"
    local summary

    if [[ ! -d "$path/.git" ]]; then
        log_warning "Skipping $name — not a git repo: $path"
        return 1
    fi

    if ! repo_has_changes "$path"; then
        log_status "$name — clean, nothing to commit"
        return 0
    fi

    summary="$(change_summary "$path")"
    log_status "$name — $summary"

    run_cmd git -C "$path" add .

    if [[ $DRY_RUN -eq 1 ]]; then
        log_status "[dry-run] git -C $path commit -m '$COMMIT_MSG'"
        if [[ $DO_PUSH -eq 1 ]]; then
            log_status "[dry-run] git -C $path push"
        fi
        return 0
    fi

    if ! git -C "$path" diff --cached --quiet; then
        git -C "$path" commit -m "$COMMIT_MSG"
        log_success "$name — committed"
    else
        log_status "$name — nothing staged after add (ignored files only?)"
        return 0
    fi

    if [[ $DO_PUSH -eq 0 ]]; then
        log_status "$name — push skipped (--no-push)"
        return 0
    fi

    if git -C "$path" rev-parse --abbrev-ref '@{u}' &>/dev/null; then
        if git -C "$path" push; then
            log_success "$name — pushed"
            return 0
        fi
        log_error "$name — push failed"
        return 1
    fi

    if git -C "$path" push origin HEAD; then
        log_success "$name — pushed to origin HEAD (no upstream set)"
        return 0
    fi

    log_error "$name — push failed"
    return 1
}

main() {
    display_header "EOD Git Sync" 2>/dev/null || true
    log_status "Message: $COMMIT_MSG"
    [[ $DO_PUSH -eq 1 ]] || log_status "Push disabled"
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
        if ! sync_repo "$name" "$path"; then
            failures=$((failures + 1))
        fi
    done

    echo ""
    if [[ $failures -eq 0 ]]; then
        log_success "EOD sync finished"
        exit 0
    fi

    log_error "EOD sync finished with $failures failure(s)"
    exit 1
}

main