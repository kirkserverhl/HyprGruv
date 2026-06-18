#!/bin/bash
# updates.sh — Dual-mode updates helper
#   - "waybar" mode (or non-tty): JSON output for Waybar custom module (always shows count)
#   - Default / tty / "popup" / "status": Pretty terminal popup view with numbers + full package list
#
# The Waybar module execs it as:  ~/.config/hyprgruv/scripts/updates.sh waybar
# You (or the bar on-click) can launch the popup view in a floating terminal:
#   ~/.config/hyprgruv/scripts/terminal.sh --class hypr-updates -e ~/.config/hyprgruv/scripts/updates.sh

set -euo pipefail

# -----------------------------------------------------
# Thresholds (for bar colors)
# -----------------------------------------------------
threshhold_green=0
threshhold_yellow=25
threshhold_red=100

# Resolve platform + helper (supports all the places these files end up)
install_platform="$(cat ~/.config/hyprgruv/scripts/platform.sh 2>/dev/null \
  || cat ~/.config/settings/platform.sh 2>/dev/null \
  || echo arch)"
aur_helper="$(cat ~/.config/hyprgruv/scripts/aur.sh 2>/dev/null \
  || cat ~/.config/settings/aur.sh 2>/dev/null \
  || echo yay)"

# -----------------------------------------------------
# Compute counts (shared by both modes)
# -----------------------------------------------------
updates_arch=0
updates_aur=0
updates_list_arch=""
updates_list_aur=""

case $install_platform in
arch)
    updates_list_arch=$(checkupdates 2>/dev/null || true)
    if [[ -n "$updates_list_arch" ]]; then
        updates_arch=$(echo "$updates_list_arch" | wc -l)
    fi

    updates_list_aur=$($aur_helper -Qu --aur 2>/dev/null || true)
    if [[ -n "$updates_list_aur" ]]; then
        updates_aur=$(echo "$updates_list_aur" | wc -l)
    fi

    updates=$((updates_arch + updates_aur))
    ;;
fedora)
    updates=$(dnf check-update -q 2>/dev/null | grep -c ^[a-z0-9] || echo 0)
    ;;
*)
    updates=0
    ;;
esac

# Color class for the bar pill
css_class="green"
if [ "$updates" -gt $threshhold_yellow ]; then css_class="yellow"; fi
if [ "$updates" -gt $threshhold_red ]; then css_class="red"; fi

# -----------------------------------------------------
# WAYBAR / JSON MODE  (what the module polls)
# Always emits the count so the pill/number is always visible
# -----------------------------------------------------
emit_waybar_json() {
    if [ "$updates" -gt 0 ]; then
        printf '{"text": "󰏖 %s", "alt": "%s", "tooltip": "Left: Backup + Install updates  ⬆️\\nRight: Pacseek 📦️\\nTotal: %s (arch:%s aur:%s)", "class": "%s"}' \
            "$updates" "$updates" "$updates" "$updates_arch" "$updates_aur" "$css_class"
    else
        printf '{"text": "󰏖 0", "alt": "0", "tooltip": "No updates available", "class": "green"}'
    fi
}

# -----------------------------------------------------
# POPUP / PRETTY TERMINAL MODE  (the nice view you launch in floating window)
# -----------------------------------------------------
emit_popup_view() {
    # --- Load your existing helpers for consistent look ---
    source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
    source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
    gum_apply_matugen_theme 2>/dev/null || true

    # Try to use lsd-print if present, otherwise plain echo
    print_line() {
        if command -v lsd-print >/dev/null 2>&1; then
            echo -e "$*" | lsd-print
        else
            echo -e "$*"
        fi
    }

    clear
    print_header "Updates"
    echo

    # Summary line
    if [ "$updates" -gt 0 ]; then
        print_line ":: ${updates} updates available  (official: ${updates_arch}   AUR: ${updates_aur})"
    else
        print_line ":: System is up to date."
    fi
    echo

    if [ "$updates_arch" -gt 0 ]; then
        print_line "== Official repositories (${updates_arch}) =="
        echo "$updates_list_arch" | sed 's/^/  /'
        echo
    fi

    if [ "$updates_aur" -gt 0 ]; then
        print_line "== AUR (${updates_aur}) =="
        echo "$updates_list_aur" | sed 's/^/  /'
        echo
    fi

    echo
    if [ "$updates" -gt 0 ]; then
        print_line "Tip: Left-click the Waybar updates pill or run: installupdates"
    else
        print_line "No action needed."
    fi
    echo
    read -n 1 -s -r -p "Press any key to close..."
    echo
}

# -----------------------------------------------------
# Mode selection
# -----------------------------------------------------
mode="${1:-}"

if [[ "$mode" == "waybar" ]]; then
    emit_waybar_json
elif [[ "$mode" == "popup" || "$mode" == "status" || "$mode" == "pretty" ]]; then
    emit_popup_view
elif [[ -t 1 ]]; then
    # Running interactively in a terminal → pretty popup view
    emit_popup_view
else
    # Non-interactive / captured stdout (Waybar, scripts, etc.) → JSON
    emit_waybar_json
fi
