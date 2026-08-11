#!/usr/bin/env bash
# git-sync — manage device-local follow list for reciprocal git-eod tooling
#
# Usage:
#   git-sync status
#   git-sync list                 # catalog + follow state
#   git-sync init [source|deploy]
#   git-sync follow <name> [...]
#   git-sync unfollow <name> [...]
#   git-sync local-only <name>    # device-specific: no push/pull reminders
#   git-sync shared <name>        # remove from LOCAL_ONLY
#   git-sync inventory            # catalog + ~/Projects discoveries + tips
#   git-sync role [source|deploy]

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"

cmd="${1:-status}"
shift || true

ensure_conf() {
    if [[ ! -f "$GIT_SYNC_CONF" ]]; then
        git_sync_init_conf "$(git_sync_detect_role)" 1
        log_status "Created $GIT_SYNC_CONF"
    fi
}

cmd_init() {
    local role="${1:-}"
    role="${role:-$(git_sync_detect_role)}"
    case "$role" in
    source | deploy) ;;
    *)
        log_error "Role must be source or deploy"
        exit 1
        ;;
    esac
    git_sync_init_conf "$role" 1
    log_success "git-sync init → ROLE=$role"
    log_status "Config: $GIT_SYNC_CONF"
    log_status "FOLLOW=$(git_sync_conf_get FOLLOW)"
    mkdir -p "$GIT_SYNC_PROJECTS_HOME"
}

cmd_role() {
    ensure_conf
    if [[ $# -eq 0 ]]; then
        git_sync_load
        echo "$GIT_SYNC_ROLE"
        return
    fi
    case "$1" in
    source | deploy)
        git_sync_conf_set ROLE "$1"
        log_success "ROLE=$1"
        ;;
    *)
        log_error "Usage: git-sync role [source|deploy]"
        exit 1
        ;;
    esac
}

cmd_follow() {
    ensure_conf
    [[ $# -ge 1 ]] || {
        log_error "Usage: git-sync follow <name> [name...]"
        exit 1
    }
    local follow name path
    follow="$(git_sync_conf_get FOLLOW "")"
    local local_csv
    local_csv="$(git_sync_conf_get LOCAL_ONLY "")"
    for name in "$@"; do
        # Remove from local-only if re-following as shared
        local_csv="$(git_sync_csv_remove "$local_csv" "$name")"
        follow="$(git_sync_csv_add "$follow" "$name")"
        path="$(git_sync_default_path_for "$name")"
        if [[ ! -d "$path/.git" ]]; then
            log_warning "$name — not a git repo yet: $path"
            if git_sync_catalog_get "$name" && [[ "$_cat_kind" == "project" ]]; then
                log_status "Create/clone into: $GIT_SYNC_PROJECTS_HOME/$name"
            fi
        else
            log_status "$name → follow ($path)"
        fi
    done
    git_sync_conf_set FOLLOW "$follow"
    git_sync_conf_set LOCAL_ONLY "$local_csv"
    log_success "FOLLOW=$follow"
}

cmd_unfollow() {
    ensure_conf
    [[ $# -ge 1 ]] || {
        log_error "Usage: git-sync unfollow <name> [name...]"
        exit 1
    }
    local follow name
    follow="$(git_sync_conf_get FOLLOW "")"
    for name in "$@"; do
        follow="$(git_sync_csv_remove "$follow" "$name")"
        log_status "$name → unfollowed"
    done
    git_sync_conf_set FOLLOW "$follow"
    log_success "FOLLOW=$follow"
}

cmd_local_only() {
    ensure_conf
    [[ $# -ge 1 ]] || {
        log_error "Usage: git-sync local-only <name> [name...]"
        exit 1
    }
    local follow local_csv name
    follow="$(git_sync_conf_get FOLLOW "")"
    local_csv="$(git_sync_conf_get LOCAL_ONLY "")"
    for name in "$@"; do
        follow="$(git_sync_csv_remove "$follow" "$name")"
        local_csv="$(git_sync_csv_add "$local_csv" "$name")"
        log_status "$name → LOCAL_ONLY (device-specific, no sync reminders)"
    done
    git_sync_conf_set FOLLOW "$follow"
    git_sync_conf_set LOCAL_ONLY "$local_csv"
    log_success "LOCAL_ONLY=$local_csv"
}

cmd_shared() {
    ensure_conf
    [[ $# -ge 1 ]] || {
        log_error "Usage: git-sync shared <name>  # remove from LOCAL_ONLY"
        exit 1
    }
    local local_csv name
    local_csv="$(git_sync_conf_get LOCAL_ONLY "")"
    for name in "$@"; do
        local_csv="$(git_sync_csv_remove "$local_csv" "$name")"
        log_status "$name → cleared from LOCAL_ONLY (use: git-sync follow $name)"
    done
    git_sync_conf_set LOCAL_ONLY "$local_csv"
}

cmd_list() {
    git_sync_load
    ensure_conf 2>/dev/null || true
    printf 'Role:   %s\n' "$GIT_SYNC_ROLE"
    printf 'Config: %s\n' "$GIT_SYNC_CONF"
    printf 'Projects home: %s\n\n' "$GIT_SYNC_PROJECTS_HOME"
    printf '%-16s %-10s %-8s %-8s %s\n' "NAME" "KIND" "FOLLOW" "LOCAL" "PATH / notes"
    printf '%-16s %-10s %-8s %-8s %s\n' "----" "----" "------" "-----" "-----------"

    _row() {
        local path fmark lmark
        path="$(git_sync_expand_path "$_cat_path")"
        fmark="no"
        lmark="no"
        local i
        for i in "${GIT_SYNC_FOLLOW[@]+"${GIT_SYNC_FOLLOW[@]}"}"; do
            [[ "$i" == "$_cat_name" ]] && fmark="yes"
        done
        for i in "${GIT_SYNC_LOCAL_ONLY[@]+"${GIT_SYNC_LOCAL_ONLY[@]}"}"; do
            [[ "$i" == "$_cat_name" ]] && lmark="yes"
        done
        if [[ ! -d "$path/.git" ]]; then
            path="$path  (missing)"
        fi
        printf '%-16s %-10s %-8s %-8s %s\n' "$_cat_name" "$_cat_kind" "$fmark" "$lmark" "$path"
    }
    git_sync_catalog_foreach _row

    echo ""
    log_status "Followed on this machine: ${GIT_SYNC_FOLLOW[*]:-(none)}"
    log_status "Local-only: ${GIT_SYNC_LOCAL_ONLY[*]:-(none)}"
}

cmd_status() {
    git_sync_load
    ensure_conf 2>/dev/null || true
    local role="$GIT_SYNC_ROLE"
    printf 'git-sync status\n'
    printf '  role:    %s\n' "$role"
    printf '  follow:  %s\n' "${GIT_SYNC_FOLLOW[*]:-(none)}"
    printf '  local:   %s\n' "${GIT_SYNC_LOCAL_ONLY[*]:-(none)}"
    printf '  config:  %s\n\n' "$GIT_SYNC_CONF"

    local i name path
    for i in "${!GIT_EOD_REPO_NAMES[@]}"; do
        name="${GIT_EOD_REPO_NAMES[$i]}"
        path="${GIT_EOD_REPO_PATHS[$i]}"
        if [[ ! -d "$path/.git" ]]; then
            printf '  · %-14s  missing  %s\n' "$name" "$path"
            continue
        fi
        if [[ "$role" == "source" ]]; then
            if git_eod_repo_has_changes "$path"; then
                printf '  · %-14s  dirty    %s\n' "$name" "$(git_eod_change_summary "$path")"
            else
                printf '  · %-14s  clean\n' "$name"
            fi
        else
            if git_eod_repo_behind "$path"; then
                printf '  · %-14s  behind   %s\n' "$name" "$(git_eod_behind_summary "$path")"
            else
                printf '  · %-14s  up-to-date\n' "$name"
            fi
        fi
    done

    echo ""
    if [[ "$role" == "source" ]]; then
        log_status "Daily action: git-eod   (commit + push followed repos)"
    else
        log_status "Daily action: git-eod-pull   (pull followed repos)"
    fi
}

cmd_inventory() {
    git_sync_load
    echo "=== Catalog (shared definitions) ==="
    cmd_list
    echo ""
    echo "=== ~/Projects discoveries ==="
    mkdir -p "$GIT_SYNC_PROJECTS_HOME"
    local found=0 name path in_cat
    while IFS= read -r name; do
        found=1
        path="$GIT_SYNC_PROJECTS_HOME/$name"
        in_cat="custom"
        git_sync_catalog_get "$name" && in_cat="catalog"
        printf '  · %-16s [%s] %s\n' "$name" "$in_cat" "$path"
        if ! git_sync_csv_contains "$name" "$(git_sync_conf_get FOLLOW "")" \
            && ! git_sync_csv_contains "$name" "$(git_sync_conf_get LOCAL_ONLY "")"; then
            log_status "    undecided — run:  git-sync follow $name   OR   git-sync local-only $name"
        fi
    done < <(git_sync_discover_projects)
    if [[ $found -eq 0 ]]; then
        echo "  (empty — clone shared projects into $GIT_SYNC_PROJECTS_HOME/<name>)"
    fi

    echo ""
    echo "=== Likely move candidates (not under Projects yet) ==="
    local cand
    for cand in \
        "$HOME/Wallpapers" \
        "$HOME/notes" \
        "$HOME/soundsbored" \
        "$HOME/code" \
        "$HOME/dev" \
        "$HOME/src"; do
        if [[ -d "$cand/.git" ]]; then
            printf '  · git repo outside Projects: %s\n' "$cand"
            log_status "    consider: mv → $GIT_SYNC_PROJECTS_HOME/$(basename "$cand")  (if it is a project)"
        elif [[ -d "$cand" ]]; then
            printf '  · directory (no .git): %s\n' "$cand"
        fi
    done
    if [[ -d "$HOME/Pictures/Wallpapers" && ! -d "$HOME/Wallpapers/.git" ]]; then
        echo "  · $HOME/Pictures/Wallpapers — local wallpaper tree (not the optional Wallpapers git follow)"
    fi

    echo ""
    cat <<EOF
Decision guide
  shared (FOLLOW)     — push from source desktop, pull on deploy laptops
  local-only          — exists on this device only; no EOD reminders
  skip (unfollowed)   — catalog knows it; this machine ignores it (e.g. laptop without Wallpapers)

Add a new shared project
  1. Desktop:  mkdir -p ~/Projects && git clone <url> ~/Projects/<name>
  2. Catalog:  add a line to lib/git-sync/catalog.conf  (kind=project, default_deploy=skip)
  3. Desktop:  git-sync follow <name>
  4. Laptop:   git-sync follow <name>   # only if you want it here
EOF
}

usage() {
    sed -n '2,20p' "$0" | sed 's/^# \?//'
}

case "$cmd" in
init) cmd_init "$@" ;;
role) cmd_role "$@" ;;
follow) cmd_follow "$@" ;;
unfollow) cmd_unfollow "$@" ;;
local-only | local) cmd_local_only "$@" ;;
shared) cmd_shared "$@" ;;
list) cmd_list ;;
status) cmd_status ;;
inventory | inv) cmd_inventory ;;
-h | --help | help) usage ;;
*)
    log_error "Unknown command: $cmd"
    usage
    exit 1
    ;;
esac
