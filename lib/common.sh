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
