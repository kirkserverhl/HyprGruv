#!/usr/bin/env bash
# reload-yazi-theme.sh — refresh ~/.config/yazi/theme.toml and hot-reload open yazis
#
# Yazi 26.5+ supports `app:theme` (no restart). Broadcast with:
#   ya emit-to 0 app:theme
#
# Icon source (~/.cache/matugen/yazi-icon-mode):
#   matugen       — wallpaper-driven palette (waypaper / image matugen)
#   preset:<name> — static theme icons (e.g. preset:gruvbox-dark)
#
# Usage:
#   reload-yazi-theme.sh              hot-reload running instances only
#   reload-yazi-theme.sh --regen      rewrite theme.toml from current.json + icons
#   reload-yazi-theme.sh --reload     emit app:theme only
#   reload-yazi-theme.sh --icons      append icons for current mode + reload

set -euo pipefail

JSON="${HOME}/.cache/matugen/current.json"
THEME="${HOME}/.config/yazi/theme.toml"
YAZI_CONFIG="${HOME}/.config/matugen/yazi-only.toml"
ICON_MODE_FILE="${HOME}/.cache/matugen/yazi-icon-mode"
ICON_CACHE="${HOME}/.cache/matugen/yazi-icons-matugen.toml"
TEMPLATES="${HOME}/.config/matugen/templates"
SCRIPTS="${HOME}/.config/hyprgruv/scripts"
GENERATOR="${SCRIPTS}/generate-yazi-icons-matugen.py"

strip_icon_block() {
    [[ -f "$THEME" ]] || return 0
    if grep -qE '^(# .*icon palette|\[icon\])' "$THEME"; then
        sed -i -E '/^(# .*icon palette|\[icon\])/,$d' "$THEME"
    fi
}

resolve_icon_mode() {
    local mode=""
    if [[ -f "$ICON_MODE_FILE" ]]; then
        mode=$(tr -d '[:space:]' <"$ICON_MODE_FILE")
    fi
    if [[ -z "$mode" ]]; then
        local run_method=""
        if [[ -f "${HOME}/.cache/matugen/pending-run.json" ]]; then
            run_method=$(jq -r '.method // empty' "${HOME}/.cache/matugen/pending-run.json" 2>/dev/null || true)
        fi
        if [[ "$run_method" == "image" ]]; then
            mode="matugen"
        elif [[ -f "${HOME}/.config/colorschemes/.current-theme" ]]; then
            mode="preset:$(tr -d '[:space:]' <"${HOME}/.config/colorschemes/.current-theme")"
        else
            mode="matugen"
        fi
    fi
    printf '%s' "$mode"
}

resolve_icon_palette() {
    local mode="$1"
    local theme_name palette

    case "$mode" in
    matugen | waypaper)
        if [[ ! -f "$JSON" ]]; then
            echo "[reload-yazi] No cache at $JSON — cannot build matugen icons" >&2
            return 1
        fi
        if [[ ! -x "$GENERATOR" ]] && [[ -f "$GENERATOR" ]]; then
            chmod +x "$GENERATOR" 2>/dev/null || true
        fi
        if [[ ! -f "$GENERATOR" ]]; then
            echo "[reload-yazi] Missing $GENERATOR" >&2
            return 1
        fi
        python3 "$GENERATOR" "$JSON" >/dev/null
        ICONS="$ICON_CACHE"
        ;;
    preset:*)
        theme_name="${mode#preset:}"
        palette="$TEMPLATES/yazi-icons-${theme_name}.toml"
        if [[ ! -f "$palette" ]]; then
            case "$theme_name" in
            gruvbox* | *gruvbox*)
                palette="$TEMPLATES/yazi-icons-gruvbox.toml"
                ;;
            *)
                palette=""
                ;;
            esac
        fi
        if [[ -n "$palette" && -f "$palette" ]]; then
            ICONS="$palette"
        else
            echo "[reload-yazi] No static icon palette for $theme_name — using matugen tint" >&2
            python3 "$GENERATOR" "$JSON" >/dev/null 2>/dev/null || return 1
            ICONS="$ICON_CACHE"
        fi
        ;;
    *)
        palette="$TEMPLATES/yazi-icons-${mode}.toml"
        if [[ -f "$palette" ]]; then
            ICONS="$palette"
        else
            python3 "$GENERATOR" "$JSON" >/dev/null 2>/dev/null || return 1
            ICONS="$ICON_CACHE"
        fi
        ;;
    esac

    [[ -f "$ICONS" ]] || {
        echo "[reload-yazi] Icon palette missing at $ICONS" >&2
        return 1
    }
}

append_icons() {
    local mode
    mode=$(resolve_icon_mode)

    [[ -f "$THEME" ]] || return 1
    resolve_icon_palette "$mode" || return 1

    strip_icon_block

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

    # Yazi-only config — never run the full matugen.toml here (would reload waybar, hypr, gtk, etc.).
    matugen json "$JSON" -c "$YAZI_CONFIG" -q --continue-on-error 2>/dev/null || true

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
    sed -n '2,16p' "$0"
    ;;
*)
    reload_instances
    ;;
esac