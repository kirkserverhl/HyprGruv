#!/usr/bin/env bash
# 04-config.sh — interactive post-setup choices
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Repo root + helpers
# ------------------------------------------------------------
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

toilet -f graffiti Config.sh | lsd-print

# ------------------------------------------------------------
# Optional gum theming (colors)
# ------------------------------------------------------------
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"
export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#282828"
export GUM_INPUT_CURSOR_FOREGROUND="#282828"
export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B"
export GUM_SPIN_SPINNER_FOREGROUND="#749D91"

# ------------------------------------------------------------
# Helpers: gum fallbacks + printing
# ------------------------------------------------------------
_has_gum() { command -v gum >/dev/null 2>&1; }
_confirm() {
    local prompt="$1"
    if _has_gum; then gum confirm "$prompt"; else
        read -rp "$prompt [y/N]: " ans
        [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
    fi
}
_say() {
    echo -e "$*"
}
run_step() {
    local path="$1"
    local title="$2"
    log_status "Starting: $title"
    # Do NOT wrap in gum spin here. These sub-scripts (shell.sh, grub.sh, etc.)
    # are interactive (gum choose/confirm, GUI tools, read prompts, etc.).
    # Wrapping them in gum spin breaks TTY / nested gum input and causes apparent stalls/hangs.
    bash "$path"
    log_success "$title completed"
}

# Scripts directory (from common.sh; fallback)
SCRIPTS_DIR="${SCRIPTS:-$HYPR_DIR/scripts}"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    log_error "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

# --------------------- SDDM (Sugar Candy) --------------------
# Note: Core SDDM enable + Sugar Candy theme is now performed unconditionally
# in 03-setup.sh (before we reach here) so the system boots to SDDM.
# We keep a section for re-runs / manual but auto-skip the prompt when already done.
sleep 0.5
echo ""
display_header "SDDM"
sleep 0.5
if systemctl is-enabled sddm.service &>/dev/null; then
    _say "SDDM service already enabled and Sugar Candy theme applied earlier in setup."
else
    if _confirm "  🍬   Install Sugar-Candy SDDM theme?"; then
        _say "Configuring SDDM theme…"
        script="$SCRIPTS_DIR/sddm_candy_install.sh"
        if [[ -f "$script" ]]; then
            run_step "$script" "Sugar-Candy SDDM Theme"
        else
            log_error "Script not found: $script"
            exit 1
        fi
    else
        _say "SDDM configuration skipped."
    fi
fi
sleep 1
clear

# ------------------------- GRUB ------------------------------
echo ""
display_header "Grub"
sleep 0.5
if _confirm "  🪱   Configure GRUB theme?"; then
    _say "Starting GRUB setup…"
    script="$SCRIPTS_DIR/grub.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "GRUB Theme"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "GRUB setup skipped."
fi
sleep 1
clear

# ------------------------- Shell -----------------------------
echo ""
display_header "Shell"
sleep 0.5
if _confirm "  🐚   Configure the Shell? (zsh, Oh My Zsh, custom plugins)"; then
    _say "Starting shell setup…"
    script="$SCRIPTS_DIR/shell.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Shell Configuration"

        zsh_fix="$SCRIPTS_DIR/zsh_fix.sh"
        if [[ -f "$zsh_fix" ]]; then
            run_step "$zsh_fix" "Zsh Plugin Fix"
        else
            log_warning "zsh_fix.sh not found at: $zsh_fix"
        fi
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "Shell setup skipped."
fi
sleep 0.5
clear

# ------------------------- Atuin -----------------------------
echo ""
display_header "Atuin"
sleep 0.5
if _confirm "  📜   Set up Atuin shell history?"; then
    _say "Starting Atuin setup…"
    script="$SCRIPTS_DIR/atuin.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Atuin Setup"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "Atuin setup skipped."
fi
sleep 0.5
clear

# ------------------------ Pacseek ---------------------------
echo ""
display_header "Pacseek"
sleep 0.5
if _confirm "  📦   Install Pacseek (AUR package browser)?"; then
    _say "Starting Pacseek setup…"
    script="$SCRIPTS_DIR/pacseek.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Pacseek Setup" || log_warning "Pacseek install failed — you can retry later"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "Pacseek setup skipped."
fi
sleep 0.5
clear

# ------------------------- SSH Key --------------------------
echo ""
display_header "SSH Key"
sleep 0.5
if _confirm "  🔑   Set up SSH key for GitHub?"; then
    _say "Starting SSH key setup…"
    script="$SCRIPTS_DIR/ssh_key.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "SSH Key Setup"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "SSH key setup skipped."
fi
sleep 0.5
clear

# -------------------------- Zram ----------------------------
echo ""
display_header "Zram"
sleep 0.5
if _confirm "  💾   Set up zram compressed swap?"; then
    _say "Starting zram setup…"
    script="$SCRIPTS_DIR/zram.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Zram Setup" || log_warning "Zram setup finished with warnings"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "Zram setup skipped."
fi
sleep 0.5
clear

mark_completed "Interactive config"

# ------------------------ Cleanup ----------------------------
echo ""
display_header "Cleanup"
sleep 0.5
if _confirm "  🧹   Perform system cleanup?"; then
    _say "Starting system cleanup…"
    script="$SCRIPTS_DIR/cleanup.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "System Cleanup"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _say "System cleanup skipped."
fi
sleep 1
clear
