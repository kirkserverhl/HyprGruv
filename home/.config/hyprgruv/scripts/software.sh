#!/usr/bin/env bash
# software.sh — open pacseek in a floating terminal with readable contrast
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLASS="dotfiles-floating"

# Prefix to scrub noisy GTK env vars for this launch only
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

# pacseek hard-codes tcell.ColorWhite and uses bold markup; matugen's muted color15
# makes that text nearly invisible on dark backgrounds (yazi sets input colors explicitly).
kitty_readable_palette() {
    local colors="$HOME/.config/kitty/colors.conf"
    local fg="#eedfe3"

    if [[ -f "$colors" ]]; then
        fg="$(awk '/^foreground[[:space:]]+/ { print $2; exit }' "$colors")"
        fg="${fg:-#eedfe3}"
    fi

    printf '%s\n' \
        "--override" "color7=$fg" \
        "--override" "color15=$fg"
}

TERM_CMD="$("$SCRIPT_DIR/terminal.sh" --print)"

case "$TERM_CMD" in
    kitty)
        mapfile -t _kitty_palette < <(kitty_readable_palette)
        exec "${CLEAN_ENV[@]}" kitty "${_kitty_palette[@]}" --class "$CLASS" -e pacseek
        ;;
    ghostty)
        exec "${CLEAN_ENV[@]}" ghostty --class "$CLASS" --command pacseek
        ;;
    alacritty)
        exec "${CLEAN_ENV[@]}" alacritty --class "$CLASS","$CLASS" -e pacseek
        ;;
    foot|footclient)
        exec "${CLEAN_ENV[@]}" footclient --app-id "$CLASS" pacseek
        ;;
    wezterm)
        exec "${CLEAN_ENV[@]}" wezterm start --class "$CLASS" -- pacseek
        ;;
    gnome-terminal)
        exec "${CLEAN_ENV[@]}" gnome-terminal -- pacseek
        ;;
    *)
        exec "${CLEAN_ENV[@]}" xterm -e pacseek
        ;;
esac