#!/usr/bin/env bash
# unlockroot.sh — open root unlock TUI in a properly sized floating window

# Use the standard floating class used by all other popout tools in this config
# (htop.sh, bpytop.sh, networkmanager.sh, yazi.sh, etc.)
CLASS="dotfiles-floating"

# Strip noisy GTK env vars (same pattern as other launchers)
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

# If we're not already inside the dedicated kitty instance, re-launch ourselves
# in a floating window using the standard class. Hyprland windowrules will then
# handle float + center + a generous size that fits the actual content width.
if [[ -z "${UNLOCKROOT_INSIDE:-}" ]]; then
    export UNLOCKROOT_INSIDE=1
    # Add --hold here temporarily if you want the window to stay open on error:
    # exec "${CLEAN_ENV[@]}" kitty --hold --class "$CLASS" --title "Root Unlock" "$0" "$@"
    exec "${CLEAN_ENV[@]}" kitty --class "$CLASS" --title "Root Unlock" "$0" "$@"
fi

# ====================== Main Script ======================

# Do NOT use set -euo pipefail here — many of the gum / faillock / journalctl
# commands legitimately return non-zero in normal operation and would kill the TUI.

# Basic sanity check so we get a visible error instead of silent death
if ! command -v gum >/dev/null 2>&1; then
    echo "ERROR: 'gum' is not installed (required for this TUI)."
    echo "Install it (e.g. paru -S gum or pacman -S gum) then try again."
    read -r -p "Press Enter to close..."
    exit 1
fi

source ~/.hyprgruv/lib/common.sh

display_header "ROOT UNLOCK"

print_section "Checking faillock status..."

print_section "Recent Failures:"
FAILLOCK_OUTPUT=$(faillock --user root 2>&1 || echo "Permission needed for full details")
print_box "$FAILLOCK_OUTPUT"

echo ""

print_section "Latest Authentication Issues:"
LOGS=$(journalctl -xe -g "pam_unix" -g faillock --since "4 hours ago" --no-pager | tail -n 35)
print_box "$LOGS"

echo ""

print_section "What would you like to do?"

ACTION=$(gum choose --height 5 \
    "✅  Unlock Root Now" \
    "🔄  Refresh Status" \
    "📜  View Full Logs" \
    "❌  Cancel")

case "$ACTION" in
    "✅  Unlock Root Now")
        echo ""
        gum style --foreground "$COLOR_PRIMARY" "Enter your password once to unlock root..."
        if sudo faillock --reset --user root; then
            show_success "Root account successfully unlocked!"
        else
            show_error "Unlock failed. Wrong password?"
        fi
        ;;

    "🔄  Refresh Status")
        exec "$0"
        ;;

    "📜  View Full Logs")
        journalctl -xe -g "pam_unix" -g faillock --since "6 hours ago" --no-pager | \
            gum pager --border rounded --border-foreground "$COLOR_PRIMARY"
        exec "$0"
        ;;

    "❌  Cancel")
        show_error "Operation cancelled."
        exit 0
        ;;
esac

echo ""
gum style --foreground "$COLOR_TEXT" --bold "Done. You can close this window."
sleep 2
