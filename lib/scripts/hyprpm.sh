#!/usr/bin/env bash
# hyprpm-setup.sh
# Purpose: Add/update/enable Hyprpm plugins (Hyprchroma + Hycov) safely & idempotently.

set -euo pipefail

# Optional: pretty output (falls back to plain echo)
log()        { command -v lsd-print >/dev/null 2>&1 && printf "%s\n" "$*" | lsd-print || printf "%s\n" "$*"; }
log_info()   { log "  $*"; }
log_ok()     { log "  $*"; }
log_warn()   { log "  $*"; }
log_err()    { log "  $*"; }

require() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log_err "Missing dependency: $1"
    exit 1
  fi
}

require hyprpm

# Optional: verify Hyprland is present (not strictly required to manage plugins)
if ! command -v hyprctl >/dev/null 2>&1; then
  log_warn "hyprctl not found. You can still manage plugins, but reload requires hyprctl."
fi

# Repos to add (url -> human name)
declare -A REPOS=(
  ["https://github.com/hyprwm/hyprland-plugins"]="hyprwm/hyprland-plugins"
  ["https://github.com/alexhulbert/Hyprchroma"]="alexhulbert/Hyprchroma"
  ["https://github.com/DreamMaoMao/hycov"]="DreamMaoMao/hycov"
)

# Plugins to enable (hyprpm package names)
PLUGINS=(
  "hyprchroma"
  "hycov"
)

retry() {
  local tries="${1:-3}"; shift
  local delay="${1:-2}"; shift
  local i
  for ((i=1; i<=tries; i++)); do
    if "$@"; then
      return 0
    fi
    log_warn "Attempt $i failed: $*"
    sleep "$delay"
  done
  return 1
}

repo_present() {
  local url="$1"
  hyprpm repos | grep -Fq -- "$url"
}

plugin_enabled() {
  local name="$1"
  hyprpm plugins | awk '{print $1,$2}' | grep -E "^\s*${name}\s+enabled$" >/dev/null 2>&1
}

plugin_installed() {
  local name="$1"
  hyprpm plugins | awk '{print $1}' | grep -Fxq -- "$name"
}

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

