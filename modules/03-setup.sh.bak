#!/usr/bin/env bash
# 03-setup.sh — run post-install setup scripts
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure helpers exist and load them
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

display_header "SETUP"

# --- Ensure 'gum' available (fallback to plain bash if not) ---
ensure_gum() {
  if command -v gum >/dev/null 2>&1; then return 0; fi
  log_status "gum not found. Installing…"
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm gum || { log_error "Failed to install gum"; return 1; }
  else
    sudo pacman -S --needed --noconfirm gum || { log_error "Failed to install gum"; return 1; }
  fi
}
ensure_gum || true
ensure_zsh || true

# --- Ensure 'sddm' is installed (handles SKIP_PACKAGES or partial runs) ---
ensure_sddm() {
  if pacman -Qq sddm &>/dev/null; then return 0; fi
  log_status "sddm not found. Installing…"
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm sddm || { log_error "Failed to install sddm"; return 1; }
  else
    sudo pacman -S --needed --noconfirm sddm || { log_error "Failed to install sddm"; return 1; }
  fi
}

# --- Ensure 'zsh' (many scripts and user workflow depend on it; shell.sh will choose it) ---
ensure_zsh() {
  if pacman -Qq zsh &>/dev/null; then return 0; fi
  log_status "zsh not found. Installing…"
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm zsh || { log_error "Failed to install zsh"; return 1; }
  else
    sudo pacman -S --needed --noconfirm zsh || { log_error "Failed to install zsh"; return 1; }
  fi
}

run_with_spinner() {
  local cmd="$1"
  if command -v gum >/dev/null 2>&1; then
    gum spin --title "Running: ${cmd}" -- bash -c "$cmd"
  else
    bash -c "$cmd"
  fi
}

# Scripts directory (from common.sh or fallback)
SCRIPTS_DIR="${SCRIPTS:-$HYPR_DIR/scripts}"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
  log_error "Scripts directory not found: $SCRIPTS_DIR"; exit 1
fi

# Define the scripts in execution order
# Note: chaotic.sh (Chaotic-AUR) is now done early inside 01-packages.sh.
# Modules 04-config and 05-setup_defaults run after reboot via
# lib/scripts/post_reboot_setup.sh (triggered from autostart on first Hyprland login).
declare -a ORDERED_SCRIPTS=(
  #"hard_copy.sh|Hard Copy files in root directory"
  # Temporarily commented out (hangs on waypaper in pre-graphical / no-compositor context).
  # Use SKIP_WALLPAPER=1 to control, or manually run after first Hyprland login.
  # "default_wp.sh|Load default wallpaper"
  #"hyprpm.sh|Install Hyprpm plugins"
)

# Support skipping the wallpaper step (waypaper + matugen can hang or block
# when there is no running Wayland compositor / awww yet during
# the text-mode install phase). Use on laptop / test runs:
#   SKIP_WALLPAPER=1 ./install.sh
# The step can be run manually later from inside Hyprland:
#   bash ~/.hyprgruv/lib/scripts/default_wp.sh


any_failed=0
for entry in "${ORDERED_SCRIPTS[@]}"; do
  script_name="${entry%%|*}"
  description="${entry#*|}"
  script_path="$SCRIPTS_DIR/$script_name"

  # Skip wallpaper step if requested (avoids hangs with waypaper in non-graphical context)
  if [[ "$script_name" == "default_wp.sh" && "${SKIP_WALLPAPER:-0}" == "1" ]]; then
    log_warning "SKIP_WALLPAPER=1 — skipping default wallpaper / matugen step"
    continue
  fi

  # If repo still has old typo, auto-fallback
  if [[ ! -f "$script_path" ]]; then
    log_error "Missing script: $script_path"
    any_failed=1
    continue
  fi

  [[ -x "$script_path" ]] || chmod +x "$script_path"

  log_status "Starting: $description"
  if run_with_spinner "\"$script_path\""; then
    log_success "$description completed"
  else
    log_error "$description failed"
    any_failed=1
  fi
  sleep 1
done

(( any_failed )) && { log_error "One or more setup steps failed."; exit 1; }

log_status "Ensuring SDDM is installed..."
ensure_sddm || true

log_status "Enabling SDDM (greeter) and installing theme..."
sudo systemctl enable sddm.service || true
sudo systemctl set-default graphical.target || true
bash "$SCRIPTS_DIR/sddm_candy_install.sh" || true

# For VMs we force the GRUB cmdline / boot compatibility tweaks here
# (nomodeset etc.) so SDDM can take over the display on first reboot,
# even if the user later skips the interactive GRUB theme question.
if [[ "${IS_VM:-false}" == "true" ]]; then
  log_status "VM detected — forcing GRUB compatibility (so SDDM loads from boot)"
  APPLY_GRUB_THEME=0 bash "$SCRIPTS_DIR/grub.sh" || true
fi

mark_completed "Setup system"
clear
log_success "Setup completed"


