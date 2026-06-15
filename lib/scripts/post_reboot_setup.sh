#!/usr/bin/env bash
# post_reboot_setup.sh — run modules 03–05 after first boot into Hyprland
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

# --- Load helpers for consistent look (available after stow) ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

mkdir -p "$ASSET_DIR/logs"
LOGFILE="$ASSET_DIR/logs/post_reboot_$(date +"%Y%m%d_%H%M%S").log"
exec > >(tee -a "$LOGFILE") 2>&1

post_reboot_needed() {
  if [[ "${FORCE:-0}" == "1" || "${RE_RUN:-0}" == "1" ]]; then
    return 0
  fi
  is_completed "Post-reboot setup" && return 1
  # Pre-reboot phase must have finished (stow is the last pre-reboot step)
  is_completed "Stow configuration" || return 1
  return 0
}

if ! post_reboot_needed; then
  log_status "Post-reboot setup already complete (or pre-reboot install not finished). Nothing to do."
  exit 0
fi

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

clear
display_header "Hyprgruv — Post-reboot Setup"
echo ""
log_status "Welcome back! Wallpaper/theming runs first, then SDDM, monitors, GRUB, shell, and defaults."
log_status "Logs: $LOGFILE"
echo ""
sleep 1.5

if [[ -f "$HYPR_DIR/lib/scripts/waypaper_setup.sh" ]]; then
  display_header "Wallpaper setup"
  bash "$HYPR_DIR/lib/scripts/waypaper_setup.sh" || log_warning "waypaper_setup.sh finished with warnings"
else
  log_warning "waypaper_setup.sh not found"
fi
sleep 1

run_module "03-setup.sh" "Setup system" || exit 1
sleep 1

run_module "04-config.sh" "Interactive config" || exit 1
sleep 1

if [[ -f "$HYPR_DIR/modules/05-setup_defaults.sh" ]]; then
  display_header "Setup defaults"
  bash "$HYPR_DIR/modules/05-setup_defaults.sh" || log_warning "05-setup_defaults.sh finished with warnings"
  mark_completed "Setup defaults"
  log_success "Setup defaults completed"
else
  log_warning "05-setup_defaults.sh not found"
fi
sleep 1

mark_completed "Post-reboot setup"

display_header "Summary"
log_success "Post-reboot configuration complete!"
echo ""
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

echo -e "\n   Hyprgruv setup is complete!\n        Common keybinds:"
echo -e "  Win + ENTER         Terminal
  Win + B             Browser
  Win + F             Thunar
  Win + N             NeoVim
  Win + Q             Close Window
  Win + SPACE         Fuzzel Launcher
  Win + CTRL + Q      Logout"

echo -e "\n   Full keybinds: Win + K  or type 'keybinds' in a terminal"
echo -e "\n   Re-run this wizard any time:"
echo -e "     FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh"

echo ""
read -rp "Press Enter to close this window…" _ || true