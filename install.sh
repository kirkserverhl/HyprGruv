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
    log_warning "Normal runs will SKIP completed pre-reboot modules."
    log_warning "Post-reboot setup (SDDM, monitors, GRUB, shell, defaults) runs on first Hyprland login."
    log_warning "To force a full re-test (re-run packages + reach stow):  FORCE=1 ./install.sh"
    log_warning "To reach/re-test stow *without* re-doing the heavy package step: SKIP_PACKAGES=1 FORCE=1 ./install.sh"
    log_warning "For a completely clean state this run: RESET_STATE=1 FORCE=1 ./install.sh"
    log_warning "To re-run post-reboot wizard: FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh"
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

# ============================================================
# Final sync before reboot (pre-reboot phase complete)
# ============================================================
display_header "Pre-reboot sync"
log_status "Pre-reboot install complete. Running final system sync before reboot..."
if command -v yay >/dev/null 2>&1; then
  yay -Syu --noconfirm || log_warning "yay -Syu reported issues (continuing to reboot)"
else
  log_warning "yay not found — falling back to pacman -Syu"
  sudo pacman -Syu --noconfirm || log_warning "pacman -Syu reported issues (continuing to reboot)"
fi
sleep 1

mark_completed "Pre-reboot install"

# ============================================================
# Summary Screen
# ============================================================
display_header "Summary"
sleep .5
log_success "Pre-reboot installation completed successfully!"
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

log_status "Rebooting now. Post-reboot setup will start automatically on first Hyprland login."
sleep 2

# ============================================================
# Post-reboot instructions (printed before reboot)
# ============================================================
cat << 'EOF'

Pre-reboot install complete (preflight, packages, stow).

After reboot:
  1. Log in via SDDM — select the Hyprland session (not uwsm-managed)
  2. A terminal wizard will open automatically to finish setup:
     - waypaper/awww + wallpapers (matugen theming), SDDM, monitors, GRUB, shell, defaults

If the wizard does not appear, run manually:
  bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

Re-run the wizard any time:
  FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

Chaotic-AUR setup happens during package install (01-packages.sh).
VM users: guest tools are installed in 01-packages.sh for SDDM/display stability.

EOF

sleep 3
sudo reboot


