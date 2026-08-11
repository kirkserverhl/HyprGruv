#!/usr/bin/env bash
# Settings → SSH / GitHub — run install-time ssh_key helper in a floating terminal.
set -euo pipefail

HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
SSH_SCRIPT="$HYPRGRUV_DIR/lib/scripts/ssh_key.sh"
CLASS="dotfiles-floating"

if [[ ! -f "$SSH_SCRIPT" ]]; then
    notify-send "HyprGruv Settings" "Missing: $SSH_SCRIPT" -u critical
    exit 1
fi

cmd=$(cat <<EOF
set -euo pipefail
printf '\e]2;SSH / GitHub Login\a'
bash "$SSH_SCRIPT"
echo
read -rp "Press Enter to close..."
EOF
)

if command -v kitty >/dev/null 2>&1; then
    exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
        kitty --class "$CLASS" \
        --title "SSH / GitHub Login" \
        --override initial_window_width=90c \
        --override initial_window_height=32c \
        -e bash -lc "$cmd"
fi

# Fallback: run in current terminal
bash -lc "$cmd"
