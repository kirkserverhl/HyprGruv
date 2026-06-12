#!/bin/bash
# Main installer for Hyprgruv

# Enable error handling
set -e

# ============================================================
# Setup paths and load helpers
# ============================================================
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

# ============================================================
# Setup logging
# ============================================================
mkdir -p "$ASSET_DIR/logs"
LOGFILE="$ASSET_DIR/logs/install_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$LOGFILE") 2>&1

# ============================================================
# Welcome Screen
# ============================================================
clear
display_header "Hyprgruv"
echo ""
log_status "Welcome to Hyprland Gruvbox Installation!"
log_status "Logs will be saved to: $LOGFILE"
echo ""
sleep 2
clear

# ============================================================
# Function to run modules safely (works without exec bit)
# ============================================================
run_module() {
    local module="$1"
    local name="$2"
    local path="$HYPR_DIR/modules/$module"

    if is_completed "$name"; then
        log_status "Skipping $name (already completed)"
        return 0
    fi

    display_header "$name"

    if [[ -x "$path" ]]; then
        "$path"
    else
        bash "$path"
    fi

    if [[ $? -eq 0 ]]; then
        mark_completed "$name"
        log_success "$name completed successfully"
        return 0
    else
        log_error "$name failed"
        return 1
    fi
}

# ============================================================
# Run essential modules in sequence
# ============================================================
run_module "00-preflight.sh" "Preflight: Hyprland base" || exit 1
sleep 1
run_module "01-packages.sh" "Install packages" || exit 1
sleep 1
run_module "02-stow.sh" "Stow configuration" || exit 1
sleep 1
run_module "03-setup.sh" "Setup system" || exit 1
sleep 1

# Interactive config
"$HYPR_DIR/modules/04-config.sh"

# ============================================================
# Summary Screen
# ============================================================
display_header "Summary"
sleep .5
log_success "Installation completed successfully!"
sleep 1
echo "Completed steps:"

if command_exists jq; then
    jq -r '.completed_steps[]' "$STATE_FILE" | while read -r step; do
        echo "  ✅ $step"
    done
else
    while read -r step; do
        echo "  ✅ $step"
    done < "$ASSET_DIR/completed_steps.txt"
fi
sleep 1.5

# ============================================================
# Helpful keybinds (plain output for simplicity)
# ============================================================
echo -e "\n   Hyprland Gruvbox Installation is Complete !!\n        A list of common helpful keybinds is below:"

echo -e "  Win + ENTER         Kitty Terminal
  Win + B             Brave Browser
  Win + F             Thunar File Manager
  Win + N             NeoVim
  Win + Q             Close Window
  Win + SPACE         Fuzzel Launcher
  Win + CTRL + Q      Logout
  Win + Mouse Left    Move Window
  Win + Print         Hyprshot Screenshot"

echo -e "\n   Display full keybinds with:  Win + SPACE
   or click the gear icon in the Waybar"

log_status "Restart is required to complete setup!"
sleep 1

# ============================================================
# Next step prompt
# ============================================================
echo "What would you like to do next?"
echo "  1. Exit"
echo "  2. Reboot system"
echo "  3. Launch Hyprland"
echo ""
read -rp "Enter your choice [1]: " next_choice
next_choice=${next_choice:-1}
echo ""
sleep 2

case "$next_choice" in
    1)
        log_status "Exiting installer"
        exit 0
        ;;
    2)
        log_status "Rebooting system"
        sudo reboot
        ;;
    3)
        log_status "Launching Hyprland"
        exec hyprland
        ;;
    *)
        log_error "Invalid choice"
        exit 1
        ;;
esac

