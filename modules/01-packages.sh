#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

say() {
  if command -v lsd-print >/dev/null 2>&1; then echo -e "$*" | lsd-print; else echo -e "$*"; fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then return 0; fi
  log_status "Installing yay (AUR helper)…"
  sudo pacman -Syu --needed --noconfirm git base-devel
  tmpdir="$(mktemp -d)"; pushd "$tmpdir" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  pushd yay >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null; popd >/dev/null
  rm -rf "$tmpdir"
  log_success "yay installed."
}

# --- NEW: make sure chaotic-aur is usable if referenced in pacman.conf ---
ensure_chaotic_ready() {
  local conf="/etc/pacman.conf"
  local ml="/etc/pacman.d/chaotic-mirrorlist"
  local need_chaotic=0

  # only act if pacman.conf references chaotic-aur
  if grep -q '^\[chaotic-aur\]' "$conf" 2>/dev/null; then
    need_chaotic=1
  fi

  # if not referenced, nothing to do
  (( need_chaotic == 0 )) && return 0

  # if mirrorlist already exists, just sanitize and continue
  if [[ -f "$ml" ]]; then
    # de-prefer flaky mirrors (like warp.dev), but don't fail if absent
    sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true
    return 0
  fi

  log_status "Chaotic repo referenced, preparing keyring + mirrorlist"
  # import/sign key
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
  sudo pacman-key --lsign-key 3056513887B78AEB || true

  # install keyring + mirrorlist
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  # sanitize mirrorlist
  if [[ -f "$ml" ]]; then
    sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true
  fi

  # clear any stale DB and force refresh
  sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true
}

OFFICIAL_PKGS=(
  archlinux-xdg-menu
  bash-language-server
  bat
  bluez
  bluez-utils
  btop
  cmake
  cpio
  duf
  fastfetch
  fzf
  ghostty
  glow
  gsettings-qt
  gtk-engine-murrine
  hexyl
  hypridle
  hyprpaper
  kate
  kdecoration
  konsole
  kvantum
  less
  mediainfo
  meson
  ncdu
  neovim
  network-manager-applet
  pacman-mirrorlist
  pavucontrol
  pkgconf
  python-ansicolors
  qt5-declarative
  qt5-graphicaleffects
  qt5-x11extras
  rofi-calc
  rofi-wayland
  starship
  stow
  sudo
  tig
  tmux
  tree
  udiskie
  waybar
  wireplumber
  wl-clip-persist
  wl-clipboard
  xclip
  xdg-desktop-portal-kde
  xsettingsd
  yazi
  zoxide
  zsh
)

AUR_PKGS=(
  aylurs-gtk-shell-git
  bpytop
  clipse
  diskonaut
  eza
  grimblast-git
  hyprgraphics
  hyprland-qt-support
  hyprpicker
  hyprshade
  iwgtk
  lscolors-git
  nwg-dock-hyprland
  nwg-drawer
  nwg-look
  pacseek
  progress-git
  python-pywal16
  python-pywalfox
  qt6ct-kde
  smile
  waypaper
  wl-clipboard-history-git
)

say "   📦️  Installing essential packages…"
sleep 0.2

# PREP CHAOTIC IF NEEDED **BEFORE** FIRST -Syu
ensure_chaotic_ready

log_status "Refreshing system packages (pacman -Syu)…"
sudo pacman -Syyu --noconfirm

# Ensure yay is available for AUR
ensure_yay

# Install official packages with pacman
log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

# Install AUR packages with yay
log_status "Installing AUR packages…"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# Verify essential subset
ESSENTIAL_CHECK=(nwg-dock-hyprland nwg-drawer nwg-look python-pywal16 python-pywalfox qt5-declarative wlogout xsettingsd yazi)
MISSING=()
for pkg in "${ESSENTIAL_CHECK[@]}"; do
  if ! pacman -Qq "$pkg" &>/dev/null; then MISSING+=("$pkg"); fi
done
if (( ${#MISSING[@]} )); then
  log_status "Installing missing essentials: ${MISSING[*]}"
  yay -S --needed --noconfirm "${MISSING[@]}"
else
  say "All essential packages are already installed."
fi

sleep 0.3
mark_completed "Install packages"

