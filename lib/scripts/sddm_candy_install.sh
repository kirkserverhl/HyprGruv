#!/usr/bin/env bash
# sddm_candy_install.sh — install Sugar Candy SDDM theme + config drop-ins
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
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

# --- Load your existing helpers for consistent look ---
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

display_header "SDDM Theme"

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

# ------------------------------------------------------------
# Require SDDM + shipped assets
# ------------------------------------------------------------
ensure_sddm

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

# Ensure target directories
log_status "Preparing target directories…"
sudo install -d -m 0755 "$THEMES_DIR"
sudo install -d -m 0755 "$CONF_DIR"

# Clean up known conflicting drop-ins from distro / Plasma installs
log_status "Removing conflicting SDDM drop-in configs (EndeavourOS remnants, KDE settings, etc.)"
for bad in \
    "$CONF_DIR/10-endeavouros.conf" \
    "$CONF_DIR/kde_settings.conf" \
    "$CONF_DIR/sddm.conf" \
    "$CONF_DIR/00-default.conf" \
    "$CONF_DIR/05-x11-greeter.conf" \
    "$CONF_DIR/10-theme.conf" \
    "$CONF_DIR/sddm-hyprland.conf" \
    "$CONF_DIR/sddm-user.conf"; do
    if [[ -f "$bad" ]]; then
        sudo rm -f "$bad"
        log_status "Removed: $bad"
    fi
done

if [[ -f /etc/sddm.conf && ! -s /etc/sddm.conf ]]; then
    sudo rm -f /etc/sddm.conf
fi

# Hard copy Sugar Candy theme → /usr/share/sddm/themes/sugar-candy
log_status "Hard copying theme: $THEME_SRC → $THEMES_DIR/$THEME_NAME"
sudo rm -rf "$THEMES_DIR/$THEME_NAME"
sudo cp -a "$THEME_SRC" "$THEMES_DIR/"

# Hard copy SDDM drop-ins → /etc/sddm.conf.d/
log_status "Hard copying config: $CONF_SRC → $CONF_DIR"
shopt -s nullglob
conf_files=("$CONF_SRC"/*)
shopt -u nullglob
if ((${#conf_files[@]} == 0)); then
    log_error "No files found in $CONF_SRC"
    exit 1
fi
for conf in "${conf_files[@]}"; do
    [[ -f "$conf" ]] || continue
    sudo install -m 0644 "$conf" "$CONF_DIR/$(basename "$conf")"
    log_status "Installed: $CONF_DIR/$(basename "$conf")"
done

log_success "Sugar Candy theme and SDDM config installed"

# Ensure SDDM is enabled as the display manager (safe to re-run)
log_status "Ensuring sddm.service is enabled and graphical.target is default"
sudo systemctl reenable sddm.service >/dev/null 2>&1 || true
sudo systemctl set-default graphical.target >/dev/null 2>&1 || true

echo "SDDM theme installation complete."
echo "You can test with:  sudo sddm --test-mode"
echo "To exit the test, press Ctrl+C."

sleep 0.5
exit 0