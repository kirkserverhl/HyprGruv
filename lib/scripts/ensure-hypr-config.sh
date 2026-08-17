#!/usr/bin/env bash
# ensure-hypr-config.sh — keep ~/.config/hypr as the full Hyprland tree
#
# Theme writers (write_hypr, leftover matugen, apply-desktop-assets, seed)
# must not mkdir a shadow ~/.config/hypr that only has colors/hyprlock.
# That hides hyprland.lua and makes `hyprctl reload` fail with
# "cannot open …/hypr/hyprland.lua".
#
# If the live path is missing hyprland.lua and the repo has it, replace the
# fragment dir with a symlink to the repo package (same as stow).

set -euo pipefail

HYPR_DIR="${HYPR_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
LIVE="${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
REPO="$HYPR_DIR/home/.config/hypr"

hypr_ok() {
    [[ -f "$1/hyprland.lua" ]]
}

if hypr_ok "$LIVE"; then
    exit 0
fi

if ! hypr_ok "$REPO"; then
    echo "ensure-hypr-config: no hyprland.lua in $LIVE or $REPO" >&2
    exit 1
fi

# Preserve generated fragments written into a shadow tree.
stash=""
if [[ -d "$LIVE" && ! -L "$LIVE" ]]; then
    stash="$(mktemp -d "${TMPDIR:-/tmp}/hypr-shadow.XXXXXX")"
    for rel in \
        colors/custom/matugen.conf \
        hyprlock/colors/matugen.conf \
        hyprlock/wallpaper \
        conf/cursor.conf
    do
        [[ -e "$LIVE/$rel" ]] || continue
        mkdir -p "$stash/$(dirname "$rel")"
        cp -a "$LIVE/$rel" "$stash/$rel"
    done
    rm -rf "$LIVE"
elif [[ -L "$LIVE" ]]; then
    rm -f "$LIVE"
fi

mkdir -p "$(dirname "$LIVE")"
ln -sfn "$REPO" "$LIVE"

if [[ -n "$stash" && -d "$stash" ]]; then
    for rel in \
        colors/custom/matugen.conf \
        hyprlock/colors/matugen.conf \
        hyprlock/wallpaper \
        conf/cursor.conf
    do
        [[ -e "$stash/$rel" ]] || continue
        mkdir -p "$(dirname "$LIVE/$rel")"
        if [[ -L "$stash/$rel" ]]; then
            ln -sfn "$(readlink -f "$stash/$rel" 2>/dev/null || readlink "$stash/$rel")" "$LIVE/$rel" 2>/dev/null \
                || cp -a "$stash/$rel" "$LIVE/$rel"
        else
            cp -a "$stash/$rel" "$LIVE/$rel"
        fi
    done
    rm -rf "$stash"
fi

if hypr_ok "$LIVE"; then
    echo "ensure-hypr-config: restored $LIVE -> $REPO"
    exit 0
fi

echo "ensure-hypr-config: restore failed ($LIVE still missing hyprland.lua)" >&2
exit 1
