#!/usr/bin/env bash
# Settings → Default Apps — re-run install module 05-setup_defaults.sh
# (terminal, browser, editor + MIME / xdg default handlers) in a floating terminal.
set -euo pipefail

HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
MODULE="$HYPRGRUV_DIR/modules/05-setup_defaults.sh"
CLASS="dotfiles-floating"

if [[ ! -f "$MODULE" ]]; then
    notify-send "HyprGruv Settings" "Missing: $MODULE" -u critical
    exit 1
fi

cmd=$(cat <<EOF
set -euo pipefail
printf '\e]2;Default Applications\a'
echo "Re-running HyprGruv default applications picker..."
echo "Choose terminal, browser, and editor. Missing apps can be installed."
echo
bash "$MODULE"
echo
read -rp "Press Enter to close..."
EOF
)

if command -v kitty >/dev/null 2>&1; then
    exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
        kitty --class "$CLASS" \
        --title "Default Applications" \
        --override initial_window_width=90c \
        --override initial_window_height=32c \
        -e bash -lc "$cmd"
fi

# Fallback: run in current terminal
bash -lc "$cmd"
