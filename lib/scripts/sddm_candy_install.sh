#!/usr/bin/env bash
# sddm_candy_install.sh — install Sugar Candy SDDM theme
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Load helpers
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
  echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"; exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
ASSET_DIR="$HYPR_DIR/assets/sddm"                     # theme assets shipped in repo
THEMES_DIR="/usr/share/sddm/themes"                   # system themes dir
CONF_DIR="/etc/sddm.conf.d"                           # per-system SDDM config
THEME_NAME="sugar-candy"                              # directory name of the theme
THEME_SRC="$ASSET_DIR/$THEME_NAME"                    # source theme folder
CONF_FILE="$CONF_DIR/10-theme.conf"                   # we’ll set Current there

display_header "SDDM: Sugar Candy Theme"

# Sanity checks
if [[ ! -d "$ASSET_DIR" ]]; then
  log_error "Assets not found: $ASSET_DIR"
  exit 1
fi
if [[ ! -d "$THEME_SRC" ]]; then
  log_error "Theme directory not found: $THEME_SRC"
  exit 1
fi

# Ensure target directories
log_status "Preparing target directories…"
sudo install -d -m 0755 "$THEMES_DIR"
sudo install -d -m 0755 "$CONF_DIR"

# Clean up known conflicting / legacy drop-ins from base distro or Plasma installs.
# These can cause the greeter to pick the wrong theme (eos-breeze) or have stray Autologin sections.
log_status "Removing conflicting SDDM drop-in configs (EndeavourOS remnants, KDE settings, etc.)"
for bad in \
  "$CONF_DIR/10-endeavouros.conf" \
  "$CONF_DIR/kde_settings.conf" \
  "$CONF_DIR/sddm.conf" \
  "$CONF_DIR/00-default.conf"; do
  if [[ -f "$bad" ]]; then
    sudo rm -f "$bad"
    log_status "Removed: $bad"
  fi
done

# Also remove any main /etc/sddm.conf if it is empty or minimal (drop-ins are preferred)
if [[ -f /etc/sddm.conf && ! -s /etc/sddm.conf ]]; then
  sudo rm -f /etc/sddm.conf
fi

# Install/copy the theme directory
log_status "Installing theme to $THEMES_DIR/$THEME_NAME"
if [[ -d "$THEMES_DIR/$THEME_NAME" ]]; then
  # Replace contents safely
  sudo rm -rf "$THEMES_DIR/$THEME_NAME"
fi
sudo cp -a "$THEME_SRC" "$THEMES_DIR/"

# If you ship any SDDM snippets (backgrounds, etc.)
# e.g., ASSET_DIR may also include a background file (sddm.jpg/png)
for img in "$ASSET_DIR"/sddm.*; do
  if [[ -f "$img" ]]; then
    log_status "Copying background $(basename "$img") into theme dir"
    sudo cp -a "$img" "$THEMES_DIR/$THEME_NAME/"
  fi
done

# Write a clean theme drop-in (after cleanup)
log_status "Setting SDDM theme in $CONF_FILE"
sudo bash -c "cat > '$CONF_FILE' <<'EOF'
[Theme]
Current=$THEME_NAME
EOF"

# Ensure a General section that prefers the X11 greeter.
# This is much more reliable than the experimental Wayland greeter
# on virtual graphics adapters (VirtualBox, QEMU virtio-gpu, etc.).
# Safe on bare metal too.
log_status "Ensuring SDDM uses X11 greeter (best compatibility, including VMs)"
sudo bash -c "cat > '$CONF_DIR/05-x11-greeter.conf' <<'EOF'
[General]
DisplayServer=x11
EOF"

log_success "Sugar Candy theme installed and configured"

# Ensure SDDM is enabled as the display manager (safe to re-run)
log_status "Ensuring sddm.service is enabled and graphical.target is default"
sudo systemctl reenable sddm.service >/dev/null 2>&1 || true
sudo systemctl set-default graphical.target >/dev/null 2>&1 || true

# Optional: quick test hint
echo "SDDM theme installation complete."
echo "You can test with:  sudo sddm --test-mode"
echo "To exit the test, press Ctrl+C."

sleep 0.5
exit 0

