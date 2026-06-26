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
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv-settings"
DISABLE_FILE="$STATE_DIR/welcome-disabled"
SKIP_TOGGLE_FILE="$STATE_DIR/welcome-skip-enabled"
mkdir -p "$STATE_DIR"

WELCOME_MODE=0
START_MENU=""
for arg in "$@"; do
    case "$arg" in
        --welcome) WELCOME_MODE=1 ;;
        styling|settings|system) START_MENU="$arg" ;;
    esac
done
[[ "${HYPRGRUV_SETTINGS_WELCOME:-}" == "1" ]] && WELCOME_MODE=1

welcome_skip_label() {
    if [[ -f "$SKIP_TOGGLE_FILE" ]]; then
        printf '%s' "☑ Don't show welcome on startup"
    else
        printf '%s' "☐ Don't show welcome on startup"
    fi
}

welcome_skip_icon() {
    if [[ -f "$SKIP_TOGGLE_FILE" ]]; then
        printf '%s' "udiskie-checkbox-checked"
    else
        printf '%s' "udiskie-checkbox-unchecked"
    fi
}

welcome_toggle_skip() {
    if [[ -f "$SKIP_TOGGLE_FILE" ]]; then
        rm -f "$SKIP_TOGGLE_FILE"
    else
        touch "$SKIP_TOGGLE_FILE"
    fi
}

welcome_on_exit() {
    if [[ -f "$SKIP_TOGGLE_FILE" ]]; then
        touch "$DISABLE_FILE"
        rm -f "$SKIP_TOGGLE_FILE"
    fi
}

# ---------------------------------------------------------------------------
# Menu helpers (square 2×2 / 3×3 grid via hyprgruv-rofi-grid.sh)
# ---------------------------------------------------------------------------
# shellcheck source=/dev/null
source "$SCRIPT_DIR/hyprgruv-rofi-grid.sh"
export HYPRGRUV_ICONS_DIR="$ICONS_DIR"
export HYPRGRUV_ROFI_CONFIG="$ROFI_CONFIG"

rofi_pick() {
    hyprgruv_rofi_pick "$@"
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
            "Themes switcher|preferences-desktop-theme|themes" \
            "Waypaper|preferences-desktop-wallpaper|waypaper" \
            "Waybar Theme|panel-top-symbolic|waybar" \
            "Back|gtk-go-back-ltr|back")
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
            "Settings|settings-configure|setup" \
            "Blur|blur|blur" \
            "Blitz|flash|blitz" \
            "Hyprsunset|brightnesssettings|hyprsunset" \
            "Back|gtk-go-back-ltr|back")
        [[ -z "${choice:-}" ]] && return 0

        case "$choice" in
            Settings)
                exec "$SCRIPT_DIR/settings-run-setup.sh"
                ;;
            Blur)
                exec "$SCRIPT_DIR/settings-blur.sh"
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
            "Laptop / PC|computer-laptop|laptop" \
            "Packages Sync|package-x-generic|packages" \
            "Updates|software-update|updates" \
            "Cleanup|document-cleanup|cleanup" \
            "Back|gtk-go-back-ltr|back")
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
    local prompt="HyprGruv Settings"
    [[ "$WELCOME_MODE" == "1" ]] && prompt="HyprGruv Settings — Welcome"

    while true; do
        local choice
        local -a entries=(
            "Styling|preferences-desktop-theme|styling"
            "Settings|settings|settings"
            "System|system-run|system"
        )

        if [[ "$WELCOME_MODE" == "1" ]]; then
            entries+=("$(welcome_skip_label)|$(welcome_skip_icon)|welcome_skip")
        fi
        entries+=("Exit|system-log-out|exit")

        choice=$(rofi_pick "$prompt" "${entries[@]}") || return 0
        if [[ -z "${choice:-}" ]]; then
            [[ "$WELCOME_MODE" == "1" ]] && welcome_on_exit
            return 0
        fi

        case "$choice" in
            Styling) menu_styling ;;
            Settings) menu_settings ;;
            System) menu_system ;;
            "☐ Don't show welcome on startup"|"☑ Don't show welcome on startup")
                welcome_toggle_skip
                ;;
            Exit)
                [[ "$WELCOME_MODE" == "1" ]] && welcome_on_exit
                return 0
                ;;
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