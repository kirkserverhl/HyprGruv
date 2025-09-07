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
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

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
  if command -v lsd-print >/dev/null 2>&1; then
    echo -e "$*" | lsd-print
  else
    echo -e "$*"
  fi
}
run_step() {
  local path="$1"; local title="$2"
  log_status "Starting: $title"
  if _has_gum; then
    gum spin --title "$title" -- bash -c "\"$path\""
  else
    bash "$path"
  fi
  log_success "$title completed"
}

# Scripts directory (from common.sh; fallback)
SCRIPTS_DIR="${SCRIPTS:-$HYPR_DIR/scripts}"
if [[ ! -d "$SCRIPTS_DIR" ]]; then
  log_error "Scripts directory not found: $SCRIPTS_DIR"
  exit 1
fi

# --------------------- SDDM (Sugar Candy) --------------------
sleep 0.5; echo ""; display_header "SDDM"; sleep 0.5
if _confirm "  🍬   Install Sugar-Candy SDDM theme?"; then
  _say "Configuring SDDM theme…"
  script="$SCRIPTS_DIR/sddm_candy_install.sh"
  if [[ -f "$script" ]]; then
    run_step "$script" "Sugar-Candy SDDM Theme"
  else
    log_error "Script not found: $script"; exit 1
  fi
else
  _say "SDDM configuration skipped."
fi
sleep 1; clear

# ----------------------- Monitors ----------------------------
echo ""; display_header "Monitors"; sleep 0.5
if _confirm "  🖥️   Configure monitor setup?"; then
  _say "Starting monitor setup…"
  script="$SCRIPTS_DIR/monitor.sh"
  if [[ -f "$script" ]]; then
    run_step "$script" "Monitor Setup"
  else
    log_error "Script not found: $script"; exit 2
  fi
else
  _say "Monitor setup skipped."
fi
sleep 1; clear

# ------------------------- GRUB ------------------------------
echo ""; display_header "Grub"; sleep 0.5
if _confirm "  🪱   Configure GRUB theme?"; then
  _say "Starting GRUB setup…"
  script="$SCRIPTS_DIR/grub.sh"
  if [[ -f "$script" ]]; then
    run_step "$script" "GRUB Theme"
  else
    log_error "Script not found: $script"; exit 1
  fi
else
  _say "GRUB setup skipped."
fi
sleep 1; clear

# ------------------------ Cleanup ----------------------------
echo ""; display_header "Cleanup"; sleep 0.5
if _confirm "  🧹   Perform system cleanup?"; then
  _say "Starting system cleanup…"
  script="$SCRIPTS_DIR/cleanup.sh"
  if [[ -f "$script" ]]; then
    run_step "$script" "System Cleanup"
  else
    log_error "Script not found: $script"; exit 1
  fi
else
  _say "System cleanup skipped."
fi
sleep 1; clear

# ------------------------- Shell -----------------------------
echo ""; display_header "Shell"; sleep 0.5
if _confirm "  🐚   Configure the Shell?"; then
  _say "Starting shell setup…"
  script="$SCRIPTS_DIR/shell.sh"
  if [[ -f "$script" ]]; then
    run_step "$script" "Shell Configuration"
  else
    log_error "Script not found: $script"; exit 1
  fi
else
  _say "Shell setup skipped."
fi
sleep 0.5; clear

mark_completed "Interactive config"

