#!/usr/bin/env bash
# kew_setup.sh — point kew at ~/Music (XDG music dir)
#
# kew stores the library path in ~/.config/kew/kewrc (`path=`).
# `kew path DIR` is the supported CLI; we also write kewrc so first launch
# skips the interactive "is this the correct path?" prompt.
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"

MUSIC_DIR="${XDG_MUSIC_DIR:-$HOME/Music}"
if [[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs" ]]; then
    # shellcheck disable=SC1090
    source "${XDG_CONFIG_HOME:-$HOME/.config}/user-dirs.dirs"
    [[ -n "${XDG_MUSIC_DIR:-}" ]] && MUSIC_DIR="$XDG_MUSIC_DIR"
fi
MUSIC_DIR="${MUSIC_DIR/#\~/$HOME}"
KEW_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/kew"
KEW_RC="$KEW_DIR/kewrc"

if ! declare -F log_status >/dev/null 2>&1; then
    log_status() { echo "  $*"; }
    log_success() { echo "  ✓ $*"; }
fi

mkdir -p "$MUSIC_DIR" "$KEW_DIR"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    xdg-user-dirs-update --set MUSIC "$MUSIC_DIR" >/dev/null 2>&1 || true
fi

if [[ -f "$KEW_RC" ]] && grep -qE '^path=' "$KEW_RC"; then
    sed -i "s|^path=.*|path=${MUSIC_DIR}|" "$KEW_RC"
else
    printf 'path=%s\n' "$MUSIC_DIR" >>"$KEW_RC"
fi

if command -v kew >/dev/null 2>&1; then
    # Persist via kew itself when the binary is already on PATH.
    kew path "$MUSIC_DIR" >/dev/null 2>&1 || true
fi

log_success "kew library path → $MUSIC_DIR"
