#!/bin/bash
# Mac Cmd bridge for Hyprland (Super ≈ Cmd).
#
# Why the delay: Super is still held when the bind fires. Injecting keys
# immediately produces Super+c / bare letters (cccccccc / vvvvvv storms) or
# dumps binary clipboard (PNG) into terminals. Wait for Super to be released,
# then send a real Ctrl(+Shift) chord once.
#
# Re-entry: flock so key-repeat cannot stack dozens of injectors.

set -euo pipefail

action="${1:-}"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/mac-shortcut.lock"
DELAY_SEC="${MAC_SHORTCUT_DELAY:-0.12}"

active_json() {
    hyprctl activewindow -j 2>/dev/null || true
}

active_class() {
    active_json | sed -n 's/.*"class"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}

is_terminal() {
    case "$(active_class)" in
        kitty|Alacritty|alacritty|wezterm-gui|foot|org.wezfurlong.wezterm|ghostty|com.mitchellh.ghostty)
            return 0
            ;;
    esac
    return 1
}

# Inject one chord after Super is (hopefully) up. Uses wtype (virtual keyboard).
inject() {
    # Usage: inject ctrl [shift] letter
    local -a down=() up=()
    local k=""
    local arg
    for arg in "$@"; do
        case "$arg" in
            ctrl|control)
                down+=(-M ctrl)
                up+=(-m ctrl)
                ;;
            shift)
                down+=(-M shift)
                up+=(-m shift)
                ;;
            *)
                k="$(printf '%s' "$arg" | tr '[:upper:]' '[:lower:]')"
                ;;
        esac
    done
    if [[ -z "$k" ]]; then
        echo "mac-shortcut: inject missing key" >&2
        return 1
    fi
    if ! command -v wtype >/dev/null 2>&1; then
        # Once per session so Super+C spam doesn't flood notifications.
        local stamp="${XDG_RUNTIME_DIR:-/tmp}/mac-shortcut-wtype-missing"
        if [[ ! -f "$stamp" ]]; then
            touch "$stamp"
            hyprctl notify 3 5000 0 "Mac shortcuts need wtype — run: sudo pacman -S wtype" 2>/dev/null || true
            echo "mac-shortcut: wtype not installed (sudo pacman -S wtype)" >&2
        fi
        return 1
    fi
    # shellcheck disable=SC2086
    wtype "${down[@]}" -k "$k" "${up[@]}"
}

# Terminal copy: prefer highlighted (primary) selection → clipboard.
# Avoids Ctrl+C SIGINT entirely.
term_copy() {
    local data=""
    data="$(wl-paste --primary -n 2>/dev/null || true)"
    if [[ -n "$data" ]]; then
        printf '%s' "$data" | wl-copy -n
        return 0
    fi
    # No primary selection — try terminal copy chord (Ctrl+Shift+C).
    inject ctrl shift c
}

# Terminal paste: text only (never image/PNG dump into the TTY).
term_paste() {
    # Prefer a real terminal paste chord (handles multiline, bracketed paste).
    if wl-paste -l 2>/dev/null | grep -Eqi 'text/plain|TEXT|STRING|UTF8_STRING'; then
        inject ctrl shift v
        return 0
    fi
    # Clipboard is image-only or empty — do nothing rather than dump binary.
    return 0
}

run_action() {
    sleep "$DELAY_SEC"
    case "$action" in
        copy|c)
            if is_terminal; then
                term_copy
            else
                inject ctrl c
            fi
            ;;
        paste|v)
            if is_terminal; then
                term_paste
            else
                inject ctrl v
            fi
            ;;
        cut|x)
            inject ctrl x
            ;;
        undo|z)
            inject ctrl z
            ;;
        redo)
            inject ctrl shift z
            ;;
        select-all|a)
            inject ctrl a
            ;;
        bold|b)
            inject ctrl b
            ;;
        italic|i)
            inject ctrl i
            ;;
        link|k)
            inject ctrl k
            ;;
        *)
            echo "Unknown mac-shortcut action: $action" >&2
            echo "Known: copy paste cut undo redo select-all bold italic link" >&2
            exit 1
            ;;
    esac
}

# Validate action before backgrounding.
case "$action" in
    copy|c|paste|v|cut|x|undo|z|redo|select-all|a|bold|b|italic|i|link|k) ;;
    *)
        echo "Unknown mac-shortcut action: $action" >&2
        exit 1
        ;;
esac

# Single-flight: ignore stacked key-repeat while a bridge is in progress.
exec 9>"$LOCK"
if ! flock -n 9; then
    exit 0
fi

# Hold the lock in the child until the delayed inject finishes.
(
    flock 9
    run_action
) &
disown 2>/dev/null || true
exit 0
