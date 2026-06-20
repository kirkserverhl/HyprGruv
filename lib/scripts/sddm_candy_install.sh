#!/usr/bin/env bash
# sddm_candy_install.sh — install Sugar Candy SDDM theme + hyprgruv config drop-ins
#
# Wallpaper flow (no reinstall needed day-to-day):
#   waypaper post_command → set_wallpaper.sh → update-sddm-wallpaper.sh
#   overwrites /usr/share/sddm/themes/sugar-candy/sddm-wallpaper.png in place.
#   theme.conf Background= always points at that path.
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# shellcheck source=/dev/null
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
ASSET_DIR="$HYPR_DIR/assets/sddm"
THEMES_DIR="/usr/share/sddm/themes"
CONF_DIR="/etc/sddm.conf.d"
THEME_NAME="sugar-candy"
THEME_SRC="$ASSET_DIR/$THEME_NAME"
CONF_SRC="$ASSET_DIR/sddm.conf.d"
CONF_DEST="$CONF_DIR/50-hyprgruv.conf"
UPDATE_SDDM="$HOME/.config/hyprgruv/scripts/update-sddm-wallpaper.sh"

display_header "SDDM Theme"

resolve_desktop_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        printf '%s\n' "$SUDO_USER"
        return 0
    fi
    printf '%s\n' "${USER:-$(id -un)}"
}

DESKTOP_USER="$(resolve_desktop_user)"
DESKTOP_UID="$(id -u "$DESKTOP_USER" 2>/dev/null || id -u)"

ensure_sddm() {
    if pacman -Qq sddm &>/dev/null; then
        return 0
    fi
    log_status "sddm not found — installing…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm sddm
    else
        sudo pacman -S --needed --noconfirm sddm
    fi
    pacman -Qq sddm &>/dev/null || {
        log_error "sddm package is not installed"
        return 1
    }
    log_success "sddm installed"
}

ensure_qt6_virtualkeyboard() {
    if pacman -Qq qt6-virtualkeyboard &>/dev/null; then
        return 0
    fi
    log_status "Installing qt6-virtualkeyboard (Sugar Candy on-screen keyboard)…"
    sudo pacman -S --needed --noconfirm qt6-virtualkeyboard
}

apply_qt6_compat() {
    local theme_dir="$1" qml meta
    for qml in "$theme_dir"/Main.qml "$theme_dir"/Components/*.qml; do
        [[ -f "$qml" ]] || continue
        if grep -q 'import QtGraphicalEffects 1.0' "$qml" 2>/dev/null; then
            sudo sed -i 's|import QtGraphicalEffects 1.0|import Qt5Compat.GraphicalEffects|g' "$qml"
            log_status "Patched Qt6 compat in $(basename "$qml")"
        fi
    done

    meta="$theme_dir/metadata.desktop"
    if [[ -f "$meta" ]] && ! grep -q '^QtVersion=6' "$meta" 2>/dev/null; then
        echo 'QtVersion=6' | sudo tee -a "$meta" >/dev/null
        log_status "Set QtVersion=6 in metadata.desktop"
    fi
}

# ------------------------------------------------------------
# Require SDDM + shipped assets
# ------------------------------------------------------------
ensure_sddm
ensure_qt6_virtualkeyboard

if [[ ! -d "$ASSET_DIR" ]]; then
    log_error "Assets not found: $ASSET_DIR"
    exit 1
fi
if [[ ! -d "$THEME_SRC" ]]; then
    log_error "Theme directory not found: $THEME_SRC"
    exit 1
fi
if [[ ! -d "$CONF_SRC" ]]; then
    log_error "SDDM config directory not found: $CONF_SRC"
    exit 1
fi

shopt -s nullglob
conf_src_files=("$CONF_SRC"/*)
shopt -u nullglob
if ((${#conf_src_files[@]} == 0)); then
    log_error "No config files found in $CONF_SRC"
    exit 1
fi

# ------------------------------------------------------------
# Install theme
# ------------------------------------------------------------
THEME_DEST="$THEMES_DIR/$THEME_NAME"
PRESERVE_WP=""

log_status "Preparing target directories…"
sudo install -d -m 0755 "$THEMES_DIR"
sudo install -d -m 0755 "$CONF_DIR"

if [[ -f "$THEME_DEST/sddm-wallpaper.png" ]]; then
    PRESERVE_WP="$(mktemp)"
    cp -f "$THEME_DEST/sddm-wallpaper.png" "$PRESERVE_WP"
    log_status "Preserving current SDDM wallpaper across theme reinstall"
fi

log_status "Installing theme: $THEME_SRC → $THEME_DEST"
sudo rm -rf "$THEME_DEST"
sudo cp -a "$THEME_SRC" "$THEME_DEST"

if [[ -n "$PRESERVE_WP" && -f "$PRESERVE_WP" ]]; then
    sudo cp -f "$PRESERVE_WP" "$THEME_DEST/sddm-wallpaper.png"
    rm -f "$PRESERVE_WP"
fi

apply_qt6_compat "$THEME_DEST"

# User-owned theme dir so waypaper can overwrite sddm-wallpaper.png without sudo.
log_status "Setting theme ownership to $DESKTOP_USER (for live wallpaper sync)"
sudo chown -R "$DESKTOP_USER:$DESKTOP_USER" "$THEME_DEST"
sudo chmod -R u+rwX,go+rX "$THEME_DEST"

# ------------------------------------------------------------
# Install SDDM config — replace all drop-ins with hyprgruv defaults
# ------------------------------------------------------------
BACKUP_DIR="$HOME/.local/backup/sddm_conf_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_status "Backing up existing SDDM drop-ins → $BACKUP_DIR"
shopt -s nullglob
for existing in "$CONF_DIR"/*.conf; do
    sudo cp -a "$existing" "$BACKUP_DIR/"
    sudo rm -f "$existing"
    log_status "Removed: $existing"
done
shopt -u nullglob

if [[ -f /etc/sddm.conf && ! -s /etc/sddm.conf ]]; then
    sudo rm -f /etc/sddm.conf
fi

# Ship a single authoritative drop-in (loads after any stray files if they reappear).
log_status "Installing SDDM config → $CONF_DEST"
sudo install -m 0644 "$CONF_SRC/default.conf" "$CONF_DEST"

# ------------------------------------------------------------
# Enable SDDM + seed wallpaper from waypaper
# ------------------------------------------------------------
log_status "Ensuring sddm.service is enabled and graphical.target is default"
sudo systemctl reenable sddm.service >/dev/null 2>&1 || true
sudo systemctl set-default graphical.target >/dev/null 2>&1 || true

if [[ -x "$UPDATE_SDDM" ]]; then
    log_status "Syncing SDDM wallpaper from waypaper…"
    if runuser -u "$DESKTOP_USER" -- "$UPDATE_SDDM"; then
        log_success "SDDM wallpaper synced"
    else
        log_warning "SDDM wallpaper sync failed — run manually: $UPDATE_SDDM"
    fi
else
    log_warning "update-sddm-wallpaper.sh not found at $UPDATE_SDDM"
    log_warning "Run 02-stow.sh first, then: bash $UPDATE_SDDM"
fi

log_success "Sugar Candy theme and SDDM config installed"
echo
echo "SDDM theme installation complete."
echo "  Theme:     $THEME_DEST"
echo "  Config:    $CONF_DEST"
echo "  Wallpaper: $THEME_DEST/sddm-wallpaper.png  (updated by waypaper)"
echo
echo "Test greeter:  sudo sddm --test-mode"
echo "Live sync:     $UPDATE_SDDM"

sleep 0.5
exit 0