#!/usr/bin/env bash
# post_reboot_setup.sh — run modules 03–05 (install wizard; invoked from install.sh or manually)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Hyprgruv repo not found at $HYPR_DIR (set HYPRGRUV_DIR if elsewhere)"
  exit 1
fi

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

hyprgruv_strict_banner
hyprgruv_forbid_skip_var SKIP_WALLPAPER
hyprgruv_require_cmd yay

# --- Load helpers for consistent look (available after stow) ---
source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

mkdir -p "$ASSET_DIR/logs"
if [[ "${RUN_FROM_INSTALL:-0}" == "1" ]]; then
  LOGFILE="${INSTALL_LOGFILE:-$ASSET_DIR/logs/install.log}"
else
  LOGFILE="$ASSET_DIR/logs/post_reboot_$(date +"%Y%m%d_%H%M%S").log"
  exec > >(tee -a "$LOGFILE") 2>&1
fi
export HYPRGRUV_LOGFILE="$LOGFILE"

post_reboot_needed() {
  if [[ "${FORCE:-0}" == "1" || "${RE_RUN:-0}" == "1" ]]; then
    return 0
  fi
  if [[ "${RUN_FROM_INSTALL:-0}" == "1" ]]; then
    is_completed "Stow configuration" || return 1
    is_completed "Post-reboot setup" && return 1
    return 0
  fi
  is_completed "Post-reboot setup" && return 1
  is_completed "Stow configuration" || return 1
  return 0
}

if ! post_reboot_needed; then
  log_status "Post-reboot setup already complete (or pre-reboot install not finished). Nothing to do."
  exit 0
fi

_HYPRGRUV_PENDING_HANDOFF=""

run_module() {
  local module="$1"
  local name="$2"
  local path="$HYPR_DIR/modules/$module"
  local module_exit=0

  if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]] && is_completed "$name"; then
    log_status "Skipping $name (already completed)"
    return 0
  fi

  if [[ -n "$_HYPRGRUV_PENDING_HANDOFF" ]]; then
    hyprgruv_section_transition "$_HYPRGRUV_PENDING_HANDOFF"
    _HYPRGRUV_PENDING_HANDOFF=""
  fi

  hyprgruv_section_intro "$name"

  set +e
  hyprgruv_run_interactive "$path" "$LOGFILE"
  module_exit=$?
  set -e

  if [[ $module_exit -eq 0 ]]; then
    mark_completed "$name"
    _HYPRGRUV_PENDING_HANDOFF="$name completed successfully"
    return 0
  else
    log_error "$name failed (exit $module_exit)"
    return 1
  fi
}

clear
if [[ "${RUN_FROM_INSTALL:-0}" == "1" ]]; then
  display_header "Hyprgruv — Setup Wizard"
  echo ""
  log_status "Running full setup before reboot (EndeavourOS / graphical install path)."
else
  display_header "Hyprgruv — Post-reboot Setup"
  echo ""
  log_status "Welcome back! Wallpaper/theming runs first, then SDDM, GRUB, shell, and defaults."
fi
log_status "Logs: $LOGFILE"
echo ""
sleep 1.5

if [[ -f "$HYPR_DIR/lib/scripts/waypaper_setup.sh" ]]; then
  hyprgruv_section_intro "Wallpaper setup"
  bash "$HYPR_DIR/lib/scripts/waypaper_setup.sh" || hyprgruv_strict_abort "waypaper_setup.sh failed"
  _HYPRGRUV_PENDING_HANDOFF="Wallpaper setup completed"
else
  hyprgruv_strict_abort "waypaper_setup.sh not found"
fi
sleep 1

run_module "03-setup.sh" "Setup system" || exit 1
sleep 1

run_module "04-config.sh" "Interactive config" || exit 1
sleep 1

if [[ -f "$HYPR_DIR/modules/05-setup_defaults.sh" ]]; then
  if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]] && is_completed "Setup defaults"; then
    log_status "Skipping Setup defaults (already completed)"
  else
    if [[ -n "$_HYPRGRUV_PENDING_HANDOFF" ]]; then
      hyprgruv_section_transition "$_HYPRGRUV_PENDING_HANDOFF"
      _HYPRGRUV_PENDING_HANDOFF=""
    fi
    hyprgruv_section_intro "Setup defaults"
    set +e
    hyprgruv_run_interactive "$HYPR_DIR/modules/05-setup_defaults.sh" "$LOGFILE"
    defaults_exit=$?
    set -e
    if [[ $defaults_exit -eq 0 ]]; then
      mark_completed "Setup defaults"
      _HYPRGRUV_PENDING_HANDOFF="Setup defaults completed"
    else
      hyprgruv_strict_abort "05-setup_defaults.sh failed (exit $defaults_exit)"
    fi
  fi
else
  hyprgruv_strict_abort "05-setup_defaults.sh not found"
fi
sleep 1

mark_completed "Post-reboot setup"

if [[ "${RUN_FROM_INSTALL:-0}" == "1" ]]; then
  log_success "Setup wizard complete — continuing install…"
else
  if [[ -n "$_HYPRGRUV_PENDING_HANDOFF" ]]; then
    hyprgruv_section_transition "$_HYPRGRUV_PENDING_HANDOFF"
    _HYPRGRUV_PENDING_HANDOFF=""
  fi
  hyprgruv_section_intro "Summary"
  log_success "Post-reboot configuration complete!"
  echo ""
  hyprgruv_print_completed_steps
  echo ""
  hyprgruv_print_setup_footer standalone
  echo ""
  read -rp "Press Enter to close this window…" _ || true
fi