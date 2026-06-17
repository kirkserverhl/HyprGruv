#!/usr/bin/env bash
# Run HyprGruv install modules 03-setup + 04-config in a floating terminal.
set -euo pipefail

HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
MODULE_03="$HYPRGRUV_DIR/modules/03-setup.sh"
MODULE_04="$HYPRGRUV_DIR/modules/04-config.sh"
CLASS="dotfiles-floating"

for mod in "$MODULE_03" "$MODULE_04"; do
    [[ -f "$mod" ]] || {
        notify-send "HyprGruv Settings" "Missing: $mod"
        exit 1
    }
done

cmd=$(cat <<EOF
set -euo pipefail
printf '\e]2;HyprGruv Setup\a'
echo "Running HyprGruv modules 03-setup + 04-config..."
echo
bash "$MODULE_03"
echo
bash "$MODULE_04"
echo
echo "Done."
read -rp "Press Enter to close..."
EOF
)

exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
    kitty --class "$CLASS" \
    --title "HyprGruv Setup" \
    --override initial_window_width=90c \
    --override initial_window_height=32c \
    -e bash -lc "$cmd"