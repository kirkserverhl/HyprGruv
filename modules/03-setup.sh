#!/usr/bin/env bash
# 03-setup.sh — run post-install setup scripts
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure helpers exist and load them
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

display_header "Setup"
hyprgruv_strict_banner

# --- Ensure 'gum' available (fallback to plain bash if not) ---
ensure_gum() {
    if command -v gum >/dev/null 2>&1; then return 0; fi
    log_status "gum not found. Installing…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm gum || {
            log_error "Failed to install gum"
            return 1
        }
    else
        sudo pacman -S --needed --noconfirm gum || {
            log_error "Failed to install gum"
            return 1
        }
    fi
}

# --- Ensure 'zsh' (many scripts and user workflow depend on it; shell.sh will choose it) ---
ensure_zsh() {
    if pacman -Qq zsh &>/dev/null; then return 0; fi
    log_status "zsh not found. Installing…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm zsh || {
            log_error "Failed to install zsh"
            return 1
        }
    else
        sudo pacman -S --needed --noconfirm zsh || {
            log_error "Failed to install zsh"
            return 1
        }
    fi
}

ensure_gum || hyprgruv_strict_abort "Failed to install gum"
ensure_zsh || hyprgruv_strict_abort "Failed to install zsh"
hyprgruv_require_cmd zsh

# gum spin hides sudo prompts and long build output — use it only for quick scripts.
run_setup_script() {
    local script_path="$1"
    local script_name="$2"

    if [[ "$script_name" == "hyprpm.sh" ]]; then
        log_status "Running: $script_path (live output — plugin build may take several minutes)"
        bash "$script_path"
        return $?
    fi

    if command -v gum >/dev/null 2>&1; then
        gum spin --title "Running: ${script_path}" -- bash "$script_path"
    else
        bash "$script_path"
    fi
}

# Scripts directory (from common.sh or fallback)
SCRIPTS_DIR="${SCRIPTS:-$HYPR_DIR/lib/scripts}"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    log_error "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

# Define the scripts in execution order
# Note: chaotic.sh (Chaotic-AUR) is now done early inside 01-packages.sh.
# Modules 04-config and 05-setup_defaults run in the same post_reboot_setup.sh
# wizard (from install.sh before reboot, or manual post_reboot_setup.sh).
declare -a ORDERED_SCRIPTS=(
    #"hard_copy.sh|Hard Copy files in root directory"
    # Temporarily commented out (hangs on waypaper in pre-graphical / no-compositor context).
    # Use SKIP_WALLPAPER=1 to control, or manually run after first Hyprland login.
    # "default_wp.sh|Load default wallpaper"
    # Builds hyprbars + hymission when Hyprland is running; otherwise defers to first login.
    # Session build/load: ~/.config/hyprgruv/scripts/hyprpm-reload.sh (autostart.lua).
    "hyprpm.sh|Install Hyprpm plugins"
    "setup-mime-handlers.sh|Configure MIME handlers and file openers"
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
    if run_setup_script "$script_path" "$script_name"; then
        log_success "$description completed"
    else
        log_error "$description failed"
        any_failed=1
    fi
    sleep 1
done

((any_failed)) && {
    log_error "One or more setup steps failed."
    exit 1
}

# SDDM package, enable, and Sugar Candy theme — all in sddm_candy_install.sh
log_status "Configuring SDDM (display manager + Sugar Candy theme)..."
bash "$SCRIPTS_DIR/sddm_candy_install.sh" || hyprgruv_strict_abort "SDDM setup failed (sddm_candy_install.sh)"
hyprgruv_require_pkg sddm

# For VMs we force the GRUB cmdline / boot compatibility tweaks here
# (nomodeset etc.) so SDDM can take over the display on first reboot,
# even if the user later skips the interactive GRUB theme question.
if [[ "${IS_VM:-false}" == "true" ]]; then
    log_status "VM detected — forcing GRUB compatibility (so SDDM loads from boot)"
    APPLY_GRUB_THEME=0 bash "$SCRIPTS_DIR/grub.sh" || hyprgruv_strict_abort "VM GRUB compatibility setup failed"
fi

mark_completed "Setup system"
clear
log_success "Setup completed"
