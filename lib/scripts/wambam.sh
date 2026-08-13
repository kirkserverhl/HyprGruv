#!/usr/bin/env bash
# wambam.sh — end-of-day slam: updates → role-aware git sync → cleanup
#
# Same command on every machine. The git step follows ROLE from
# ~/.local/state/hyprgruv/git-sync.conf (see git_sync_detect_role):
#   source (desktop) → git-eod        (commit + push)
#   deploy (laptop)  → git-eod-pull   (fetch + pull)
#
# Usage:
#   wambam
#   wambam --dry-run
#   wambam --skip-updates
#   wambam --skip-cleanup
#   wambam --yes                  # skip cleanup confirm
#   wambam -m "catch-up"          # forwarded to git-eod
#   wambam --hyprgruv-full        # forwarded to git-eod-pull
#   wambam --only hyprgruv        # forwarded to git-eod / git-eod-pull

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"

DRY_RUN=0
SKIP_UPDATES=0
SKIP_CLEANUP=0
CLEANUP_YES=0
GIT_ARGS=()

usage() {
    cat <<'EOF'
wambam — updates → git-eod / git-eod-pull → cleanup

The git command is chosen from this machine's ROLE (source vs deploy).

Options:
  --dry-run         Skip updates; pass --dry-run to git + cleanup
  --skip-updates    Skip the package update step
  --skip-cleanup    Skip cleanup
  --yes, -y         Skip cleanup confirmation
  -h, --help        This help

Anything else is forwarded to git-eod (source) or git-eod-pull (deploy):
  -m, --message MSG
  --only NAMES
  --hyprgruv-full
  --no-push
  --force
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --skip-updates) SKIP_UPDATES=1; shift ;;
    --skip-cleanup) SKIP_CLEANUP=1; shift ;;
    --yes | -y) CLEANUP_YES=1; shift ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        GIT_ARGS+=("$1")
        shift
        ;;
    esac
done

if [[ ! -f "$GIT_SYNC_CONF" ]]; then
    git_sync_init_conf "$(git_sync_detect_role)" 1
fi
git_sync_load

ROLE="$GIT_SYNC_ROLE"
case "$ROLE" in
source)
    GIT_LABEL="git-eod"
    GIT_SCRIPT="$HYPR_DIR/lib/scripts/git-eod.sh"
    ;;
deploy)
    GIT_LABEL="git-eod-pull"
    GIT_SCRIPT="$HYPR_DIR/lib/scripts/git-eod-pull.sh"
    ;;
*)
    log_error "Unknown ROLE=$ROLE (expected source or deploy)"
    log_status "Fix with: git-sync role source   or   git-sync role deploy"
    exit 2
    ;;
esac

UPDATES_SCRIPT="${DOTFILES_SCRIPTS:-$HOME/.config/hyprgruv/scripts}/installupdates.sh"
CLEANUP_SCRIPT="$HYPR_DIR/lib/scripts/cleanup.sh"

run_step() {
    local label="$1"
    shift
    echo ""
    log_status "── $label ──"
    if [[ $DRY_RUN -eq 1 && "$label" == "updates" ]]; then
        log_status "[dry-run] skip updates (installupdates.sh has no dry-run)"
        return 0
    fi
    "$@"
}

display_header "wambam" 2>/dev/null || true
log_status "Role: $ROLE → $GIT_LABEL"
log_status "Then: updates → $GIT_LABEL → cleanup"
[[ $DRY_RUN -eq 1 ]] && log_status "Dry run — updates skipped; git + cleanup in dry-run"

if [[ $SKIP_UPDATES -eq 0 ]]; then
    if [[ ! -x "$UPDATES_SCRIPT" && ! -f "$UPDATES_SCRIPT" ]]; then
        log_error "updates script missing: $UPDATES_SCRIPT"
        exit 1
    fi
    run_step "updates" bash "$UPDATES_SCRIPT"
else
    log_status "Skipping updates"
fi

if [[ ! -f "$GIT_SCRIPT" ]]; then
    log_error "Git script missing: $GIT_SCRIPT"
    exit 1
fi
git_cmd=(bash "$GIT_SCRIPT")
[[ $DRY_RUN -eq 1 ]] && git_cmd+=(--dry-run)
if [[ ${#GIT_ARGS[@]} -gt 0 ]]; then
    git_cmd+=("${GIT_ARGS[@]}")
fi
run_step "$GIT_LABEL" "${git_cmd[@]}"

if [[ $SKIP_CLEANUP -eq 0 ]]; then
    if [[ ! -f "$CLEANUP_SCRIPT" ]]; then
        log_error "cleanup script missing: $CLEANUP_SCRIPT"
        exit 1
    fi
    cleanup_cmd=(bash "$CLEANUP_SCRIPT")
    [[ $DRY_RUN -eq 1 ]] && cleanup_cmd+=(--dry-run)
    [[ $CLEANUP_YES -eq 1 ]] && cleanup_cmd+=(--yes)
    run_step "cleanup" "${cleanup_cmd[@]}"
else
    log_status "Skipping cleanup"
fi

echo ""
log_success "wambam finished ($ROLE / $GIT_LABEL)"
