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

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

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
# Re-run / testing guidance (addresses "skips packages/stow on re-runs")
# ============================================================
if [[ "${RESET_STATE:-0}" == "1" || "${RESET:-0}" == "1" ]]; then
  log_warning "RESET_STATE=1 — clearing previous completed steps (fresh test run)"
  : > "$ASSET_DIR/completed_steps.txt" 2>/dev/null || true
  if command_exists jq && [[ -f "$STATE_FILE" ]]; then
    tmp="$(mktemp)"
    jq '.completed_steps = []' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
  fi
fi

if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]]; then
  if is_completed "Install packages" || is_completed "Stow configuration"; then
    log_warning "Previous install state detected (packages or stow marked complete)."
    log_warning "Normal runs will SKIP the package + stow modules and jump ahead."
    log_warning "To force a full re-test (re-run packages + reach stow):  FORCE=1 ./install.sh"
    log_warning "To reach/re-test stow *without* re-doing the heavy package step: SKIP_PACKAGES=1 FORCE=1 ./install.sh"
    log_warning "For a completely clean state this run: RESET_STATE=1 FORCE=1 ./install.sh"
    log_warning "(You can also run modules directly: bash modules/02-stow.sh )"
    echo ""
    sleep 1.5
  fi
fi

# ============================================================
# Function to run modules safely (works without exec bit)
# ============================================================
run_module() {
    local module="$1"
    local name="$2"
    local path="$HYPR_DIR/modules/$module"

    if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]] && is_completed "$name"; then
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

# Packages step (and its internal chaotic bootstrap) can be heavy, slow on VMs,
# or blocked by keyring/pacman.d issues. If you mainly want to reach/re-run
# the stow step to apply configs (and don't need the full pkg reinstall right now):
#     SKIP_PACKAGES=1 ./install.sh
# To also force re-running stow (or other later steps) even if state says completed:
#     SKIP_PACKAGES=1 FORCE=1 ./install.sh
# (Or just run the script directly: bash modules/02-stow.sh )
if [[ "${SKIP_PACKAGES:-0}" == "1" ]]; then
    log_warning "SKIP_PACKAGES=1 — skipping 'Install packages' module (chaotic + big pacman/yay installs)"
    if ! is_completed "Install packages"; then
        mark_completed "Install packages"
    fi
else
    run_module "01-packages.sh" "Install packages" || exit 1
fi
sleep 1

run_module "02-stow.sh" "Stow configuration" || exit 1
sleep 1
run_module "03-setup.sh" "Setup system" || exit 1
sleep 1

# ------------------------------------------------------------
# Run the remaining configuration scripts BEFORE reboot.
# This way the user gets a fully configured system (shell choice,
# monitors, GRUB theme, cleanup, default apps) on first login
# instead of having to run these after rebooting into Hyprland.
# ------------------------------------------------------------
log_status "Ensuring interactive prerequisites (gum, zsh) are present..."
# Quick local ensure (in case of SKIP_PACKAGES or jumping around)
if ! command -v gum >/dev/null 2>&1; then
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm gum || true
  else
    sudo pacman -S --needed --noconfirm gum || true
  fi
fi
if ! pacman -Qq zsh &>/dev/null; then
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm zsh || true
  else
    sudo pacman -S --needed --noconfirm zsh || true
  fi
fi

log_status "Running full interactive configuration (monitors, GRUB, cleanup, shell, etc.)..."
if [[ -f "$HYPR_DIR/modules/04-config.sh" ]]; then
  bash "$HYPR_DIR/modules/04-config.sh" || log_warning "04-config.sh finished (some steps may have been skipped)"
else
  log_warning "04-config.sh not found"
fi
sleep 1

log_status "Choosing default terminal / browser / editor..."
if [[ -f "$HYPR_DIR/modules/05-setup_defaults.sh" ]]; then
  bash "$HYPR_DIR/modules/05-setup_defaults.sh" || log_warning "05-setup_defaults.sh finished"
else
  log_warning "05-setup_defaults.sh not found"
fi
sleep 1

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

log_status "Core installation + configuration complete (Hyprland, SDDM, stow, shell/monitors/GRUB/defaults, etc.). Rebooting into SDDM..."
sleep 2

# ============================================================
# Post-reboot instructions (printed before reboot)
# ============================================================
cat << 'EOF'

Core setup + interactive configuration completed before reboot.

After reboot, log in via SDDM (select the Hyprland session). Your shell preference,
monitor config, GRUB theme, defaults, etc. should already be applied.

VM users: guest tools were installed and GRUB was adjusted (nomodeset + visible menu)
to help the SDDM greeter appear reliably on virtual graphics.

Chaotic-AUR setup now happens early (during package install in 01-packages.sh).

If you need to manually (re)configure Chaotic-AUR later (e.g. after network fix in a VM):
  sudo bash ~/.hyprgruv/modules/000-setup_chaotic.sh                 # dedicated robust standalone (recommended for the keyring/VM case)
  DRY_RUN=1 bash ~/.hyprgruv/lib/scripts/chaotic.sh                  # test mode
  bash ~/.hyprgruv/lib/scripts/chaotic.sh                          # apply for real

Re-run these any time if you want to change choices:
  ~/.hyprgruv/modules/04-config.sh
  ~/.hyprgruv/modules/05-setup_defaults.sh

EOF

sleep 3
sudo reboot


