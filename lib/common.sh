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

# Simple functional display_header (gum if available for a bit of polish, otherwise plain)
display_header() {
    echo ""
    if command -v gum >/dev/null 2>&1; then
        echo "$1" | gum style --foreground "${COLOR_PRIMARY:-#89b4fa}" --bold
    else
        echo "=== $1 ==="
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
export HYPR_DIR ASSET_DIR BACKUP_DIR


# ============== Matugen + Gum Styling (Added for consistency) ==============

# Source matugen colors if available
if [ -f ~/.cache/matugen/colors.sh ]; then
    source ~/.cache/matugen/colors.sh
elif [ -f ~/.config/hypr/colors.conf ]; then
    source ~/.config/hypr/colors.conf
fi

# Fallback colors
: "${COLOR_PRIMARY:="#89b4fa"}"
: "${COLOR_SUCCESS:="#a6e3a1"}"
: "${COLOR_ERROR:="#f38ba8"}"
: "${COLOR_TEXT:="#cdd6f4"}"

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

# display_header is defined above; no figlet/lsd-print dependency (kept functional + optional gum polish)

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
