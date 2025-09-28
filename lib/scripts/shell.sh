#!/usr/bin/env bash
# shell.sh — select and configure default shell (bash/zsh) with plugin setup
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/ and load helpers
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1; }
[[ -f "$HYPR_DIR/lib/state.sh"  ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh";  exit 1; }
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# ------------------------------------------------------------
# Theming for gum (optional)
# ------------------------------------------------------------
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"
export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#282828"
export GUM_INPUT_CURSOR_FOREGROUND="#282828"
export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B"
export GUM_SPIN_SPINNER_FOREGROUND="#749D91"

display_header "SHELL"

# ------------------------------------------------------------
# Ensure prerequisites
# ------------------------------------------------------------
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
ensure_cmd git "Installing git…" git

# zsh will be installed on demand if the user chooses it

# ------------------------------------------------------------
# Prompt user
# ------------------------------------------------------------
echo ""
echo "Please select your preferred shell" | lsd-print || echo "Please select your preferred shell"
sleep 0.5

shell="$(gum choose "zsh" "bash" "CANCEL")"

# ------------------------------------------------------------
# Activate bash
# ------------------------------------------------------------
if [[ "$shell" == "bash" ]]; then
  log_status "Switching default shell to bash"
  if chsh -s "$(command -v bash)"; then
    log_success "Shell is now bash."
  else
    log_error "chsh failed. Please re-run and enter the correct password."
    exit 1
  fi
  gum spin --spinner dot --title "Shell changed. Please log out/in to apply." -- sleep 2
  exit 0
fi

# ------------------------------------------------------------
# Activate zsh
# ------------------------------------------------------------
if [[ "$shell" == "zsh" ]]; then
  # Ensure zsh is installed
  ensure_cmd zsh "Installing zsh…" zsh

  log_status "Switching default shell to zsh"
  if chsh -s "$(command -v zsh)"; then
    log_success "Shell is now zsh."
  else
    log_error "chsh failed. Please re-run and enter the correct password."
    exit 1
  fi

  # Oh My Zsh plugins (only if Oh My Zsh is installed)
  ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    mkdir -p "$ZSH_CUSTOM_DIR/plugins"

    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions" ]]; then
      echo "Installing zsh-autosuggestions" | lsd-print || true
      git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM_DIR/plugins/zsh-autosuggestions"
    else
      echo "zsh-autosuggestions already installed" | lsd-print || true
    fi

    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting" ]]; then
      echo "Installing zsh-syntax-highlighting" | lsd-print || true
      git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM_DIR/plugins/zsh-syntax-highlighting"
    else
      echo "zsh-syntax-highlighting already installed" | lsd-print || true
    fi

    if [[ ! -d "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting" ]]; then
      echo "Installing fast-syntax-highlighting" | lsd-print || true
      git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
        "$ZSH_CUSTOM_DIR/plugins/fast-syntax-highlighting"
    else
      echo "fast-syntax-highlighting already installed" | lsd-print || true
    fi

    echo ""
    log_status "Add the plugins to your ~/.zshrc, e.g.:"
    echo "  plugins=(git zsh-autosuggestions zsh-syntax-highlighting fast-syntax-highlighting)"
  else
    log_status "Oh My Zsh not detected (~/.oh-my-zsh). Skipping plugin installs."
    echo "To install it later:  sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\"" | lsd-print || true
  fi

  gum spin --spinner dot --title "Shell changed. Please log out/in to apply." -- sleep 2
  exit 0
fi

# ------------------------------------------------------------
# Cancel
# ------------------------------------------------------------
echo "Changing shell canceled." | lsd-print || echo "Changing shell canceled."
exit 0
