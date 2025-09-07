#!/usr/bin/env bash
# 00-preflight.sh — ensure Hyprland base stack on Arch/EndeavourOS, with repo assets
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from modules/ and load helpers
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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

display_header "Preflight: Hyprland Base Stack"

# ------------------------------------------------------------
# Arch sanity
# ------------------------------------------------------------
if ! command -v pacman >/dev/null 2>&1; then
  log_error "pacman not found. This preflight supports Arch/EndeavourOS only."
  exit 1
fi

log_status "Running preflight checks for Hyprland base…"

# ------------------------------------------------------------
# Helpers
# ------------------------------------------------------------
pkg_installed() { pacman -Qi "$1" &>/dev/null; }
repo_has() { pacman -Si "$1" &>/dev/null; }  # visible in enabled repos?
ensure_pkg() {
  local pkgs=()
  for p in "$@"; do
    pkg_installed "$p" || pkgs+=("$p")
  done
  ((${#pkgs[@]})) && sudo pacman -S --noconfirm --needed "${pkgs[@]}" || true
}
# Enable [multilib] if disabled (x86_64 only)
ensure_multilib_enabled() {
  # If multilib already queryable, done
  if pacman -Sl multilib &>/dev/null; then
    return 0
  fi
  # Only relevant on x86_64
  if [[ "$(uname -m)" != "x86_64" ]]; then
    return 0
  fi
  local conf="/etc/pacman.conf"
  local ts; ts="$(date +%Y%m%d_%H%M%S)"
  log_status "Enabling [multilib] in $conf"
  sudo cp -a "$conf" "$conf.bak.$ts"
  # Uncomment [multilib] block and its Include line
  sudo sed -i -E \
    -e 's/^[#[:space:]]*\[multilib\]/[multilib]/' \
    -e 's|^[#[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman\.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|' \
    "$conf"
  # Refresh databases after enabling
  sudo pacman -Syu --noconfirm
}

# ------------------------------------------------------------
# Detect GPU vendor
# ------------------------------------------------------------
GPU_VENDOR="generic"
if lspci | grep -iE ' vga|3d|display' | grep -qi nvidia; then
  GPU_VENDOR="nvidia"
elif lspci | grep -iE ' vga|3d|display' | grep -qi amd; then
  GPU_VENDOR="amd"
elif lspci | grep -iE ' vga|3d|display' | grep -qi intel; then
  GPU_VENDOR="intel"
fi
log_status "Detected GPU vendor: $GPU_VENDOR"

# Try to enable multilib before choosing lib32 packages
ensure_multilib_enabled || true

case "$GPU_VENDOR" in
  amd)    GFX_PKGS=(mesa vulkan-radeon libva-mesa-driver);     LIB32_GFX=(lib32-mesa lib32-vulkan-radeon) ;;
  intel)  GFX_PKGS=(mesa vulkan-intel  libva-intel-driver);    LIB32_GFX=(lib32-mesa lib32-vulkan-intel)  ;;
  nvidia) GFX_PKGS=(nvidia nvidia-utils);                      LIB32_GFX=(lib32-nvidia-utils)             ;;
  *)      GFX_PKGS=(mesa);                                     LIB32_GFX=(lib32-mesa)                     ;;
esac

# Filter lib32 packages if multilib still isn't available
AVAILABLE_LIB32=()
for p in "${LIB32_GFX[@]}"; do
  if repo_has "$p"; then AVAILABLE_LIB32+=("$p"); fi
done

# ------------------------------------------------------------
# Core Hyprland/Wayland stack
# ------------------------------------------------------------
BASE_PKGS=(
  hyprland
  xdg-desktop-portal xdg-desktop-portal-hyprland
  waybar
  rofi-wayland
  wl-clipboard grim slurp
  brightnessctl
  polkit
  networkmanager
  pipewire pipewire-pulse wireplumber
  gvfs gvfs-mtp
  noto-fonts ttf-dejavu
)

OPT_TERMS=(ghostty kitty alacritty)
OPT_EXTRAS=(wlogout swaybg hyprpaper hyprlock)

# ------------------------------------------------------------
# Install packages
# ------------------------------------------------------------
log_status "Refreshing package databases"
sudo pacman -Syu --noconfirm

log_status "Installing core packages"
ensure_pkg "${BASE_PKGS[@]}"

log_status "Installing GPU packages"
ensure_pkg "${GFX_PKGS[@]}"
if ((${#AVAILABLE_LIB32[@]})); then
  log_status "Installing 32-bit GPU packages (multilib)"
  ensure_pkg "${AVAILABLE_LIB32[@]}"
else
  log_status "Skipping 32-bit GPU packages (multilib unavailable)"
fi

log_status "Installing optional terminals"
ensure_pkg "${OPT_TERMS[@]}"

log_status "Installing optional extras"
ensure_pkg "${OPT_EXTRAS[@]}"

# ------------------------------------------------------------
# Enable services
# ------------------------------------------------------------
log_status "Enabling services"
sudo systemctl enable --now NetworkManager.service
# PipeWire stack (socket-activated; enabling is fine)
sudo systemctl enable --now pipewire.service wireplumber.service pipewire-pulse.service 2>/dev/null || true

if pkg_installed sddm; then
  sudo systemctl enable --now sddm.service
fi

# ------------------------------------------------------------
# Session file (only if missing)
# ------------------------------------------------------------
if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  log_status "Creating Hyprland session file"
  sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
fi

# ------------------------------------------------------------
# Apply optional preflight assets from the repo
# ------------------------------------------------------------
PREFLIGHT_DIR="$ASSET_DIR/preflight"
if [[ -d "$PREFLIGHT_DIR" ]]; then
  log_status "Applying preflight assets from $PREFLIGHT_DIR"

  if [[ -d "$PREFLIGHT_DIR/etc" ]]; then
    log_status "Syncing etc/ payload"
    sudo rsync -a "$PREFLIGHT_DIR/etc/." /etc/
  fi

  if [[ -d "$PREFLIGHT_DIR/usr_share" ]]; then
    log_status "Syncing usr_share/ payload → /usr/share"
    sudo rsync -a "$PREFLIGHT_DIR/usr_share/." /usr/share/
  fi

  if [[ -d "$PREFLIGHT_DIR/systemd" ]]; then
    log_status "Installing systemd unit overrides"
    sudo rsync -a "$PREFLIGHT_DIR/systemd/." /etc/systemd/system/
    sudo systemctl daemon-reload
  fi

  if [[ -f "$PREFLIGHT_DIR/env" ]]; then
    log_status "Merging environment variables into /etc/environment"
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      key="${line%%=*}"
      if grep -qE "^${key}=" /etc/environment 2>/dev/null; then
        sudo sed -i 's|^'"$key"'=.*$|'"$line"'|' /etc/environment
      else
        echo "$line" | sudo tee -a /etc/environment >/dev/null
      fi
    done < "$PREFLIGHT_DIR/env"
  fi
else
  log_status "No preflight asset directory at $PREFLIGHT_DIR — skipping asset application."
fi

mark_completed "Preflight"
log_success "Preflight check completed."
