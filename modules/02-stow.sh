#!/usr/bin/env bash
# 02-stow.sh — stow user config from repo (with absolute-symlink handling)
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

#   _____ __
#  /   ______/  |_ ______  _  __
#  \_____  \\   __/  _ \ \/ \/ /
#  /        \|  |(  <_> \     /
# /_______  /|__| \____/ \/\_/
#         \/

echo ""

log_status "Starting configuration stowing process"
hyprgruv_strict_banner
hyprgruv_require_cmd yay

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
# IMPORTANT: Must NOT be inside any top-level directory that the repo stows
# (e.g. not under ~/.local, ~/.config, ~/.cache etc.). The backup loop does
# `cp -a` of those exact dirs (including ~/.local), so placing the backup root
# inside ~/.local would cause "cannot copy a directory ... into itself".
TIMESTAMP="$(date +"%Y-%m-%d_%H-%M-%S")"
BACKUP_DIR="$HOME/.hyprgruv-backups/hyprgruv_$TIMESTAMP"
mkdir -p "$BACKUP_DIR"
log_status "Backup directory: $BACKUP_DIR"
sleep 0.3

# Ensure stow present
if ! command_exists stow; then
    log_status "stow not found. Installing…"

    # IMPORTANT: Before running pacman/yay, temporarily disable [chaotic-aur] if its mirrorlist
    # file is missing. This prevents the exact error you saw:
    #   "error: config file /etc/pacman.d/chaotic-mirrorlist could not be read: No such file or directory"
    #   "error: parsing '/etc/pacman.conf'"
    #
    # This can happen if 00-preflight added the chaotic repo block but the mirrorlist
    # (installed later in 01 or 03) isn't present yet. The disable logic matches 01-packages.sh.
    local_conf="/etc/pacman.conf"
    local_ml="/etc/pacman.d/chaotic-mirrorlist"
    if grep -q '^\[chaotic-aur\]' "$local_conf" 2>/dev/null && [[ ! -f "$local_ml" ]]; then
        log_status "Temporarily disabling [chaotic-aur] for stow install (mirrorlist not ready yet)..."
        sudo awk '
    BEGIN{insec=0}
    /^\[chaotic-aur\]/{insec=1; if($0 !~ /^#/) print "# hyprgruv-stow: " $0; else print; next}
    /^\[/ && insec==1 {insec=0; print; next}
    {
      if(insec==1) {
        if($0 !~ /^#/) print "# hyprgruv-stow: " $0; else print
      } else {
        print
      }
    }
  ' "$local_conf" | sudo tee "$local_conf.tmp.$$" >/dev/null
        sudo mv "$local_conf.tmp.$$" "$local_conf"
    fi

    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm stow || hyprgruv_strict_abort "Failed to install stow via yay"
    else
        sudo pacman -S --needed --noconfirm stow || hyprgruv_strict_abort "Failed to install stow via pacman"
    fi
fi
hyprgruv_require_cmd stow

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
if ! (
    cd "$REPO_DIR"
    stow "${STOW_ARGS[@]}"
); then
    hyprgruv_strict_abort "GNU stow failed"
fi

log_success "Stow succeeded for non-conflicting paths"

# Hyprland configs reference ~/.config/hyprgruv/scripts — ensure that tree exists.
if ! bash "$HYPR_DIR/lib/scripts/ensure-dotfiles.sh"; then
    log_error "hyprgruv dotfiles missing after stow (keybinds will fail)"
    exit 1
fi

# --------------------------------------------------------------------
# Recreate the previously ignored items as symlinks in $HOME
# --------------------------------------------------------------------

# 1) GTK 4.0 — Gruvbox assets (system theme or bundled colorscheme fallback)
_hyprgruv_resolve_gruvbox_gtk4_dir() {
    local candidate bundled
    for candidate in \
        "/usr/share/themes/Gruvbox-Dark/gtk-4.0" \
        "/usr/share/themes/Gruvbox-Dark-hc/gtk-4.0" \
        "/usr/share/themes/Gruvbox-Dark-hc-b/gtk-4.0"; do
        [[ -d "$candidate/assets" ]] || continue
        echo "$candidate"
        return 0
    done
    for bundled in \
        "$HOME/.config/colorschemes/gruvbox-dark/gtk-4.0" \
        "$REPO_DIR/$PKG_DIR/.config/colorschemes/gruvbox-dark/gtk-4.0"; do
        [[ -d "$bundled/assets" ]] || continue
        echo "$bundled"
        return 0
    done
    return 1
}

GTK_SYS_DIR="$(_hyprgruv_resolve_gruvbox_gtk4_dir || true)"
if [[ -z "$GTK_SYS_DIR" ]] && command -v yay >/dev/null 2>&1; then
    log_status "Gruvbox GTK theme not found — installing gruvbox-gtk-theme-git…"
    yay -S --needed --noconfirm gtk-engine-murrine gruvbox-gtk-theme-git 2>/dev/null || \
        log_warning "Could not install gruvbox-gtk-theme-git (will use bundled assets if available)"
    GTK_SYS_DIR="$(_hyprgruv_resolve_gruvbox_gtk4_dir || true)"
fi

if [[ -z "$GTK_SYS_DIR" ]]; then
    hyprgruv_strict_abort "Gruvbox GTK 4 assets missing (expected system theme or ~/.config/colorschemes/gruvbox-dark/gtk-4.0)"
fi

log_status "GTK 4 Gruvbox source: $GTK_SYS_DIR"
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
        hyprgruv_strict_abort "Missing theme asset: $target"
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

# 3) starship.toml — matugen rainbow theme (updated by matugen on wallpaper change)
mkdir -p "$HOME/.config/starship"
STARSHIP_THEME="matugen-rainbow.toml"
if [[ -f "$HOME/.config/starship/$STARSHIP_THEME" ]]; then
    ln -sfn "$HOME/.config/starship/$STARSHIP_THEME" "$HOME/.config/starship.toml"
    log_status "Linked: ~/.config/starship.toml -> ~/.config/starship/$STARSHIP_THEME"
elif [[ -f "$REPO_DIR/$PKG_DIR/.config/starship/$STARSHIP_THEME" ]]; then
    cp -a "$REPO_DIR/$PKG_DIR/.config/starship/$STARSHIP_THEME" "$HOME/.config/starship/$STARSHIP_THEME"
    ln -sfn "$HOME/.config/starship/$STARSHIP_THEME" "$HOME/.config/starship.toml"
    log_status "Installed and linked starship theme: $STARSHIP_THEME"
else
    hyprgruv_strict_abort "starship theme $STARSHIP_THEME not found in $HOME or repo"
fi

hyprgruv_require_cmd stow
[[ -d "$HOME/.config/hyprgruv/scripts" ]] || hyprgruv_strict_abort "hyprgruv scripts missing after stow"

log_success "Configuration files applied"
log_status "Backup saved to: $BACKUP_DIR"
save_choice "last_backup" "$BACKUP_DIR"

sleep 0.5
clear
exit 0
