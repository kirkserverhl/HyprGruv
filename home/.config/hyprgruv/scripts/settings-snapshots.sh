#!/usr/bin/env bash
# Settings → Snapshots — run install-time snapshot wizard in a floating terminal.
set -euo pipefail

HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
SNAP_SCRIPT="$HYPRGRUV_DIR/lib/scripts/snapshots.sh"
CLASS="dotfiles-floating"

if [[ ! -f "$SNAP_SCRIPT" ]]; then
    notify-send "HyprGruv Settings" "Missing: $SNAP_SCRIPT" -u critical
    exit 1
fi

cmd=$(cat <<EOF
set -euo pipefail
printf '\e]2;Snapshots\a'
bash "$SNAP_SCRIPT"
echo
read -rp "Press Enter to close..."
EOF
)

if command -v kitty >/dev/null 2>&1; then
    exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
        kitty --class "$CLASS" \
        --title "Snapshots" \
        --override initial_window_width=90c \
        --override initial_window_height=32c \
        -e bash -lc "$cmd"
fi

bash -lc "$cmd"
