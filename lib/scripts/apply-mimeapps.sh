#!/usr/bin/env bash
# apply-mimeapps.sh — register defaults from mimeapps.list via xdg-mime

apply_mime_default() {
    local mimetype="$1"
    local desktop="$2"

    [[ -n "$mimetype" && -n "$desktop" ]] || return 0

    if xdg-mime default "$desktop" "$mimetype" 2>/dev/null; then
        return 0
    fi

    echo "Warning: could not set $mimetype -> $desktop" >&2
    return 1
}

apply_mimeapps_file() {
    local file="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list}"
    local in_defaults=0
    local line mimetype desktop

    [[ -f "$file" ]] || {
        echo "mimeapps.list not found: $file" >&2
        return 1
    }

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%%#*}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] || continue

        if [[ "$line" == "[Default Applications]" ]]; then
            in_defaults=1
            continue
        fi
        if [[ "$line" == \[*\] ]]; then
            in_defaults=0
            continue
        fi
        ((in_defaults)) || continue
        [[ "$line" == *"="* ]] || continue

        mimetype="${line%%=*}"
        desktop="${line#*=}"
        apply_mime_default "$mimetype" "$desktop" || true
    done <"$file"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    apply_mimeapps_file "${1:-}"
fi