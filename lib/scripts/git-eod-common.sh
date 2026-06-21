#!/usr/bin/env bash
# Shared repo list + change detection for git-eod tooling.

GIT_EOD_REPO_NAMES=(hyprgruv Wallpapers notes)
GIT_EOD_REPO_PATHS=("$HOME/.hyprgruv" "$HOME/Wallpapers" "$HOME/notes")

git_eod_repo_has_changes() {
    local path="$1"
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

git_eod_dirty_repo_lines() {
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