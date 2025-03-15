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
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ASSETS="$SCRIPT_DIR/assets"
SCRIPTS="$SCRIPT_DIR/lib/scripts"
BACKUP_DIR="$HOME/.local/backup/hyprgruv"

# Logging functions
log_status() { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

# LS Terminal Colors
export LSCOLORS=GxFxCxDxbxegedabagaced

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Display header with figlet
display_header() {
	figlet -f "$HYPR_DIR/home/.fonts/Graffiti.flf" "$1" | lsd-print
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
 export SCRIPTS ASSETS CONFIG_DIR BACKUP_DIR

 source ~~./hyprgruv/assets/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
