#!/usr/bin/env bash
# git-sync — device follow list + cross-device handoff index
#
# Follow list:
#   git-sync status | list | init | follow | unfollow | local-only | inventory | role
#
# Cross-device handoff log (docs/device-sync/ — committed, shared with other Grok sessions):
#   git-sync handoff "summary…"
#   git-sync handoff -t to-source "laptop → main next steps"
#   git-sync log [-n N]
#   git-sync brief                 # INDEX + LATEST (best for agents)
#   git-sync index                 # rebuild INDEX.md

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/scripts/git-eod-common.sh"

DEVICE_SYNC_DIR="${HYPR_DIR}/docs/device-sync"
DEVICE_SYNC_ENTRIES="${DEVICE_SYNC_DIR}/entries"
DEVICE_SYNC_INDEX="${DEVICE_SYNC_DIR}/INDEX.md"
DEVICE_SYNC_LATEST="${DEVICE_SYNC_DIR}/LATEST.md"
DEVICE_SYNC_SEEN="${GIT_SYNC_STATE_DIR}/last-handoff-seen"

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

# ---------------------------------------------------------------------------
# Cross-device handoff index (docs/device-sync)
# ---------------------------------------------------------------------------
git_sync_host_slug() {
    local h
    h="$(hostname -s 2>/dev/null || hostname 2>/dev/null || echo host)"
    h="${h//[^A-Za-z0-9._-]/_}"
    printf '%s\n' "$h"
}

git_sync_rebuild_index() {
    mkdir -p "$DEVICE_SYNC_ENTRIES"
    local tmp rows=0
    tmp="$(mktemp)"
    {
        cat <<'HDR'
# Device sync index

Auto-generated by `git-sync index` / `git-sync handoff`.  
Newest first. Full protocol: [README.md](README.md).

| When (UTC) | Host | Role | Direction | Summary | File |
|------------|------|------|-----------|---------|------|
HDR
        local f base when host role dir summary
        # Newest first by filename (UTC timestamp prefix)
        while IFS= read -r f; do
            [[ -f "$f" ]] || continue
            [[ "$(basename "$f")" == ".gitkeep" ]] && continue
            base="$(basename "$f")"
            when="$(grep -E '^date:' "$f" 2>/dev/null | head -1 | sed 's/^date:[[:space:]]*//')"
            host="$(grep -E '^host:' "$f" 2>/dev/null | head -1 | sed 's/^host:[[:space:]]*//')"
            role="$(grep -E '^role:' "$f" 2>/dev/null | head -1 | sed 's/^role:[[:space:]]*//')"
            dir="$(grep -E '^direction:' "$f" 2>/dev/null | head -1 | sed 's/^direction:[[:space:]]*//')"
            summary="$(grep -E '^summary:' "$f" 2>/dev/null | head -1 | sed 's/^summary:[[:space:]]*//')"
            [[ -z "$summary" ]] && summary="$(grep -m1 -E '^# ' "$f" 2>/dev/null | sed 's/^# //')"
            summary="${summary//|/\\|}"
            printf '| %s | %s | %s | %s | %s | [%s](entries/%s) |\n' \
                "${when:-?}" "${host:-?}" "${role:-?}" "${dir:-both}" "${summary:-…}" "$base" "$base"
            rows=$((rows + 1))
        done < <(find "$DEVICE_SYNC_ENTRIES" -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' | sort -r)
        if [[ $rows -eq 0 ]]; then
            echo '| _(none yet)_ | | | | run `git-sync handoff` | |'
        fi
        cat <<'FTR'

## How to use (Grok / human)

1. Read **[LATEST.md](LATEST.md)** first.
2. Skim this table for recent context.
3. Open the matching file under `entries/` if you need detail.
4. Pull before editing the same area the other machine just touched.
FTR
    } >"$tmp"
    mv "$tmp" "$DEVICE_SYNC_INDEX"
}

cmd_index() {
    git_sync_rebuild_index
    log_success "Rebuilt $DEVICE_SYNC_INDEX"
}

cmd_handoff() {
    local direction="both"
    local next_steps=""
    local summary=""
    local stage=1

    while [[ $# -gt 0 ]]; do
        case "$1" in
        -t | --to | --direction)
            direction="$2"
            shift 2
            ;;
        --next)
            next_steps="$2"
            shift 2
            ;;
        --no-stage) stage=0; shift ;;
        -h | --help)
            cat <<'EOF'
git-sync handoff [options] "summary of work"

  -t, --direction  to-source | to-deploy | both   (default: both)
  --next "…"       checklist line for the other machine
  --no-stage       write files but do not git add

Examples:
  git-sync handoff "Added machine profile + git-sync"
  git-sync handoff -t to-source "Laptop authored features; main should pull"
  git-sync handoff -t to-deploy --next "git-eod-pull && systemctl --user enable git-eod-remind.timer" "Released on main"
EOF
            return 0
            ;;
        --)
            shift
            break
            ;;
        -*)
            log_error "Unknown option: $1"
            exit 1
            ;;
        *)
            summary="$1"
            shift
            # allow extra words as summary continuation
            while [[ $# -gt 0 && "$1" != -* ]]; do
                summary+=" $1"
                shift
            done
            ;;
        esac
    done

    if [[ -z "$summary" ]]; then
        if command -v gum >/dev/null 2>&1 && [[ -t 0 ]]; then
            summary="$(gum input --placeholder "Handoff summary (what changed + what the other machine should do)")" || true
        fi
    fi
    [[ -n "$summary" ]] || {
        log_error "Usage: git-sync handoff \"summary\""
        exit 1
    }

    case "$direction" in
    to-source | to-deploy | both) ;;
    source) direction=to-source ;;
    deploy | laptop) direction=to-deploy ;;
    main | desktop) direction=to-source ;;
    *)
        log_error "direction must be to-source, to-deploy, or both"
        exit 1
        ;;
    esac

    git_sync_load 2>/dev/null || true
    local role host slug ts_utc ts_local id path git_head branch
    role="${GIT_SYNC_ROLE:-$(git_sync_detect_role)}"
    host="$(hostname -s 2>/dev/null || hostname)"
    slug="$(git_sync_host_slug)"
    ts_utc="$(date -u +%Y-%m-%dT%H%M%SZ)"
    ts_local="$(date -Iseconds)"
    id="${ts_utc}-${slug}"
    path="${DEVICE_SYNC_ENTRIES}/${id}.md"
    git_head="$(git -C "$HYPR_DIR" rev-parse --short HEAD 2>/dev/null || echo unknown)"
    branch="$(git -C "$HYPR_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

    mkdir -p "$DEVICE_SYNC_ENTRIES"

    # Default next-steps by direction
    if [[ -z "$next_steps" ]]; then
        case "$direction" in
        to-source)
            next_steps="On main (source): cd ~/.hyprgruv && git pull && git-sync brief && git-sync init source"
            ;;
        to-deploy)
            next_steps="On laptop (deploy): git-eod-pull && git-sync brief"
            ;;
        both)
            next_steps="Both sides: git pull / git-eod-pull, then git-sync brief before further edits"
            ;;
        esac
    fi

    cat >"$path" <<EOF
---
id: ${id}
date: ${ts_local}
date_utc: ${ts_utc}
host: ${host}
role: ${role}
direction: ${direction}
branch: ${branch}
git_head: ${git_head}
summary: ${summary}
---

# ${summary}

## Context

| Field | Value |
|-------|-------|
| Host | \`${host}\` |
| Role | \`${role}\` |
| Direction | \`${direction}\` |
| Branch | \`${branch}\` @ \`${git_head}\` |
| When | ${ts_local} |

## For the other machine

- [ ] ${next_steps}

## Notes

_(optional — edit this entry before commit if needed)_

## Avoid overlaps

- Pull this handoff before editing the same areas on the other device.
- Device-local state stays in \`~/.local/state/hyprgruv/\` — do not commit it.
EOF

    # LATEST.md is a full copy for agents
    cp -f "$path" "$DEVICE_SYNC_LATEST"
    git_sync_rebuild_index

    # Mark as seen on this machine so pull summary is quiet for our own notes
    mkdir -p "$(dirname "$DEVICE_SYNC_SEEN")"
    printf '%s\n' "$id" >"$DEVICE_SYNC_SEEN"

    if [[ $stage -eq 1 ]] && [[ -d "$HYPR_DIR/.git" ]]; then
        git -C "$HYPR_DIR" add \
            "$path" \
            "$DEVICE_SYNC_LATEST" \
            "$DEVICE_SYNC_INDEX" \
            "$DEVICE_SYNC_DIR/README.md" 2>/dev/null || true
        log_status "Staged handoff under docs/device-sync/ (commit with your next push)"
    fi

    log_success "Handoff written: $path"
    log_status "Direction: $direction · Open LATEST.md on the other machine after pull"
    echo ""
    echo "Next: commit + push hyprgruv, then on the other device:"
    echo "  git pull   # or git-eod-pull"
    echo "  git-sync brief"
}

cmd_log() {
    local n=10
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -n)
            n="$2"
            shift 2
            ;;
        *) shift ;;
        esac
    done
    mkdir -p "$DEVICE_SYNC_ENTRIES"
    local f count=0
    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        [[ "$(basename "$f")" == ".gitkeep" ]] && continue
        count=$((count + 1))
        [[ $count -gt $n ]] && break
        echo "────────────────────────────────────────"
        # show front matter + first heading
        head -n 40 "$f"
        echo ""
    done < <(find "$DEVICE_SYNC_ENTRIES" -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' | sort -r)

    if [[ $count -eq 0 ]]; then
        log_status "No handoffs yet. Create one: git-sync handoff \"…\""
    fi
}

cmd_brief() {
    echo "=== git-sync brief (cross-device) ==="
    if [[ -f "$DEVICE_SYNC_LATEST" ]]; then
        cat "$DEVICE_SYNC_LATEST"
    else
        log_status "No LATEST.md yet"
    fi
    echo ""
    echo "=== INDEX (recent) ==="
    if [[ -f "$DEVICE_SYNC_INDEX" ]]; then
        # table only
        sed -n '1,25p' "$DEVICE_SYNC_INDEX"
    fi
    # Update seen marker to newest entry
    local newest
    newest="$(find "$DEVICE_SYNC_ENTRIES" -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' | sort -r | head -1 || true)"
    if [[ -n "$newest" ]]; then
        mkdir -p "$(dirname "$DEVICE_SYNC_SEEN")"
        basename "$newest" .md >"$DEVICE_SYNC_SEEN" 2>/dev/null || true
        # basename .md might leave wrong if pattern - use sed
        printf '%s\n' "$(basename "$newest" .md)" >"$DEVICE_SYNC_SEEN"
    fi
}

# Print handoffs newer than last-seen (for post-pull summary).
# Entry ids are UTC timestamps in the filename → lexicographic sort = time sort.
git_sync_print_unread_handoffs() {
    mkdir -p "$DEVICE_SYNC_ENTRIES"
    local seen="" f id any=0 newest_id=""
    [[ -f "$DEVICE_SYNC_SEEN" ]] && seen="$(tr -d '[:space:]' <"$DEVICE_SYNC_SEEN")"

    while IFS= read -r f; do
        [[ -f "$f" ]] || continue
        id="$(basename "$f" .md)"
        if [[ -n "$seen" && "$id" == "$seen" ]]; then
            break
        fi
        if [[ -n "$seen" && "$id" < "$seen" ]]; then
            break
        fi
        any=1
        [[ -z "$newest_id" ]] && newest_id="$id"
        local sum dir host
        sum="$(grep -E '^summary:' "$f" 2>/dev/null | head -1 | sed 's/^summary:[[:space:]]*//')"
        dir="$(grep -E '^direction:' "$f" 2>/dev/null | head -1 | sed 's/^direction:[[:space:]]*//')"
        host="$(grep -E '^host:' "$f" 2>/dev/null | head -1 | sed 's/^host:[[:space:]]*//')"
        printf '  • [%s] %s — %s\n' "${dir:-both}" "${host:-?}" "${sum:-$id}"
    done < <(find "$DEVICE_SYNC_ENTRIES" -maxdepth 1 -type f -name '*.md' ! -name '.gitkeep' | sort -r)

    if [[ $any -eq 0 ]]; then
        return 1
    fi
    if [[ -n "$newest_id" ]]; then
        mkdir -p "$(dirname "$DEVICE_SYNC_SEEN")"
        printf '%s\n' "$newest_id" >"$DEVICE_SYNC_SEEN"
    fi
    return 0
}

cmd_unread() {
    echo "Unread handoffs since last brief/pull on this machine:"
    if ! git_sync_print_unread_handoffs; then
        log_status "None (or already reviewed). Run: git-sync brief"
    else
        log_status "Details: git-sync brief"
    fi
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
handoff | note) cmd_handoff "$@" ;;
log) cmd_log "$@" ;;
brief) cmd_brief ;;
index) cmd_index ;;
unread) cmd_unread ;;
-h | --help | help) usage ;;
*)
    log_error "Unknown command: $cmd"
    usage
    exit 1
    ;;
esac

