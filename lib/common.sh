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

# Fail-fast install mode (default on for VM testing). Set HYPRGRUV_STRICT=0 to relax.
: "${HYPRGRUV_STRICT:=1}"
export HYPRGRUV_STRICT

hyprgruv_strict_enabled() { [[ "${HYPRGRUV_STRICT:-1}" == "1" ]]; }

hyprgruv_strict_abort() {
    local msg="${1:-install step failed}"
    log_error "$msg"
    if hyprgruv_strict_enabled; then
        log_error "HYPRGRUV_STRICT=1 — aborting (set HYPRGRUV_STRICT=0 to continue past non-fatal issues)"
        exit 1
    fi
    log_warning "Continuing despite error (HYPRGRUV_STRICT=0)"
    return 0
}

hyprgruv_strict_banner() {
    if hyprgruv_strict_enabled; then
        log_status "HYPRGRUV_STRICT=1 — fail-fast mode (no skip flags, no soft-fail continues)"
    else
        log_warning "HYPRGRUV_STRICT=0 — relaxed mode (warnings may continue install)"
    fi
}

hyprgruv_forbid_skip_var() {
    local var_name="$1"
    local label="${2:-$var_name}"
    if hyprgruv_strict_enabled && [[ "${!var_name:-0}" == "1" ]]; then
        hyprgruv_strict_abort "${label}=1 is forbidden while HYPRGRUV_STRICT=1"
    fi
}

hyprgruv_require_cmd() {
    local cmd="$1"
    command -v "$cmd" &>/dev/null && return 0
    hyprgruv_strict_abort "Required command not found: $cmd"
}

hyprgruv_require_pkg() {
    local pkg="$1"
    pacman -Qq "$pkg" &>/dev/null && return 0
    hyprgruv_strict_abort "Required package not installed: $pkg"
}

hyprgruv_verify_pkgs() {
    local missing=()
    local pkg
    for pkg in "$@"; do
        pacman -Qq "$pkg" &>/dev/null || missing+=("$pkg")
    done
    if ((${#missing[@]})); then
        hyprgruv_strict_abort "Required packages missing: ${missing[*]}"
    fi
}

hyprgruv_require_service_enabled() {
    local unit="$1"
    if systemctl is-enabled "$unit" &>/dev/null; then
        return 0
    fi
    hyprgruv_strict_abort "Required systemd unit not enabled: $unit"
}

hyprgruv_enable_pipewire_services() {
    # PipeWire ships user units only (/usr/lib/systemd/user/), not system units.
    local units=(
        pipewire.socket
        pipewire-pulse.socket
        pipewire.service
        pipewire-pulse.service
        wireplumber.service
    )

    if command -v loginctl &>/dev/null && [[ -n "${USER:-}" ]]; then
        if ! loginctl show-user "$USER" -p Linger --value 2>/dev/null | grep -qx yes; then
            log_status "Enabling systemd linger for $USER (PipeWire starts at boot)"
            sudo loginctl enable-linger "$USER" \
                || log_warning "Could not enable linger for $USER"
        fi
    fi

    if systemctl --user is-system-running &>/dev/null; then
        systemctl --user enable --now "${units[@]}" \
            || hyprgruv_strict_abort "Failed to enable PipeWire user services"
    else
        systemctl --user enable "${units[@]}" \
            || hyprgruv_strict_abort "Failed to enable PipeWire user services"
        log_warning "PipeWire enabled for next login (no active user dbus session)"
    fi
}

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

# colors.sh can export -f load_matugen_colors into the parent shell environment.
# Child install scripts inherit only the function body (helpers stay behind),
# which breaks under set -u with "environment: line N: … command not found".
unset -f load_matugen_colors gum_apply_matugen_theme gum_use_matugen \
    _load_from_cache_shell _load_from_hypr_conf _load_from_json 2>/dev/null || true

_hyprgruv_load_matugen_colors() {
    local colors_sh="${DOTFILES_SCRIPTS}/colors.sh"
    local repo_colors_sh="${REPO_DOTFILES_SCRIPTS}/colors.sh"
    local repo_defaults="${HYPR_DIR}/lib/defaults/matugen-colors.sh"
    if [[ -f "${HOME}/.cache/matugen/colors.sh" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "${HOME}/.cache/matugen/colors.sh" 2>/dev/null || true
        set +a
        return 0
    fi
    if [[ -f "$colors_sh" ]]; then
        # shellcheck source=/dev/null
        source "$colors_sh" 2>/dev/null && return 0
    fi
    if [[ -f "$repo_colors_sh" ]]; then
        # shellcheck source=/dev/null
        source "$repo_colors_sh" 2>/dev/null && return 0
    fi
    if [[ -f "$repo_defaults" ]]; then
        # shellcheck source=/dev/null
        set -a
        source "$repo_defaults" 2>/dev/null || true
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
        export GUM_CHOOSE_CURSOR_FOREGROUND="${COLOR_ON_PRIMARY}"
        export GUM_CHOOSE_CURSOR_BACKGROUND="${COLOR_PRIMARY}"
        export GUM_CHOOSE_SELECTED_FOREGROUND="${COLOR_ON_PRIMARY}"
        export GUM_CHOOSE_SELECTED_BACKGROUND="${COLOR_PRIMARY}"
        export GUM_CHOOSE_ITEM_FOREGROUND="${COLOR_ON_SURFACE}"
        export GUM_CHOOSE_CURSOR_PREFIX="› "
        export GUM_CHOOSE_SELECTED_PREFIX="✓ "
        export GUM_CHOOSE_UNSELECTED_PREFIX="  "
        export GUM_FILTER_MATCH_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_SPIN_SPINNER_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_SPIN_TITLE_FOREGROUND="${COLOR_ON_SURFACE}"
        export GUM_TABLE_HEADER_FOREGROUND="${COLOR_PRIMARY}"
        export GUM_PAGER_FOREGROUND="${COLOR_ON_SURFACE}"
    }
fi

# True when the session can open the controlling terminal (needed for gum UI under tee logging).
_hyprgruv_has_tty() {
    [[ -e /dev/tty ]] && { : </dev/tty; } 2>/dev/null
}

# Run interactive scripts with a real TTY so gum can render confirm/choose UI.
# install.sh and post_reboot_setup.sh pipe stdout to tee for logging, which hides gum boxes.
hyprgruv_run_interactive() {
    local path="$1"
    local logfile="${2:-${HYPRGRUV_LOGFILE:-}}"
    local -a cmd=(bash "$path")

    if _hyprgruv_has_tty; then
        if [[ -n "$logfile" ]] && command -v script >/dev/null 2>&1; then
            script -q -e -a "$logfile" -c "$(printf '%q ' "${cmd[@]}")" </dev/tty >/dev/tty
            return $?
        fi
        "${cmd[@]}" </dev/tty >/dev/tty
        return $?
    fi

    log_warning "No controlling TTY — gum UI may be minimal; prompts still accept y/n and arrow keys."

    if [[ -n "$logfile" ]]; then
        "${cmd[@]}" 2>&1 | tee -a "$logfile"
        return "${PIPESTATUS[0]}"
    fi
    "${cmd[@]}"
}

gum_confirm_prompt() {
    local prompt="$1"
    shift || true
    gum_apply_matugen_theme 2>/dev/null || true
    if _hyprgruv_has_tty && ! [[ -t 1 ]]; then
        gum confirm "$prompt" \
            --affirmative "  Yes  " --negative "  No  " \
            "$@" </dev/tty >/dev/tty
    else
        gum confirm "$prompt" \
            --affirmative "  Yes  " --negative "  No  " \
            "$@"
    fi
}

gum_choose_prompt() {
    gum_apply_matugen_theme 2>/dev/null || true
    if _hyprgruv_has_tty && ! [[ -t 1 ]]; then
        gum choose "$@" </dev/tty >/dev/tty
    else
        gum choose "$@"
    fi
}

# Wipe noisy script output, then show a clean hand-off into the next prompt.
# Typical flow: transition → section_intro → gum confirm/choose.
hyprgruv_section_transition() {
    local message="${1:-}"
    local kind="${2:-success}"

    sleep 0.3
    clear
    echo ""
    if [[ -n "$message" ]]; then
        case "$kind" in
            success) log_success "$message" ;;
            status)  log_status "$message" ;;
            *)       echo "$message" ;;
        esac
        echo ""
    fi
}

hyprgruv_section_intro() {
    local title="$1"
    display_header "$title"
    sleep 0.3
}

if command -v gum >/dev/null 2>&1; then
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

# Install yay from AUR when missing (idempotent). Used in preflight and packages.
ensure_yay() {
    command -v yay &>/dev/null && return 0
    log_status "Installing yay (AUR helper)…"
    sudo pacman -S --needed --noconfirm git base-devel || return 1
    local tmpdir
    tmpdir="$(mktemp -d)"
    if ! (
        cd "$tmpdir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    ); then
        rm -rf "$tmpdir"
        log_error "yay build/install failed"
        return 1
    fi
    rm -rf "$tmpdir"
    if ! command -v yay &>/dev/null; then
        log_error "yay installation failed (binary not on PATH)"
        return 1
    fi
    log_success "yay installed."
}

# Installed in 00-preflight before any other installer work.
# Still listed in lib/packages/*.list for sync-packages.sh — filtered out of 01-packages.sh.
HYPRGRUV_BOOTSTRAP_PACMAN_PKGS=(
    hyprland
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    gum
    hyprland-protocols
    cmake
)
HYPRGRUV_BOOTSTRAP_AUR_PKGS=(
    waypaper-git
    waypaper-engine
)

hyprgruv_filter_bootstrap_from_manifest() {
    local -n _pkgs=$1
    local -a filtered=()
    local pkg skip
    for pkg in "${_pkgs[@]}"; do
        skip=0
        for b in "${HYPRGRUV_BOOTSTRAP_PACMAN_PKGS[@]}" "${HYPRGRUV_BOOTSTRAP_AUR_PKGS[@]}"; do
            [[ "$pkg" == "$b" ]] && { skip=1; break; }
        done
        ((skip)) || filtered+=("$pkg")
    done
    _pkgs=("${filtered[@]}")
}

hyprgruv_waypaper_installed() {
    command -v waypaper &>/dev/null && return 0
    pacman -Qq waypaper &>/dev/null && return 0
    pacman -Qq waypaper-git &>/dev/null && return 0
    return 1
}

ensure_aur_pkg() {
    local pkg="$1"
    pacman -Qq "$pkg" &>/dev/null && return 0
    hyprgruv_require_cmd yay
    log_status "Installing AUR package: $pkg"
    yay -S --needed --noconfirm "$pkg"
}

ensure_waypaper_pkg() {
    hyprgruv_waypaper_installed && return 0
    log_status "Installing waypaper…"
    if pacman -Si waypaper &>/dev/null 2>&1; then
        sudo pacman -S --needed --noconfirm waypaper
        return 0
    fi
    hyprgruv_require_cmd yay
    if yay -Si waypaper-git &>/dev/null 2>&1; then
        yay -S --needed --noconfirm waypaper-git
    else
        yay -S --needed --noconfirm waypaper
    fi
}

ensure_hyprpm_cmd() {
    if command -v hyprpm &>/dev/null; then
        return 0
    fi
    log_error "hyprpm not found — install hyprland first (provides /usr/bin/hyprpm)"
    return 1
}

# yay → hyprland/hyprpm → gum → waypaper stack. Called at the start of 00-preflight.sh.
ensure_bootstrap_stack() {
    log_status "Bootstrapping essential tools (yay, Hyprland, hyprpm, gum, waypaper)…"

    ensure_yay || return 1

    if ! pacman -Si hyprland &>/dev/null 2>&1; then
        log_status "Refreshing package databases (bootstrap)…"
        sudo pacman -Sy --noconfirm || return 1
    fi

    local pkgs=() p
    for p in "${HYPRGRUV_BOOTSTRAP_PACMAN_PKGS[@]}"; do
        pacman -Qq "$p" &>/dev/null || pkgs+=("$p")
    done
    if ((${#pkgs[@]})); then
        log_status "Installing bootstrap packages: ${pkgs[*]}"
        sudo pacman -S --needed --noconfirm "${pkgs[@]}" || return 1
    fi

    ensure_hyprpm_cmd || return 1
    log_success "hyprpm available (from hyprland)"

    ensure_waypaper_pkg || return 1
    local aur_pkg
    for aur_pkg in "${HYPRGRUV_BOOTSTRAP_AUR_PKGS[@]}"; do
        # waypaper-git is handled by ensure_waypaper_pkg; skip duplicate install attempt
        [[ "$aur_pkg" == "waypaper-git" ]] && continue
        ensure_aur_pkg "$aur_pkg" || return 1
    done

    hyprgruv_require_cmd yay
    hyprgruv_require_cmd gum
    hyprgruv_require_pkg hyprland
    hyprgruv_require_cmd hyprpm
    hyprgruv_waypaper_installed || hyprgruv_strict_abort "waypaper binary not available after install"
    hyprgruv_require_pkg waypaper-engine

    log_success "Bootstrap stack ready (yay, hyprland, hyprpm, gum, waypaper, waypaper-engine)"
    return 0
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

# Shared install/setup closing output (avoid duplicating across install.sh + post_reboot_setup.sh)
hyprgruv_print_completed_steps() {
    echo "Completed steps:"
    if command_exists jq && [[ -f "${STATE_FILE:-}" ]]; then
        jq -r '.completed_steps[]' "$STATE_FILE" | while read -r step; do
            echo "  ✅ $step"
        done
    elif [[ -f "${ASSET_DIR:-}/completed_steps.txt" ]]; then
        while read -r step; do
            echo "  ✅ $step"
        done <"$ASSET_DIR/completed_steps.txt"
    fi
}

hyprgruv_print_common_keybinds() {
    cat <<'EOF'

Common keybinds:
  Win + ENTER         Terminal
  Win + B             Brave  |  Alt + B Chrome  |  Win + Alt + B Firefox
  Win + F             Thunar
  Win + N             NeoVim
  Win + Q             Close Window
  Win + SPACE         App launcher (favorites)
  Win + CTRL + Q      Logout

Full keybinds: Win + K  or type 'keybinds' in a terminal
EOF
}

# mode: install (invoked from install.sh) | standalone (post-reboot wizard alone)
hyprgruv_print_setup_footer() {
    local mode="${1:-standalone}"

    hyprgruv_print_common_keybinds

    case "$mode" in
    install)
        cat <<'EOF'

On first Hyprland login, HyprGruv syncs packages in the background and opens Settings.
EOF
        ;;
    *)
        cat <<'EOF'

Re-run this wizard any time:
  FORCE=1 bash ~/.hyprgruv/lib/scripts/post_reboot_setup.sh

On first Hyprland login, HyprGruv syncs packages in the background and opens Settings.
Uncheck "Don't show welcome on startup" in Settings to skip future welcomes.
EOF
        ;;
    esac
}

