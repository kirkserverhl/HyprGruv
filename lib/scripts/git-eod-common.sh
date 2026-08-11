#!/usr/bin/env bash
# Shared catalog + machine config for git-eod / git-eod-pull / git-sync tooling.
#
# Catalog (shared):  $HYPR_DIR/lib/git-sync/catalog.conf
# Machine config:    $XDG_STATE_HOME/hyprgruv/git-sync.conf
# Projects home:     ~/Projects/<name>  (kind=project)

# shellcheck disable=SC2034

: "${HYPR_DIR:=${HYPRGRUV_DIR:-$HOME/.hyprgruv}}"
GIT_SYNC_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
GIT_SYNC_CONF="${GIT_SYNC_CONF:-$GIT_SYNC_STATE_DIR/git-sync.conf}"
GIT_SYNC_CATALOG="${GIT_SYNC_CATALOG:-$HYPR_DIR/lib/git-sync/catalog.conf}"
GIT_SYNC_PROJECTS_HOME="${GIT_SYNC_PROJECTS_HOME:-$HOME/Projects}"

# Filled by git_sync_load
GIT_SYNC_ROLE=""
GIT_EOD_REPO_NAMES=()
GIT_EOD_REPO_PATHS=()
GIT_EOD_REPO_KINDS=()
GIT_SYNC_FOLLOW=()
GIT_SYNC_LOCAL_ONLY=()

# ---------------------------------------------------------------------------
# Path / string helpers
# ---------------------------------------------------------------------------
git_sync_expand_path() {
    local p="$1"
    p="${p//\$HOME/$HOME}"
    p="${p/#\~/$HOME}"
    printf '%s\n' "$p"
}

git_sync_trim() {
    local s="$1"
    s="${s#"${s%%[![:space:]]*}"}"
    s="${s%"${s##*[![:space:]]}"}"
    printf '%s\n' "$s"
}

git_sync_csv_contains() {
    local needle="$1"
    local csv="$2"
    local item
    [[ -z "$csv" ]] && return 1
    IFS=',' read -ra _items <<<"$csv"
    for item in "${_items[@]}"; do
        item="$(git_sync_trim "$item")"
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

git_sync_csv_add() {
    local csv="$1"
    local name="$2"
    if git_sync_csv_contains "$name" "$csv"; then
        printf '%s\n' "$csv"
        return
    fi
    if [[ -z "$csv" ]]; then
        printf '%s\n' "$name"
    else
        printf '%s,%s\n' "$csv" "$name"
    fi
}

git_sync_csv_remove() {
    local csv="$1"
    local name="$2"
    local item out=()
    IFS=',' read -ra _items <<<"$csv"
    for item in "${_items[@]}"; do
        item="$(git_sync_trim "$item")"
        [[ -z "$item" || "$item" == "$name" ]] && continue
        out+=("$item")
    done
    local IFS=','
    printf '%s\n' "${out[*]}"
}

# ---------------------------------------------------------------------------
# Catalog
# ---------------------------------------------------------------------------
# Sets globals for one row: _cat_name _cat_path _cat_kind _cat_def_src _cat_def_dep _cat_desc
git_sync_catalog_parse_line() {
    local line="$1"
    line="${line%%#*}"
    line="$(git_sync_trim "$line")"
    [[ -z "$line" ]] && return 1
    IFS='|' read -r _cat_name _cat_path _cat_kind _cat_def_src _cat_def_dep _cat_desc <<<"$line"
    _cat_name="$(git_sync_trim "${_cat_name:-}")"
    _cat_path="$(git_sync_trim "${_cat_path:-}")"
    _cat_kind="$(git_sync_trim "${_cat_kind:-}")"
    _cat_def_src="$(git_sync_trim "${_cat_def_src:-skip}")"
    _cat_def_dep="$(git_sync_trim "${_cat_def_dep:-skip}")"
    _cat_desc="$(git_sync_trim "${_cat_desc:-}")"
    [[ -n "$_cat_name" && -n "$_cat_path" ]] || return 1
    return 0
}

git_sync_catalog_foreach() {
    local line
    [[ -f "$GIT_SYNC_CATALOG" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        git_sync_catalog_parse_line "$line" || continue
        "$@"
    done <"$GIT_SYNC_CATALOG"
}

git_sync_catalog_get() {
    # usage: git_sync_catalog_get <name> → sets _cat_*
    local want="$1"
    local line
    [[ -f "$GIT_SYNC_CATALOG" ]] || return 1
    while IFS= read -r line || [[ -n "$line" ]]; do
        git_sync_catalog_parse_line "$line" || continue
        if [[ "$_cat_name" == "$want" ]]; then
            return 0
        fi
    done <"$GIT_SYNC_CATALOG"
    return 1
}

git_sync_default_path_for() {
    local name="$1"
    local override_var="PATH_${name}"
    # shellcheck disable=SC2154
    if [[ -n "${!override_var:-}" ]]; then
        git_sync_expand_path "${!override_var}"
        return
    fi
    if git_sync_catalog_get "$name"; then
        git_sync_expand_path "$_cat_path"
        return
    fi
    # Unknown name → assume project under Projects/
    git_sync_expand_path "$GIT_SYNC_PROJECTS_HOME/$name"
}

# ---------------------------------------------------------------------------
# Role detection
# ---------------------------------------------------------------------------
git_sync_detect_role() {
    local machine_file="$GIT_SYNC_STATE_DIR/machine"
    local deploy_a="$GIT_SYNC_STATE_DIR/deploy-target"
    local deploy_b="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/deploy-target"

    if [[ -n "${GIT_SYNC_ROLE_OVERRIDE:-}" ]]; then
        printf '%s\n' "$GIT_SYNC_ROLE_OVERRIDE"
        return
    fi
    if [[ -f "$GIT_SYNC_CONF" ]]; then
        local r
        r="$(grep -E '^ROLE=' "$GIT_SYNC_CONF" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '[:space:]')"
        if [[ "$r" == "source" || "$r" == "deploy" ]]; then
            printf '%s\n' "$r"
            return
        fi
    fi
    if [[ -f "$deploy_a" || -f "$deploy_b" || "${HYPRGRUV_DEPLOY_TARGET:-0}" == "1" ]]; then
        echo deploy
        return
    fi
    if [[ -f "$machine_file" ]]; then
        case "$(tr -d '[:space:]' <"$machine_file")" in
        laptop) echo deploy; return ;;
        desktop) echo source; return ;;
        esac
    fi
    # Hardware guess
    local c
    c="$(hostnamectl 2>/dev/null | awk -F': ' '/Chassis/ {print tolower($2); exit}')"
    case "$c" in
    laptop | convertible | portable | handset) echo deploy; return ;;
    esac
    echo source
}

# ---------------------------------------------------------------------------
# Load machine config + build active repo arrays
# ---------------------------------------------------------------------------
git_sync_conf_get() {
    local key="$1"
    local fallback="${2:-}"
    [[ -f "$GIT_SYNC_CONF" ]] || {
        printf '%s\n' "$fallback"
        return
    }
    local line
    line="$(grep -E "^${key}=" "$GIT_SYNC_CONF" 2>/dev/null | tail -1 || true)"
    if [[ -z "$line" ]]; then
        printf '%s\n' "$fallback"
        return
    fi
    printf '%s\n' "${line#*=}"
}

git_sync_conf_set() {
    local key="$1"
    local value="$2"
    mkdir -p "$(dirname "$GIT_SYNC_CONF")"
    touch "$GIT_SYNC_CONF"
    if grep -qE "^${key}=" "$GIT_SYNC_CONF" 2>/dev/null; then
        # portable-ish in-place replace
        local tmp
        tmp="$(mktemp)"
        awk -v k="$key" -v v="$value" '
            BEGIN { done=0 }
            $0 ~ "^"k"=" { print k"="v; done=1; next }
            { print }
            END { if (!done) print k"="v }
        ' "$GIT_SYNC_CONF" >"$tmp"
        mv "$tmp" "$GIT_SYNC_CONF"
    else
        printf '%s=%s\n' "$key" "$value" >>"$GIT_SYNC_CONF"
    fi
}

git_sync_load() {
    local role follow_csv local_csv name path item

    GIT_SYNC_ROLE="$(git_sync_detect_role)"
    follow_csv="$(git_sync_conf_get FOLLOW "")"
    local_csv="$(git_sync_conf_get LOCAL_ONLY "")"

    # Export PATH_* overrides from conf into environment for default_path_for
    if [[ -f "$GIT_SYNC_CONF" ]]; then
        local line k v
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ "$line" =~ ^PATH_[A-Za-z0-9_]+= ]] || continue
            k="${line%%=*}"
            v="${line#*=}"
            export "$k=$v"
        done <"$GIT_SYNC_CONF"
    fi

    GIT_SYNC_FOLLOW=()
    GIT_SYNC_LOCAL_ONLY=()
    GIT_EOD_REPO_NAMES=()
    GIT_EOD_REPO_PATHS=()
    GIT_EOD_REPO_KINDS=()

    if [[ -n "$local_csv" ]]; then
        IFS=',' read -ra _lo <<<"$local_csv"
        for item in "${_lo[@]}"; do
            item="$(git_sync_trim "$item")"
            [[ -n "$item" ]] && GIT_SYNC_LOCAL_ONLY+=("$item")
        done
    fi

    # If no conf yet, build defaults from catalog for this role
    if [[ -z "$follow_csv" && ! -f "$GIT_SYNC_CONF" ]]; then
        follow_csv="$(git_sync_default_follow_csv "$GIT_SYNC_ROLE")"
    fi

    IFS=',' read -ra _fol <<<"$follow_csv"
    for item in "${_fol[@]}"; do
        name="$(git_sync_trim "$item")"
        [[ -z "$name" ]] && continue
        if git_sync_csv_contains "$name" "$local_csv"; then
            continue
        fi
        GIT_SYNC_FOLLOW+=("$name")
        path="$(git_sync_default_path_for "$name")"
        local kind="project"
        if git_sync_catalog_get "$name"; then
            kind="$_cat_kind"
        fi
        GIT_EOD_REPO_NAMES+=("$name")
        GIT_EOD_REPO_PATHS+=("$path")
        GIT_EOD_REPO_KINDS+=("$kind")
    done
}

git_sync_default_follow_csv() {
    local role="$1"
    local names=()
    _collect() {
        if [[ "$role" == "source" && "$_cat_def_src" == "follow" ]]; then
            names+=("$_cat_name")
        elif [[ "$role" == "deploy" && "$_cat_def_dep" == "follow" ]]; then
            names+=("$_cat_name")
        fi
    }
    git_sync_catalog_foreach _collect
    local IFS=','
    printf '%s\n' "${names[*]}"
}

# Write a fresh machine config for role (does not clobber FOLLOW if conf exists unless force)
git_sync_init_conf() {
    local role="${1:-}"
    local force="${2:-0}"
    role="${role:-$(git_sync_detect_role)}"
    mkdir -p "$GIT_SYNC_STATE_DIR" "$GIT_SYNC_PROJECTS_HOME"

    if [[ -f "$GIT_SYNC_CONF" && "$force" != "1" ]]; then
        git_sync_conf_set ROLE "$role"
        # Ensure FOLLOW exists
        if [[ -z "$(git_sync_conf_get FOLLOW "")" ]]; then
            git_sync_conf_set FOLLOW "$(git_sync_default_follow_csv "$role")"
        fi
        if [[ -z "$(git_sync_conf_get LOCAL_ONLY "")" ]]; then
            git_sync_conf_set LOCAL_ONLY ""
        fi
        return 0
    fi

    cat >"$GIT_SYNC_CONF" <<EOF
# Generated by git-sync init / apply-machine-profile — machine-local (do not commit)
# ROLE=source (push via git-eod) | deploy (pull via git-eod-pull)
# FOLLOW=catalog names this machine syncs
# LOCAL_ONLY=present on disk but never reminded (device-specific)
# PATH_<Name>=override path if not at catalog default
# Projects home: $GIT_SYNC_PROJECTS_HOME

ROLE=$role
FOLLOW=$(git_sync_default_follow_csv "$role")
LOCAL_ONLY=
EOF
}

# ---------------------------------------------------------------------------
# Git status helpers
# ---------------------------------------------------------------------------
git_eod_repo_has_changes() {
    local path="$1"
    [[ -d "$path/.git" ]] || return 1
    ! git -C "$path" diff --quiet 2>/dev/null ||
        ! git -C "$path" diff --cached --quiet 2>/dev/null ||
        [[ -n "$(git -C "$path" ls-files --others --exclude-standard 2>/dev/null)" ]]
}

git_eod_change_summary() {
    local path="$1"
    local modified staged untracked
    modified="$(git -C "$path" diff --name-only 2>/dev/null | wc -l | tr -d ' ')"
    staged="$(git -C "$path" diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')"
    untracked="$(git -C "$path" ls-files --others --exclude-standard 2>/dev/null | wc -l | tr -d ' ')"
    printf '%s modified, %s staged, %s untracked' "$modified" "$staged" "$untracked"
}

git_eod_repo_behind() {
    local path="$1"
    local upstream count
    [[ -d "$path/.git" ]] || return 1
    git -C "$path" fetch --quiet 2>/dev/null || true
    upstream="$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || return 1
    count="$(git -C "$path" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)"
    [[ "${count:-0}" -gt 0 ]]
}

git_eod_behind_summary() {
    local path="$1"
    local upstream count
    upstream="$(git -C "$path" rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null)" || {
        echo "no upstream"
        return
    }
    count="$(git -C "$path" rev-list --count "HEAD..$upstream" 2>/dev/null || echo 0)"
    printf '%s commit(s) behind %s' "$count" "$upstream"
}

git_eod_dirty_repo_lines() {
    git_sync_load
    local i name path summary
    for i in "${!GIT_EOD_REPO_NAMES[@]}"; do
        name="${GIT_EOD_REPO_NAMES[$i]}"
        path="${GIT_EOD_REPO_PATHS[$i]}"
        [[ -d "$path/.git" ]] || continue
        if git_eod_repo_has_changes "$path"; then
            summary="$(git_eod_change_summary "$path")"
            printf '%s (%s)\n' "$name" "$summary"
        fi
    done
}

git_eod_behind_repo_lines() {
    git_sync_load
    local i name path summary
    for i in "${!GIT_EOD_REPO_NAMES[@]}"; do
        name="${GIT_EOD_REPO_NAMES[$i]}"
        path="${GIT_EOD_REPO_PATHS[$i]}"
        [[ -d "$path/.git" ]] || continue
        if git_eod_repo_behind "$path"; then
            summary="$(git_eod_behind_summary "$path")"
            printf '%s (%s)\n' "$name" "$summary"
        fi
    done
}

# Discover unregistered git repos under ~/Projects (for inventory)
git_sync_discover_projects() {
    local d
    [[ -d "$GIT_SYNC_PROJECTS_HOME" ]] || return 0
    find "$GIT_SYNC_PROJECTS_HOME" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | while read -r d; do
        [[ -d "$d/.git" ]] || continue
        printf '%s\n' "$(basename "$d")"
    done
}
