#!/usr/bin/env bash
# matugen-posthook-starship.sh — bump starship config so the next prompt picks up new colors

set -euo pipefail

STARSHIP_MATUGEN="${HOME}/.config/starship/matugen-rainbow.toml"
STARSHIP_ACTIVE="${HOME}/.config/starship.toml"

[[ -f "$STARSHIP_MATUGEN" ]] || exit 0

touch "$STARSHIP_MATUGEN" 2>/dev/null || true

if [[ -L "$STARSHIP_ACTIVE" ]]; then
    active_target=$(readlink -f "$STARSHIP_ACTIVE" 2>/dev/null || true)
    if [[ "$active_target" == "$STARSHIP_MATUGEN" || "$(basename "$active_target" 2>/dev/null)" == matugen-rainbow.toml ]]; then
        ln -sfn "$STARSHIP_MATUGEN" "$STARSHIP_ACTIVE" 2>/dev/null || true
        touch "$STARSHIP_ACTIVE" 2>/dev/null || true
    fi
elif [[ ! -e "$STARSHIP_ACTIVE" ]]; then
    ln -sfn "$STARSHIP_MATUGEN" "$STARSHIP_ACTIVE" 2>/dev/null || true
fi

# Force an immediate prompt redraw in open shells (starship re-reads config each draw)
if command -v pkill >/dev/null 2>&1; then
    pkill -WINCH -u "$(id -un)" -x zsh 2>/dev/null || true
    pkill -WINCH -u "$(id -un)" -x bash 2>/dev/null || true
fi