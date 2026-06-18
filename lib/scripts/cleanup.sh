#!/bin/bash

# Load common functions from the installer tree (robust for the canonical ~/.hyprgruv location or any clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

display_header "Cleanup"

gum_apply_matugen_theme
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
###########
RESET="\e[0m"                # Reset  ##
GREEN="\e[38;2;142;192;124m" # 8ec07c ##  **Notes
CYAN="\e[38;2;69;133;136m"   # 458588 ##
YELLOW="\e[38;2;215;153;33m" # d79921 ##
RED="\e[38;2;204;36;29m"     # cc241d ##
GRAY="\e[38;2;60;56;54m"     # 3c3836 ##
BOLD="\e[1m"                 # Bold   ##

sleep 1

# Prefer user's aur helper script if present in the tree, else default to yay
AUR_SCRIPT="${REPO_DOTFILES_SCRIPTS:-$HYPR_DIR/home/.config/hyprgruv/scripts}/aur.sh"
if [[ ! -f "$AUR_SCRIPT" ]]; then
    AUR_SCRIPT="${DOTFILES_SCRIPTS:-$HOME/.config/hyprgruv/scripts}/aur.sh"
fi
if [[ -f "$AUR_SCRIPT" ]]; then
    aur_helper="$(cat "$AUR_SCRIPT" | tr -d ' \t\r\n')"
else
    aur_helper="yay"
fi
[[ -z "$aur_helper" ]] && aur_helper="yay"

echo ""

# Safe cleanup: cache only by default. Orphan removal is commented for safety.
if command -v "$aur_helper" >/dev/null 2>&1; then
    log_status "Cleaning $aur_helper cache..."
    "$aur_helper" -Scc || true
else
    log_warning "AUR helper '$aur_helper' not found, skipping cache clean."
fi

# Orphan removal is powerful and can remove things you want. Uncomment only if desired.
# log_status "Removing orphaned packages (review the list!)"
# ORPHANS=$(pacman -Qdtq || true)
# if [[ -n "$ORPHANS" ]]; then
#     echo "Orphans found: $ORPHANS"
#     if command -v gum >/dev/null 2>&1; then
#         gum confirm "Remove orphans with pacman -Rsn?" && sudo pacman -Rsn $ORPHANS || true
#     else
#         read -rp "Remove orphans? [y/N]: " ans
#         [[ "${ans,,}" =~ ^y ]] && sudo pacman -Rsn $ORPHANS || true
#     fi
# fi

duf -theme ansi || df -h
sleep 2
clear
