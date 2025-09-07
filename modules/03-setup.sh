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
declare -a ORDERED_SCRIPTS=(
  "hard_copy.sh|Hard Copy files in root directory"
  "default_wp.sh|Load default wallpaper"
  "chaotic.sh|Configure Chaotic-AUR pacman mirrors"
  "hyprpm.sh|Install Hyprpm plugins"
)

any_failed=0
for entry in "${ORDERED_SCRIPTS[@]}"; do
  script_name="${entry%%|*}"
  description="${entry#*|}"
  script_path="$SCRIPTS_DIR/$script_name"

  # If repo still has old typo, auto-fallback
  if [[ ! -f "$script_path" && "$script_name" == "chaotic.sh" && -f "$SCRIPTS_DIR/chatoic.sh" ]]; then
    script_path="$SCRIPTS_DIR/chatoic.sh"
    description="Configure Chaotic-AUR pacman mirrors (chatoic.sh)"
  fi

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

mark_completed "Setup system"
clear
log_success "Setup completed"


