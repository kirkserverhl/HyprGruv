#!/usr/bin/env bash
# hyprpm.sh — add/enable Hyprland plugins
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
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

display_header "Hyprpm Plugins"

# Ensure hyprpm exists
if ! command -v hyprpm >/dev/null 2>&1; then
  log_error "hyprpm not found. Ensure Hyprland/hyprpm is installed and on PATH."
  exit 1
fi

# Add plugin repos (idempotent)
log_status "Adding plugin repositories"
hyprpm add https://github.com/hyprwm/hyprland-plugins || true    # hyprwm
sleep 0.2
hyprpm add https://github.com/alexhulbert/Hyprchroma || true     # hyprchroma
sleep 0.2
hyprpm add https://github.com/DreamMaoMao/hycov || true          # hycov
sleep 0.2

# Enable specific plugins (idempotent)
log_status "Enabling plugins"
hyprpm enable hyprchroma || true
hyprpm enable hycov || true
sleep 0.2

# Update plugins
log_status "Updating hyprpm plugins"
if command -v lsd-print >/dev/null 2>&1; then
  hyprpm update | lsd-print
else
  hyprpm update
fi

log_success "Hyprpm plugins configured"


add_repo() {
  local url="$1" label="$2"
  if repo_present "$url"; then
    log_ok "Repo already added: $label"
  else
    log_info "Adding repo: $label"
    retry 3 2 hyprpm add "$url" || { log_err "Failed to add $label"; exit 1; }
    log_ok "Added repo: $label"
  fi
}

enable_plugin() {
  local name="$1"
  if plugin_enabled "$name"; then
    log_ok "Plugin already enabled: $name"
    return
  fi
  if ! plugin_installed "$name"; then
    log_info "Installing plugin: $name"
    retry 3 2 hyprpm update >/dev/null || true
  fi
  log_info "Enabling plugin: $name"
  retry 3 2 hyprpm enable "$name" || { log_err "Failed to enable $name"; exit 1; }
  log_ok "Enabled plugin: $name"
}

log_info "Configuring Hyprpm repositories…"
for url in "${!REPOS[@]}"; do
  add_repo "$url" "${REPOS[$url]}"
done

log_info "Updating Hyprpm plugin index…"
retry 3 2 hyprpm update >/dev/null && log_ok "Hyprpm updated."

log_info "Enabling desired plugins…"
for p in "${PLUGINS[@]}"; do
  enable_plugin "$p"
done

# Optional: reload Hyprland to apply plugins immediately
if command -v hyprctl >/dev/null 2>&1; then
  log_info "Reloading Hyprland config…"
  if hyprctl reload >/dev/null 2>&1; then
    log_ok "Hyprland reloaded."
  else
    log_warn "Couldn’t reload via hyprctl. Reload manually if needed."
  fi
fi

log_ok "Hyprpm setup complete."

