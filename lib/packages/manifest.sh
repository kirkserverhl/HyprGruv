#!/usr/bin/env bash
# Hyprgruv package manifest — single source of truth for cross-device sync
#
# Package lists (one name per line):
#   lib/packages/pacman.list  — confirmed official-repo packages
#   lib/packages/aur.list     — confirmed AUR packages (via yay)
#   lib/packages/new.list     — staging: test here before promoting
#
# Workflow:
#   1. Stage:  bash ~/.hyprgruv/sync-packages.sh add <package>
#   2. Sync:   bash ~/.hyprgruv/sync-packages.sh
#   3. Promote: bash ~/.hyprgruv/sync-packages.sh promote <package> --to pacman|aur
#
# Sync all sections:
#   bash ~/.hyprgruv/sync-packages.sh
#
# Sync only staging:
#   bash ~/.hyprgruv/sync-packages.sh --new-only
#
# Preview:
#   bash ~/.hyprgruv/sync-packages.sh --dry-run

# shellcheck disable=SC2034

MANIFEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_manifest_load_list() {
    local file="$1"
    local -n _out=$2
    _out=()
    [[ -f "$file" ]] || return 0
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line// /}"
        if [[ -n "$line" ]]; then _out+=("$line"); fi
    done <"$file"
}

_manifest_load_list "$MANIFEST_DIR/pacman.list" PACMAN_PKGS
_manifest_load_list "$MANIFEST_DIR/aur.list" AUR_PKGS
_manifest_load_list "$MANIFEST_DIR/new.list" NEW_PKGS