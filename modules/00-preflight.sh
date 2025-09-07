#!/usr/bin/env bash
# 00-preflight.sh - Ensure EndeavourOS has the Hyprland base stack
set -euo pipefail

# logging helpers come from lib/common.sh
log_status "Running preflight checks for Hyprland base..."

# -------------------------------------------------------------
# Utility functions
# -------------------------------------------------------------
pkg_installed() { pacman -Qi "$1" &>/dev/null; }
ensure_pkg() {
  local pkgs=()
  for p in "$@"; do
    pkg_installed "$p" || pkgs+=("$p")
  done
  [[ ${#pkgs[@]} -gt 0 ]] && sudo pacman -S --noconfirm --needed "${pkgs[@]}"
}

# -------------------------------------------------------------
# Detect GPU and pick driver stack
# -------------------------------------------------------------
GPU_VENDOR="generic"
if lspci | grep -i ' vga\|3d\|display' | grep -qi nvidia; then
  GPU_VENDOR="nvidia"
elif lspci | grep -i ' vga\|3d\|display' | grep -qi amd; then
  GPU_VENDOR="amd"
elif lspci | grep -i ' vga\|3d\|display' | grep -qi intel; then
  GPU_VENDOR="intel"
fi

case "$GPU_VENDOR" in
  amd)    GFX_PKGS=(mesa vulkan-radeon libva-mesa-driver lib32-mesa lib32-vulkan-radeon) ;;
  intel)  GFX_PKGS=(mesa vulkan-intel libva-intel-driver lib32-mesa lib32-vulkan-intel) ;;
  nvidia) GFX_PKGS=(nvidia nvidia-utils lib32-nvidia-utils) ;;
  *)      GFX_PKGS=(mesa lib32-mesa) ;;
esac

# -------------------------------------------------------------
# Core Hyprland/Wayland stack
# -------------------------------------------------------------
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

log_status "Installing base packages if missing..."
ensure_pkg "${BASE_PKGS[@]}"
ensure_pkg "${GFX_PKGS[@]}"
ensure_pkg "${OPT_TERMS[@]}"
ensure_pkg "${OPT_EXTRAS[@]}"

# -------------------------------------------------------------
# Enable services EndeavourOS may not have enabled
# -------------------------------------------------------------
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now pipewire.service wireplumber.service pipewire-pulse.service 2>/dev/null || true

if pkg_installed sddm; then
  sudo systemctl enable --now sddm.service
fi

# -------------------------------------------------------------
# Session file sanity
# -------------------------------------------------------------
if [[ ! -f /usr/share/wayland-sessions/hyprland.desktop ]]; then
  log_status "Creating Hyprland session file for SDDM/GDM"
  sudo tee /usr/share/wayland-sessions/hyprland.desktop >/dev/null <<'EOF'
[Desktop Entry]
Name=Hyprland
Comment=Hyprland Wayland Compositor
Exec=Hyprland
Type=Application
DesktopNames=Hyprland
EOF
fi

log_success "Preflight check completed."
