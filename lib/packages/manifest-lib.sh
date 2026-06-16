#!/usr/bin/env bash
# manifest-lib.sh — read/write hyprgruv package list files

set -euo pipefail

MANIFEST_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

manifest_list_file() {
    local section="${1,,}"
    case "$section" in
    pacman | official) echo "$MANIFEST_LIB_DIR/pacman.list" ;;
    aur | yay) echo "$MANIFEST_LIB_DIR/aur.list" ;;
    new | staging) echo "$MANIFEST_LIB_DIR/new.list" ;;
    *)
        echo "[ERROR] Unknown section: $section (use pacman, aur, or new)" >&2
        return 1
        ;;
    esac
}

manifest_read_list() {
    local file="$1"
    local line
    [[ -f "$file" ]] || return 0
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line// /}"
        [[ -n "$line" ]] && printf '%s\n' "$line"
    done <"$file"
}

manifest_find_section() {
    local pkg="$1"
    local section file
    for section in pacman aur new; do
        file="$(manifest_list_file "$section")"
        if manifest_read_list "$file" | grep -Fxq "$pkg"; then
            echo "$section"
            return 0
        fi
    done
    return 1
}

manifest_add_package() {
    local section="$1"
    shift
    local pkg file existing
    file="$(manifest_list_file "$section")"
    touch "$file"
    mapfile -t existing < <(manifest_read_list "$file")

    for pkg in "$@"; do
        pkg="${pkg// /}"
        [[ -n "$pkg" ]] || continue
        if [[ ! "$pkg" =~ ^[a-zA-Z0-9@._+-]+$ ]]; then
            echo "[ERROR] Invalid package name: $pkg" >&2
            return 1
        fi
        if current="$(manifest_find_section "$pkg" 2>/dev/null)"; then
            if [[ "$current" == "$section" ]]; then
                echo "[INFO] $pkg already in $section"
            else
                echo "[ERROR] $pkg already listed in $current (remove or promote first)" >&2
                return 1
            fi
            continue
        fi
        existing+=("$pkg")
        echo "[SUCCESS] Added $pkg → $section"
    done

    {
        echo "# Hyprgruv ${section} packages — one per line"
        echo "# Lines starting with # are ignored."
        echo ""
        printf '%s\n' "${existing[@]}" | sort -u
    } >"$file"
}

manifest_remove_package() {
    local section="$1"
    local pkg="$2"
    local file
    file="$(manifest_list_file "$section")"
    [[ -f "$file" ]] || return 1

    local -a kept=()
    local line found=0
    while IFS= read -r line || [[ -n "$line" ]]; do
        local bare="${line%%#*}"
        bare="${bare// /}"
        if [[ "$bare" == "$pkg" ]]; then
            found=1
            continue
        fi
        [[ -n "$line" ]] && kept+=("$line")
    done <"$file"

    if [[ $found -eq 0 ]]; then
        echo "[ERROR] $pkg not found in $section" >&2
        return 1
    fi

    printf '%s\n' "${kept[@]}" >"$file"
    echo "[SUCCESS] Removed $pkg from $section"
}

manifest_promote_package() {
    local pkg="$1"
    local dest="$2"
    local current
    current="$(manifest_find_section "$pkg")" || {
        echo "[ERROR] $pkg is not in any list" >&2
        return 1
    }
    if [[ "$current" == "$dest" ]]; then
        echo "[INFO] $pkg is already in $dest"
        return 0
    fi
    manifest_remove_package "$current" "$pkg"
    manifest_add_package "$dest" "$pkg"
    echo "[SUCCESS] Promoted $pkg: $current → $dest"
}

manifest_summary() {
    local section file count
    for section in pacman aur new; do
        file="$(manifest_list_file "$section")"
        count="$(manifest_read_list "$file" | wc -l)"
        printf '%-8s %3s  %s\n' "$section:" "$count" "$file"
    done
}