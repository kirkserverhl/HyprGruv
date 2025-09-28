#!/usr/bin/env bash
# 02-stow.sh — stow user config from repo (with absolute-symlink handling)
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

log_status "Starting configuration stowing process"

# Paths
REPO_DIR="$HYPR_DIR"
PKG_DIR="home"
TARGET="$HOME"

# Sanity
if [[ ! -d "$REPO_DIR/$PKG_DIR" ]]; then
  log_error "Expected package dir not found: $REPO_DIR/$PKG_DIR"
  exit 1
fi

# Timestamped backup dir
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
BACKUP_DIR="$HOME/.local/backup/hyprgruv_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
log_status "Backup directory: $BACKUP_DIR"
sleep 0.3

# Ensure stow present
if ! command_exists stow; then
  log_status "stow not found. Installing…"
  if command -v yay >/dev/null 2>&1; then
    yay -S --needed --noconfirm stow
  else
    sudo pacman -S --needed --noconfirm stow
  fi
fi

# Back up top-level entries under home/ that would be affected
log_status "Backing up existing files that would be replaced"
while IFS= read -r entry; do
  name="$(basename "$entry")"
  src_rel="$name"
  target_path="$TARGET/$src_rel"
  if [[ -e "$target_path" || -L "$target_path" ]]; then
    dest_path="$BACKUP_DIR/$src_rel"
    mkdir -p "$(dirname "$dest_path")"
    log_status "Backing up: ~/$src_rel"
    cp -a "$target_path" "$dest_path"
  fi
done < <(find "$REPO_DIR/$PKG_DIR" -mindepth 1 -maxdepth 1 -print)

sleep 0.2

# Special-case: move any existing Hypr config to backup (rather than delete)
if [[ -e "$HOME/.config/hypr" || -L "$HOME/.config/hypr" ]]; then
  mv "$HOME/.config/hypr" "$BACKUP_DIR/.config_hypr.pre-stow"
  log_status "Moved existing ~/.config/hypr to backup"
fi

# --------------------------------------------------------------------
# Ignore absolute-symlinked sources that make stow abort
# We'll create the desired links in $HOME after stow completes.
# Adjust patterns if your repo layout changes.
# --------------------------------------------------------------------
IGNORE_PATTERNS=(
  '^\.config/gtk-4\.0/.*$'
  '^\.config/pacseek/pacseek$'
  '^\.config/starship\.toml$'
)

STOW_ARGS=(-v -t "$TARGET" "$PKG_DIR" --adopt)
for pat in "${IGNORE_PATTERNS[@]}"; do
  STOW_ARGS+=(--ignore "$pat")
done

log_status "Applying configurations with GNU Stow (--adopt, with ignores)"
(
  cd "$REPO_DIR"
  stow "${STOW_ARGS[@]}"
)

log_success "Stow succeeded for non-conflicting paths"

# --------------------------------------------------------------------
# Recreate the previously ignored items as symlinks in $HOME
# --------------------------------------------------------------------

# 1) GTK 4.0 files linking to Gruvbox system theme assets
GTK_SYS_DIR="/usr/share/themes/Gruvbox-Dark/gtk-4.0"
mkdir -p "$HOME/.config/gtk-4.0"

declare -A GTK_LINKS=(
  ["$HOME/.config/gtk-4.0/assets"]="$GTK_SYS_DIR/assets"
  ["$HOME/.config/gtk-4.0/gtk.css"]="$GTK_SYS_DIR/gtk.css"
  ["$HOME/.config/gtk-4.0/gtk-dark.css"]="$GTK_SYS_DIR/gtk-dark.css"
)

for link in "${!GTK_LINKS[@]}"; do
  target="${GTK_LINKS[$link]}"
  if [[ -e "$target" || -L "$target" ]]; then
    ln -sfn "$target" "$link"
    log_status "Linked: $link -> $target"
  else
    log_error "Missing theme asset: $target (install Gruvbox-Dark GTK theme?)"
  fi
done

# 2) pacseek config — your repo had an odd absolute symlink.
# Prefer: copy or symlink a real config file/dir.
# If your repo has defaults at home/.config/pacseek/, copy them in:
if [[ -d "$REPO_DIR/$PKG_DIR/.config/pacseek" ]]; then
  mkdir -p "$HOME/.config/pacseek"
  cp -an "$REPO_DIR/$PKG_DIR/.config/pacseek/." "$HOME/.config/pacseek/" || true
  log_status "Ensured pacseek config in ~/.config/pacseek"
fi
# If you really want a symlink, set LINK_TO somewhere valid, e.g.:
# ln -sfn "$HOME/.config/pacseek/config.toml" "$HOME/.config/pacseek/pacseek"

# 3) starship.toml — point to your preferred theme file
mkdir -p "$HOME/.config/starship"
if [[ -f "$HOME/.config/starship/chevron.toml" ]]; then
  ln -sfn "$HOME/.config/starship/chevron.toml" "$HOME/.config/starship.toml"
  log_status "Linked: ~/.config/starship.toml -> ~/.config/starship/chevron.toml"
else
  # If your theme file lives in the repo, fallback copy:
  if [[ -f "$REPO_DIR/$PKG_DIR/.config/starship/chevron.toml" ]]; then
    mkdir -p "$HOME/.config/starship"
    cp -a "$REPO_DIR/$PKG_DIR/.config/starship/chevron.toml" "$HOME/.config/starship/chevron.toml"
    ln -sfn "$HOME/.config/starship/chevron.toml" "$HOME/.config/starship.toml"
    log_status "Installed and linked starship theme"
  else
    log_error "starship theme chevron.toml not found in $HOME or repo; skip linking"
  fi
fi

log_success "Configuration files applied"
log_status "Backup saved to: $BACKUP_DIR"
save_choice "last_backup" "$BACKUP_DIR"

sleep 0.5
clear
exit 0

