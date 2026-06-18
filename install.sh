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
source "${REPO_DOTFILES_SCRIPTS}/header.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "${REPO_DOTFILES_SCRIPTS}/colors.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

# ============================================================
# Setup logging
# ============================================================
mkdir -p "$ASSET_DIR/logs"
LOGFILE="$ASSET_DIR/logs/install_$(date +"%Y%m%d_%H%M%S").log"
export HYPRGRUV_LOGFILE="$LOGFILE"
exec > >(tee -a "$LOGFILE") 2>&1

# ============================================================
# Welcome Screen
# ============================================================
clear

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
    rm -f "$STATE_FILE" "$ASSET_DIR/completed_steps.txt" "$ASSET_DIR/user_choices.txt" 2>/dev/null || true
    # init_state (from state.sh) recreates a fresh install_state.json on next access
fi

if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]]; then
    if is_completed "Install packages" || is_completed "Stow configuration"; then
        log_warning "Previous install state detected (packages or stow marked complete)."
        log_warning "Normal runs will SKIP completed pre-reboot modules."
        log_warning "Full setup wizard runs near the end of install.sh (before optional reboot)."
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
    local module_exit=0

    if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]] && is_completed "$name"; then
        log_status "Skipping $name (already completed)"
        return 0
    fi

    display_header "$name"

    # Run via bash and capture exit explicitly. Child modules must not inherit the
    # install.sh `exec > >(tee …)` redirect alone — combined with pipefail in modules
    # that can SIGPIPE/exit non-zero even when the module succeeds standalone.
    set +e
    bash "$path" 2>&1 | tee -a "$LOGFILE"
    module_exit=${PIPESTATUS[0]}
    set -e

    if [[ $module_exit -eq 0 ]]; then
        mark_completed "$name"
        log_success "$name completed successfully"
        return 0
    else
        log_error "$name failed (exit $module_exit)"
        log_error "Module log: $LOGFILE"
        log_error "Re-run directly: bash $path"
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
    if ! run_module "01-packages.sh" "Install packages"; then
        if [[ "${CONTINUE_ON_PACKAGE_FAIL:-1}" == "1" ]]; then
            log_warning "Install packages reported errors — continuing to stow (set CONTINUE_ON_PACKAGE_FAIL=0 to stop here)"
            mark_completed "Install packages"
        else
            exit 1
        fi
    fi
fi
sleep 1

run_module "02-stow.sh" "Stow configuration" || exit 1
sleep 1

# ============================================================
# Opening wallpaper + first matugen palette (before reboot)
# Runs after stow so set_wallpaper.sh, matugen templates, and
# waypaper config are in place.
# ============================================================
if [[ "${SKIP_WALLPAPER:-0}" != "1" ]]; then
    display_header "Opening Wallpaper"
    log_status "Applying opening wallpaper and default matugen theme…"
    set +e
    bash "$HYPR_DIR/lib/scripts/default_wp.sh"
    wp_exit=$?
    set -e
    if [[ $wp_exit -eq 0 ]]; then
        log_success "Opening wallpaper and matugen theme applied"
        mark_completed "Opening wallpaper"
    else
        log_warning "default_wp.sh finished with warnings (post-reboot setup can retry)"
    fi
else
    log_warning "SKIP_WALLPAPER=1 — skipping opening wallpaper step"
fi
sleep 1

# ============================================================
# Full setup wizard (03–05) — run before reboot when possible
# Ideal for EndeavourOS: clone repo in KDE, run install.sh in one go.
# ============================================================
if [[ "${SKIP_SETUP_WIZARD:-0}" != "1" ]]; then
    display_header "Setup Wizard"
    log_status "Running full setup (SDDM, GRUB, shell, defaults)…"
    set +e
    RUN_FROM_INSTALL=1 INSTALL_LOGFILE="$LOGFILE" bash "$HYPR_DIR/lib/scripts/post_reboot_setup.sh"
    wizard_exit=$?
    set -e
    if [[ $wizard_exit -eq 0 ]]; then
        log_success "Setup wizard completed"
    else
        log_warning "Setup wizard finished with errors (exit $wizard_exit)"
        log_status "Retry: FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh"
    fi
else
    log_warning "SKIP_SETUP_WIZARD=1 — wizard skipped (run manually: bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh)"
fi
sleep 1

# ============================================================
# Refresh package databases (no full upgrade — 01-packages already
# installed the manifest with --needed; -Syu would re-touch every pkg)
# ============================================================
display_header "Final sync"
log_status "Refreshing package databases…"
if command -v yay >/dev/null 2>&1; then
    yay -Sy --noconfirm || log_warning "yay -Sy reported issues (continuing)"
else
    sudo pacman -Sy --noconfirm || log_warning "pacman -Sy reported issues (continuing)"
fi
sleep 1

mark_completed "Pre-reboot install"

# ============================================================
# Summary Screen
# ============================================================
display_header "Summary"
sleep .5
log_success "Hyprgruv installation completed!"
sleep 1
hyprgruv_print_completed_steps
hyprgruv_print_setup_footer install
sleep 1

# ============================================================
# Next steps — interactive menu (45s timeout → reboot)
# ============================================================
do_install_reboot() {
    cat <<'EOF'

After reboot, log in via SDDM and select the Hyprland session.
HyprGruv will sync packages and open Settings on first login.

EOF
    log_status "Rebooting now to finish SDDM / display manager handoff…"
    sleep 2
    sudo reboot
}

do_install_exit() {
    cat <<'EOF'

Next: log out of your current session, then at SDDM select the Hyprland session.
HyprGruv will sync packages and open Settings on first login.

If anything was skipped later:
  FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

EOF
    log_success "Done — log out and pick Hyprland at SDDM when ready."
    exit 0
}

do_install_rerun_wizard() {
    log_status "Re-running setup wizard…"
    set +e
    FORCE=1 RUN_FROM_INSTALL=1 INSTALL_LOGFILE="$LOGFILE" bash "$HYPR_DIR/lib/scripts/post_reboot_setup.sh"
    local wiz_exit=$?
    set -e
    if [[ $wiz_exit -eq 0 ]]; then
        log_success "Setup wizard finished"
    else
        log_warning "Setup wizard finished with errors (exit $wiz_exit)"
    fi
    prompt_install_finish
}

prompt_install_finish() {
    local choice=""
    local timeout=45
    local remaining=$timeout
    local default_action="reboot"

    [[ "${SKIP_REBOOT:-0}" == "1" ]] && default_action="exit"

    display_header "Next Steps"
    cat <<'EOF'

Installation complete. Choose what to do next:

  1) Reboot now (recommended — finish SDDM / Hyprland handoff)
  2) Exit without rebooting (log out manually and pick Hyprland at SDDM)
  3) Re-run setup wizard (SDDM, GRUB, shell, defaults)

EOF

    if [[ "$default_action" == "reboot" ]]; then
        log_status "Auto-reboot in ${timeout}s if no selection…"
    else
        log_status "SKIP_REBOOT=1 — auto-exit in ${timeout}s if no selection…"
    fi
    echo ""

    while ((remaining > 0)) && [[ -z "$choice" ]]; do
        printf '\r  Enter 1, 2, or 3'
        if [[ "$default_action" == "reboot" ]]; then
            printf ' (auto-reboot in %2ds): ' "$remaining"
        else
            printf ' (auto-exit in %2ds): ' "$remaining"
        fi
        if read -t 1 -r choice </dev/tty 2>/dev/null; then
            printf '\n'
            break
        fi
        ((remaining--)) || true
    done

    if [[ -z "$choice" ]]; then
        printf '\n'
        if [[ "$default_action" == "reboot" ]]; then
            log_status "No selection — rebooting now (timeout)"
            do_install_reboot
        else
            log_status "No selection — exiting (timeout)"
            do_install_exit
        fi
        return
    fi

    case "$choice" in
    1)
        do_install_reboot
        ;;
    2)
        do_install_exit
        ;;
    3)
        do_install_rerun_wizard
        ;;
    *)
        log_warning "Invalid choice '$choice' — using default"
        if [[ "$default_action" == "reboot" ]]; then
            do_install_reboot
        else
            do_install_exit
        fi
        ;;
    esac
}

if [[ "${FORCE_REBOOT:-0}" == "1" ]]; then
    do_install_reboot
else
    prompt_install_finish
fi
