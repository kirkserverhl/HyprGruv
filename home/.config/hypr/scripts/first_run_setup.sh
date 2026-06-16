#!/usr/bin/env bash
# first_run_setup.sh — optional manual launcher for post_reboot_setup.sh
# Not started from Hyprland autostart (install.sh runs the wizard before reboot).
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
SETUP_SCRIPT="$HYPR_DIR/lib/scripts/post_reboot_setup.sh"
LOCK_FILE="${XDG_RUNTIME_DIR:-/tmp}/hyprgruv-first-run.lock"

resolve_terminal() {
  local term="kitty"
  if [[ -x "$HOME/.config/hypr/scripts/terminal.sh" ]]; then
    term="$("$HOME/.config/hypr/scripts/terminal.sh" 2>/dev/null || echo kitty)"
  elif [[ -x "$HYPR_DIR/defaults/terminal.sh" ]]; then
    term="$("$HYPR_DIR/defaults/terminal.sh" 2>/dev/null || echo kitty)"
  fi
  command -v "$term" >/dev/null 2>&1 || term="kitty"
  command -v "$term" >/dev/null 2>&1 || term="alacritty"
  command -v "$term" >/dev/null 2>&1 || term="foot"
  echo "$term"
}

needs_setup() {
  [[ -f "$HYPR_DIR/lib/state.sh" ]] || return 1
  # shellcheck source=/dev/null
  source "$HYPR_DIR/lib/common.sh"
  # shellcheck source=/dev/null
  source "$HYPR_DIR/lib/state.sh"
  if [[ "${FORCE:-0}" == "1" || "${RE_RUN:-0}" == "1" ]]; then
    return 0
  fi
  is_completed "Post-reboot setup" && return 1
  is_completed "Stow configuration" || return 1
  return 0
}

run_setup() {
  [[ -f "$SETUP_SCRIPT" ]] || return 1
  bash "$SETUP_SCRIPT"
}

# --- Direct run (inside terminal launched by autostart) ---
if [[ "${1:-}" == "--run" ]]; then
  exec 9>"$LOCK_FILE"
  flock -n 9 || exit 0
  run_setup
  exit $?
fi

# --- Launcher (manual only: bash first_run_setup.sh) ---
needs_setup || exit 0

TERM_CMD="$(resolve_terminal)"
SELF="$HOME/.config/hypr/scripts/first_run_setup.sh"

"$TERM_CMD" \
  --title "Hyprgruv — Setup Wizard" \
  -- bash "$SELF" --run &

exit 0