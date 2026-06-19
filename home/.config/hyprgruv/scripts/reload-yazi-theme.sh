#!/usr/bin/env bash
# reload-yazi-theme.sh — refresh ~/.config/yazi/theme.toml and hot-reload open yazis
#
# Yazi 26.5+ supports `app:theme` (no restart). Broadcast with:
#   ya emit-to 0 app:theme
#
# Usage:
#   reload-yazi-theme.sh           regen from cache + reload all instances
#   reload-yazi-theme.sh --regen   write theme.toml only
#   reload-yazi-theme.sh --reload  emit app:theme to running instances only
#   reload-yazi-theme.sh --icons   append gruvbox icons + reload (after matugen template write)

set -euo pipefail

JSON="${HOME}/.cache/matugen/current.json"
THEME="${HOME}/.config/yazi/theme.toml"
ICONS="${HOME}/.config/matugen/templates/yazi-icons-gruvbox.toml"

append_icons() {
    [[ -f "$THEME" ]] || return 1
    [[ -f "$ICONS" ]] || {
        echo "[reload-yazi] Missing icon palette at $ICONS" >&2
        return 1
    }

    # Strip a prior icon block if this runs more than once on the same theme.toml.
    if grep -qE '^(# Gruvbox icon palette|\[icon\])' "$THEME"; then
        sed -i -E '/^(# Gruvbox icon palette|\[icon\])/,$d' "$THEME"
    fi

    printf '\n' >>"$THEME"
    cat "$ICONS" >>"$THEME"
}

regen_theme() {
    [[ -f "$JSON" ]] || {
        echo "[reload-yazi] No cache at $JSON — run matugen first" >&2
        return 0
    }
    command -v matugen >/dev/null 2>&1 || {
        echo "[reload-yazi] matugen not found" >&2
        return 0
    }

    local before after
    before=""
    [[ -f "$THEME" ]] && before=$(stat -c '%Y' "$THEME" 2>/dev/null || echo "")

    # Runs all matugen templates; we only need theme.toml updated.
    matugen json "$JSON" -q --continue-on-error 2>/dev/null || true

    [[ -f "$THEME" ]] || {
        echo "[reload-yazi] theme.toml missing after matugen json" >&2
        return 1
    }

    append_icons

    after=$(stat -c '%Y' "$THEME" 2>/dev/null || echo "")
    if [[ -n "$before" && "$before" == "$after" ]]; then
        touch "$THEME" 2>/dev/null || true
    fi
}

reload_instances() {
    command -v ya >/dev/null 2>&1 || return 0
    # Receiver 0 = all remote yazi instances (DDS broadcast).
    ya emit-to 0 app:theme 2>/dev/null || true
}

case "${1:-}" in
--regen)
    regen_theme
    ;;
--reload)
    reload_instances
    ;;
--icons)
    append_icons
    reload_instances
    ;;
-h | --help)
    sed -n '2,10p' "$0"
    ;;
*)
    # Default: hot-reload open instances only. Full regen from current.json
    # overwrites every matugen template and must be requested explicitly (--regen).
    reload_instances
    ;;
esac