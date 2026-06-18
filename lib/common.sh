#!/bin/bash
# common.sh

# ANSI color codes
RESET="\e[0m"
GREEN="\e[38;2;142;192;124m"
CYAN="\e[38;2;69;133;136m"
YELLOW="\e[38;2;215;153;33m"
RED="\e[38;2;204;36;29m"
BOLD="\e[1m"

# Base directories
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSET_DIR="$HYPR_DIR/assets"
SCRIPTS="$HYPR_DIR/lib/scripts"
INSTALL_SCRIPTS="$HYPR_DIR/lib/scripts"
DOTFILES_SCRIPTS="${DOTFILES_SCRIPTS:-$HOME/.config/hyprgruv/scripts}"
REPO_DOTFILES_SCRIPTS="$HYPR_DIR/home/.config/hyprgruv/scripts"
BACKUP_DIR="$HOME/.local/backup/hyprgruv"

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Logging functions
log_status() { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# LS Terminal Colors
export LSCOLORS=GxFxCxDxbxegedabagaced

# display_header — toilet + lsd-print when available (see header.sh after stow)
display_header() {
    local title="${1:-}"
    [[ -z "$title" ]] && return 0
    echo ""
    if command -v toilet >/dev/null 2>&1; then
        if command -v lsd-print >/dev/null 2>&1; then
            toilet -f graffiti "$title" | lsd-print
        else
            toilet -f graffiti "$title"
        fi
    elif command -v gum >/dev/null 2>&1; then
        echo "$title" | gum style --foreground "${COLOR_PRIMARY:-#89b4fa}" --bold
    else
        echo "=== $title ==="
    fi
    echo ""
}
# Check if command exists
command_exists() {
	command -v "$1" >/dev/null 2>&1
}
# Run a command with proper error handling
run_command() {
	local cmd="$1"
	local description="$2"

	log_status "Running: $description"
	if eval "$cmd"; then
		log_success "$description completed"
		return 0
	else
		log_error "$description failed"
		return 1
	fi
}
# Source this at the beginning of each script
export HYPR_DIR ASSET_DIR BACKUP_DIR DOTFILES_SCRIPTS REPO_DOTFILES_SCRIPTS INSTALL_SCRIPTS


# ============== Matugen + Gum Styling ==============

_hyprgruv_load_matugen_colors() {
    local colors_sh="${HOME}/.config/hyprgruv/scripts/colors.sh"
    if [[ -f "$colors_sh" ]]; then
        # shellcheck source=/dev/null
        source "$colors_sh" 2>/dev/null && return 0
    fi
    if [[ -f "${HOME}/.cache/matugen/colors.sh" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "${HOME}/.cache/matugen/colors.sh" 2>/dev/null || true
        set +a
        return 0
    fi
    if [[ -f "${HOME}/.config/hypr/colors.conf" ]]; then
        # shellcheck source=/dev/null
        source "${HOME}/.config/hypr/colors.conf" 2>/dev/null && return 0
    fi
    return 1
}

_hyprgruv_load_matugen_colors || true

# Fallback semantic colors (matugen cache may omit a few aliases)
: "${COLOR_PRIMARY:="#89b4fa"}"
: "${COLOR_ON_PRIMARY:="#1e1e2e"}"
: "${COLOR_SECONDARY:="#89b4fa"}"
: "${COLOR_SURFACE:="#1e1e2e"}"
: "${COLOR_ON_SURFACE:="#cdd6f4"}"
: "${COLOR_SURFACE_CONTAINER:="#252535"}"
: "${COLOR_ON_SURFACE_VARIANT:="#bac2de"}"
: "${COLOR_SUCCESS:="${COLOR_TERTIARY:-#a6e3a1}"}"
: "${COLOR_ERROR:="${COLOR_ERROR:-#f38ba8}"}"
: "${COLOR_TEXT:="${COLOR_TEXT:-${COLOR_ON_SURFACE:-#cdd6f4}}"}"

# gum_apply_matugen_theme lives in colors.sh; provide a fallback if only the cache was sourced
if ! declare -F gum_apply_matugen_theme >/dev/null 2>&1; then
    gum_apply_matugen_theme() {
        export GUM_CONFIRM_PROMPT="? "
        export GUM_CONFIRM_SELECTED_BACKGROUND="${COLOR_PRIMARY}"
        export GUM_CONFIRM_SELECTED_FOREGROUND="${COLOR_ON_PRIMARY}"
        export GUM_CONFIRM_UNSELECTED_BACKGROUND="${COLOR_SURFACE_CONTAINER}"
        export GUM_CONFIRM_UNSELECTED_FOREGROUND="${COLOR_ON_SURFACE}"
        export GUM_INPUT_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_INPUT_PROMPT_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_INPUT_PLACEHOLDER_FOREGROUND="${COLOR_ON_SURFACE_VARIANT}"
        export GUM_CHOOSE_CURSOR_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_CHOOSE_SELECTED_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_FILTER_MATCH_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_SPIN_SPINNER_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_SPIN_TITLE_FOREGROUND="${COLOR_ON_SURFACE}"
        export GUM_TABLE_HEADER_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_PAGER_FOREGROUND="${COLOR_ON_SURFACE}"
    }
fi

if command -v gum >/dev/null 2>&1; then
    if declare -F load_matugen_colors >/dev/null 2>&1; then
        load_matugen_colors
    fi
    gum_apply_matugen_theme
fi

# Enhanced print functions using gum (for modern scripts)
print_section() {
    local title="$1"
    echo ""
    echo "$title" | gum style --foreground "$COLOR_PRIMARY" --bold
}

print_box() {
    local content="$1"
    echo "$content" | gum style \
        --foreground "$COLOR_TEXT" \
        --border rounded \
        --border-foreground "$COLOR_PRIMARY" \
        --padding "1 3" \
        --width 95
}

show_success() {
    gum style --foreground "$COLOR_SUCCESS" --bold "✓ $1"
}

show_error() {
    gum style --foreground "$COLOR_ERROR" --bold "✗ $1"
}

# display_header uses toilet + lsd-print when installed (header.sh matches after stow)

# ============================================================
# Pure Arch sanitization helpers (for users moving away from EndeavourOS or other derivatives)
# ============================================================

# Remove EndeavourOS repository section, mirrorlist, and packages.
# This keeps the system on pure Arch + only the repos the installer explicitly manages (multilib + chaotic-aur).
# Respects DRY_RUN=1 / TEST_MODE=1 for safe testing (no changes performed).
purge_endeavouros_remnants() {
  local conf="/etc/pacman.conf"
  if ! grep -q '^\[endeavouros\]' "$conf" 2>/dev/null; then
    return 0
  fi

  local dry=0
  [[ "${DRY_RUN:-0}" == "1" || "${TEST_MODE:-0}" == "1" ]] && dry=1

  if [[ $dry -eq 1 ]]; then
    log_warning "DRY_RUN/TEST_MODE active — would purge EndeavourOS remnants (no changes)"
    echo "[dry-run] Would remove [endeavouros] section from $conf"
    echo "[dry-run] Would rm /etc/pacman.d/endeavouros-mirrorlist if present"
    echo "[dry-run] Would pacman -Rdd endeavouros-mirrorlist endeavouros-keyring"
    echo "[dry-run] Would clean eos-* from HoldPkg"
    return 0
  fi

  log_status "Purging EndeavourOS repository remnants (pure Arch only)..."

  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  sudo cp -a "$conf" "$conf.bak.eos.$ts" 2>/dev/null || true

  # Delete the entire [endeavouros] section (until next [repo])
  sudo awk '
    BEGIN { insec=0 }
    /^\[endeavouros\]/ { insec=1; next }
    /^\[/ && insec==1 { insec=0 }
    { if (insec==0) print }
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
  sudo mv "$conf.tmp.$$" "$conf" 2>/dev/null || true

  # Remove the EOS mirrorlist file if present
  if [[ -f /etc/pacman.d/endeavouros-mirrorlist ]]; then
    sudo rm -f /etc/pacman.d/endeavouros-mirrorlist 2>/dev/null || true
    log_status "Removed /etc/pacman.d/endeavouros-mirrorlist"
  fi

  # Remove the EOS mirrorlist/keyring packages (dd to allow removal during transition)
  for p in endeavouros-mirrorlist endeavouros-keyring; do
    if pacman -Qi "$p" &>/dev/null; then
      sudo pacman -Rdd --noconfirm "$p" 2>/dev/null || true
    fi
  done

  # Strip any eos- entries from HoldPkg lines
  sudo sed -i -E '
    /^HoldPkg[[:space:]]*=/ {
      s/[[:space:]]+eos-[^ ]+//g
      s/[[:space:]]{2,}/ /g
      s/[[:space:]]+$//
    }
  ' "$conf" 2>/dev/null || true

  log_success "EndeavourOS remnants removed from pacman configuration."
}

# ============================================================
# VM / Hypervisor detection (used for guest tools, GRUB video
# compatibility, and SDDM greeter stability on virtual hardware).
# Sets IS_VM=true/false and HYPERVISOR=virtualbox|qemu|vmware|...
# Safe to call multiple times; exports the vars.
# ============================================================
detect_vm() {
  local _is_vm=false
  local _hv="none"

  # Primary reliable source
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    local v
    v="$(systemd-detect-virt 2>/dev/null || true)"
    if [[ -n "$v" && "$v" != "none" ]]; then
      _is_vm=true
      _hv="$v"
    fi
  fi

  # DMI fallback / refinement
  if [[ "$_is_vm" != true && -r /sys/class/dmi/id/product_name ]]; then
    local prod
    prod=$(cat /sys/class/dmi/id/product_name 2>/dev/null || true)
    case "$prod" in
      *VirtualBox*|*virtualbox*) _is_vm=true; _hv="virtualbox" ;;
      *VMware*|*vmware*)         _is_vm=true; _hv="vmware" ;;
      *QEMU*|*KVM*)              _is_vm=true; _hv="qemu" ;;
      *Microsoft*|*Hyper-V*|*HyperV*) _is_vm=true; _hv="hyperv" ;;
    esac
  fi

  # lspci last resort (only if we still don't have a positive ID)
  if [[ "$_is_vm" != true ]]; then
    if lspci 2>/dev/null | grep -qiE 'virtualbox|innotek.*vbox|vmware|vmxnet|qemu.*gpu|virtio.*(gpu|display)|red hat.*virt'; then
      _is_vm=true
      if   lspci 2>/dev/null | grep -qiE 'virtualbox|innotek'; then _hv="virtualbox"
      elif lspci 2>/dev/null | grep -qiE 'vmware|vmxnet';     then _hv="vmware"
      elif lspci 2>/dev/null | grep -qiE 'qemu|virtio';      then _hv="qemu"
      else                                                     _hv="generic-vm"
      fi
    fi
  fi

  # Normalize
  [[ "$_hv" == "oracle" ]] && _hv="virtualbox"
  [[ "$_hv" == "kvm"    ]] && _hv="qemu"

  # Final guard: only declare a VM when we have a concrete non-none hypervisor
  if [[ "$_is_vm" == true && "$_hv" != "none" && -n "$_hv" ]]; then
    declare -g IS_VM=true
    declare -g HYPERVISOR="$_hv"
    log_status "Virtual machine / hypervisor detected: $HYPERVISOR (guest tools + boot tweaks will be applied)"
  else
    declare -g IS_VM=false
    declare -g HYPERVISOR="none"
  fi

  export IS_VM HYPERVISOR
}

# Run detection on every source of common.sh (lightweight, idempotent)
detect_vm

