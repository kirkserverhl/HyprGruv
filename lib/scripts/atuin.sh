#!/usr/bin/env bash
# atuin.sh — optional Atuin shell history setup (official installer)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
  exit 1
}
[[ -f "$HYPR_DIR/lib/state.sh" ]] || {
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
  exit 1
}
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

ensure_cmd() {
  local c="$1" install_msg="$2" pkg="$3"
  if ! command -v "$c" >/dev/null 2>&1; then
    log_status "$install_msg"
    if command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm "$pkg"
    else
      sudo pacman -S --needed --noconfirm "$pkg"
    fi
  fi
}

ensure_cmd gum "Installing gum…" gum
ensure_cmd curl "Installing curl…" curl

ensure_rustup_toolchain() {
  if ! command -v rustup >/dev/null 2>&1; then
    log_status "Installing rustup (required before Atuin setup)…"
    if command -v yay >/dev/null 2>&1; then
      yay -S --needed --noconfirm rustup
    else
      sudo pacman -S --needed --noconfirm rustup
    fi
  fi

  # Make rustup/cargo available in this script and the installer subshell
  if [[ -f "$HOME/.cargo/env" ]]; then
    # shellcheck source=/dev/null
    source "$HOME/.cargo/env"
  fi
  export PATH="$HOME/.cargo/bin:$PATH"

  if command -v rustc >/dev/null 2>&1; then
    log_success "Rust toolchain ready ($(rustc --version 2>/dev/null | head -1))"
    return 0
  fi

  log_status "Setting up Rust stable toolchain via rustup…"
  if rustup default stable; then
    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
    export PATH="$HOME/.cargo/bin:$PATH"
    log_success "Rust toolchain ready ($(rustc --version 2>/dev/null | head -1))"
    return 0
  fi

  log_error "Failed to configure rustup — run manually: rustup default stable"
  return 1
}

source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true
gum_apply_matugen_theme

display_header "ATUIN"

echo ""
echo "Atuin provides searchable, synced shell history."
echo "Rust (via rustup) must be configured before the installer runs."
echo "The official installer places the binary in ~/.atuin/bin and"
echo "hooks it into your shell startup files."
sleep 0.5

ensure_rustup_toolchain

atuin_ready() {
  command -v atuin >/dev/null 2>&1 || [[ -x "$HOME/.atuin/bin/atuin" ]]
}

if atuin_ready; then
  if command -v atuin >/dev/null 2>&1; then
    log_success "Atuin is already installed ($(atuin --version 2>/dev/null | head -1 || echo 'version unknown'))"
  else
    log_success "Atuin binary found at ~/.atuin/bin/atuin"
    log_status "Add ~/.atuin/bin to your PATH if it is not already there."
  fi
  exit 0
fi

log_status "Running official Atuin installer…"
if env PATH="$HOME/.cargo/bin:$PATH" \
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | env PATH="$HOME/.cargo/bin:$PATH" sh; then
  log_success "Atuin installed — open a new shell or log out/in to activate"
else
  log_error "Atuin installer failed"
  exit 1
fi