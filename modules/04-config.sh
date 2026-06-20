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

hyprgruv_section_intro "Config"

# gum theming comes from common.sh → colors.sh / ~/.cache/matugen/colors.sh
export GUM_CONFIRM_PROMPT="? "

# ------------------------------------------------------------
# Helpers: gum fallbacks + printing
# ------------------------------------------------------------
_has_gum() { command -v gum >/dev/null 2>&1; }
_confirm() {
    local prompt="$1"
    if _has_gum; then gum_confirm_prompt "$prompt"; else
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
    if [[ "$title" == "Shell Configuration" ]]; then
        HYPRGRUV_FROM_CONFIG=1 hyprgruv_run_interactive "$path" "${HYPRGRUV_LOGFILE:-}"
    else
        bash "$path"
    fi
    log_success "$title completed"
}

# Scripts directory (from common.sh; fallback)
SCRIPTS_DIR="${SCRIPTS:-$HYPR_DIR/lib/scripts}"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
    log_error "Scripts directory not found: $SCRIPTS_DIR"
    exit 1
fi

_section_handoff() {
    local message="${1:-}"
    local kind="${2:-success}"
    hyprgruv_section_transition "$message" "$kind"
}

# SDDM (package, enable, Sugar Candy theme) is configured in 03-setup.sh before reboot.
# Re-apply manually: bash ~/.hyprgruv/lib/scripts/sddm_candy_install.sh

# ------------------------- GRUB ------------------------------
hyprgruv_section_intro "Grub"
if _confirm "  🪱   Configure GRUB theme?"; then
    script="$SCRIPTS_DIR/grub.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "GRUB Theme"
        _section_handoff "GRUB Theme completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "GRUB setup skipped" status
fi

# ------------------------- Shell -----------------------------
hyprgruv_section_intro "Shell"
if _confirm "  🐚   Configure the Shell? (fish, zsh, or bash)"; then
    script="$SCRIPTS_DIR/shell.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Shell Configuration"
        _section_handoff "Shell configuration completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "Shell setup skipped" status
fi

# ------------------------- Atuin -----------------------------
hyprgruv_section_intro "Atuin"
if _confirm "  📜   Set up Atuin shell history?"; then
    script="$SCRIPTS_DIR/atuin.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Atuin Setup"
        _section_handoff "Atuin Setup completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "Atuin setup skipped" status
fi

# ------------------------ Pacseek ---------------------------
hyprgruv_section_intro "Pacseek"
if _confirm "  📦   Install Pacseek (AUR package browser)?"; then
    script="$SCRIPTS_DIR/pacseek.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Pacseek Setup" || log_warning "Pacseek install failed — you can retry later"
        _section_handoff "Pacseek Setup completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "Pacseek setup skipped" status
fi

# ------------------------- SSH Key --------------------------
hyprgruv_section_intro "SSH Key"
if _confirm "  🔑   Set up SSH key for GitHub?"; then
    script="$SCRIPTS_DIR/ssh_key.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "SSH Key Setup"
        _section_handoff "SSH Key Setup completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "SSH key setup skipped" status
fi

# -------------------------- Zram ----------------------------
hyprgruv_section_intro "Zram"
if _confirm "  💾   Set up zram compressed swap?"; then
    script="$SCRIPTS_DIR/zram.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "Zram Setup" || log_warning "Zram setup finished with warnings"
        _section_handoff "Zram Setup completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "Zram setup skipped" status
fi

mark_completed "Interactive config"

# ------------------------ Cleanup ----------------------------
hyprgruv_section_intro "Cleanup"
if _confirm "  🧹   Perform system cleanup?"; then
    script="$SCRIPTS_DIR/cleanup.sh"
    if [[ -f "$script" ]]; then
        run_step "$script" "System Cleanup"
        _section_handoff "System Cleanup completed"
    else
        log_error "Script not found: $script"
        exit 1
    fi
else
    _section_handoff "System cleanup skipped" status
fi