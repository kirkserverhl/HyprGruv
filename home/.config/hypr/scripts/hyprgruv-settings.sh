#!/usr/bin/env bash
# HyprGruv Settings — rofi icon menu (wlogout-style scaffold).
#
# Top level: Styling | Settings | System | Exit
# Submenus wire to existing scripts where available; placeholders elsewhere.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv-settings"
if [[ ! -d "$SETTINGS_DIR" ]]; then
    SETTINGS_DIR="$HOME/.hyprgruv/home/.config/hyprgruv-settings"
fi
ICONS_DIR="$SETTINGS_DIR/icons"
ROFI_CONFIG="$HOME/.config/rofi/config-settings.rasi"
HYPRGRUV_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"

START_MENU="${1:-}"

# ---------------------------------------------------------------------------
# Menu helpers
# ---------------------------------------------------------------------------
rofi_pick() {
    local prompt="$1"
    shift
    local input=""
    for entry in "$@"; do
        IFS='|' read -r label icon _ <<< "$entry"
        input+="${label}\0icon\x1f${ICONS_DIR}/${icon}.png\n"
    done
    printf '%b' "$input" | rofi -dmenu -i -show-icons -config "$ROFI_CONFIG" -p "$prompt" 2>/dev/null || true
}

run_bg() {
    local title="$1"
    shift
    if command -v kitty >/dev/null; then
        exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
            kitty --class dotfiles-floating \
            --title "$title" \
            --override initial_window_width=90c \
            --override initial_window_height=28c \
            -e bash -lc "$*; echo; read -rp 'Press Enter to close...'"
    fi
    notify-send "HyprGruv Settings" "Launching: $title"
    bash -lc "$*"
}

# ---------------------------------------------------------------------------
# Submenus
# ---------------------------------------------------------------------------
menu_styling() {
    while true; do
        local choice
        choice=$(rofi_pick "Styling" \
            "Themes switcher|themes|themes" \
            "Waypaper|waypaper|waypaper" \
            "Waybar Theme|waybar|waybar" \
            "Back|back|back")
        [[ -z "${choice:-}" ]] && return 0

        case "$choice" in
            "Themes switcher")
                exec "$HOME/.config/colorschemes/rofi-launcher.sh"
                ;;
            Waypaper)
                exec waypaper
                ;;
            "Waybar Theme")
                exec "$HOME/.local/bin/waybar-layout-switcher"
                ;;
            Back) return 0 ;;
        esac
    done
}

menu_settings() {
    while true; do
        local choice
        choice=$(rofi_pick "Settings" \
            "Settings|setup|setup" \
            "Blitz|blitz|blitz" \
            "Hyprsunset|hyprsunset|hyprsunset" \
            "Back|back|back")
        [[ -z "${choice:-}" ]] && return 0

        case "$choice" in
            Settings)
                exec "$SCRIPT_DIR/settings-run-setup.sh"
                ;;
            Blitz)
                exec "$SCRIPT_DIR/settings-blitz.sh"
                ;;
            Hyprsunset)
                exec "$SCRIPT_DIR/settings-hyprsunset.sh"
                ;;
            Back) return 0 ;;
        esac
    done
}

menu_system() {
    while true; do
        local choice
        choice=$(rofi_pick "System" \
            "Laptop / PC|laptop|laptop" \
            "Packages Sync|packages|packages" \
            "Updates|updates|updates" \
            "Cleanup|cleanup|cleanup" \
            "Back|back|back")
        [[ -z "${choice:-}" ]] && return 0

        case "$choice" in
            "Laptop / PC")
                exec "$SCRIPT_DIR/settings-laptop-pc.sh"
                ;;
            "Packages Sync")
                run_bg "Packages Sync" "bash '$HYPRGRUV_DIR/sync-packages.sh' sync"
                ;;
            Updates)
                exec "$SCRIPT_DIR/installupdates.sh"
                ;;
            Cleanup)
                run_bg "Cleanup" "bash '$HYPRGRUV_DIR/lib/scripts/cleanup.sh'"
                ;;
            Back) return 0 ;;
        esac
    done
}

menu_main() {
    while true; do
        local choice
        choice=$(rofi_pick "HyprGruv Settings" \
            "Styling|styling|styling" \
            "Settings|settings|settings" \
            "System|system|system" \
            "Exit|exit|exit")
        [[ -z "${choice:-}" ]] && return 0

        case "$choice" in
            Styling) menu_styling ;;
            Settings) menu_settings ;;
            System) menu_system ;;
            Exit) return 0 ;;
        esac
    done
}

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
[[ -d "$ICONS_DIR" ]] || bash "$SETTINGS_DIR/generate-icons.sh" 2>/dev/null || true

case "$START_MENU" in
    styling)  menu_styling ;;
    settings) menu_settings ;;
    system)   menu_system ;;
    *)        menu_main ;;
esac