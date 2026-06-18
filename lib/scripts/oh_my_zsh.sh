#!/usr/bin/env bash
# oh_my_zsh.sh — install Oh My Zsh + Hyprgruv custom plugins (not vendored in repo)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true
command -v gum_apply_matugen_theme >/dev/null 2>&1 && gum_apply_matugen_theme 2>/dev/null || true

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OMZ_DIR/custom}"
PLUGINS_DIR="$ZSH_CUSTOM_DIR/plugins"

# name|git-url — must match plugins=() in home/.zshrc
OMZ_CUSTOM_PLUGINS=(
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions"
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git"
)

oh_my_zsh_installed() {
  [[ -d "$OMZ_DIR" && -f "$OMZ_DIR/oh-my-zsh.sh" ]]
}

install_oh_my_zsh() {
  if oh_my_zsh_installed; then
    log_success "Oh My Zsh already installed at $OMZ_DIR"
    return 0
  fi

  command -v git >/dev/null 2>&1 || {
    log_error "git is required to install Oh My Zsh"
    return 1
  }

  log_status "Installing Oh My Zsh to $OMZ_DIR …"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

  if oh_my_zsh_installed; then
    log_success "Oh My Zsh installed"
    return 0
  fi

  log_error "Oh My Zsh install finished but $OMZ_DIR/oh-my-zsh.sh is missing"
  return 1
}

install_oh_my_zsh_plugins() {
  if ! oh_my_zsh_installed; then
    log_warning "Oh My Zsh not installed — skipping custom plugins"
    return 1
  fi

  mkdir -p "$PLUGINS_DIR"
  local entry name url
  for entry in "${OMZ_CUSTOM_PLUGINS[@]}"; do
    name="${entry%%|*}"
    url="${entry#*|}"
    if [[ -d "$PLUGINS_DIR/$name" ]]; then
      log_status "Plugin already installed: $name"
      continue
    fi
    log_status "Installing OMZ plugin: $name"
    git clone --depth 1 "$url" "$PLUGINS_DIR/$name"
  done
  log_success "Oh My Zsh custom plugins ready"
}

prompt_install_oh_my_zsh() {
  if oh_my_zsh_installed; then
    return 0
  fi
  if command -v gum >/dev/null 2>&1; then
    gum confirm "Install Oh My Zsh? (official installer → ~/.oh-my-zsh)"
  else
    local ans
    read -rp "Install Oh My Zsh? [y/N]: " ans
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
  fi
}

setup_oh_my_zsh_interactive() {
  if oh_my_zsh_installed; then
    log_status "Oh My Zsh present — ensuring custom plugins only"
    install_oh_my_zsh_plugins
    return 0
  fi

  if prompt_install_oh_my_zsh; then
    install_oh_my_zsh
    install_oh_my_zsh_plugins
  else
    log_status "Oh My Zsh install skipped"
    log_status "Install later: RUNZSH=no CHSH=no sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
    return 0
  fi
}