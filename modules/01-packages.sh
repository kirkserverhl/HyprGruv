#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

say() {
  if command -v lsd-print >/dev/null 2>&1; then
    echo -e "$*" | lsd-print
  else
    echo -e "$*"
  fi
}

ensure_yay() {
  if command -v yay >/dev/null 2>&1; then
    return 0
  fi
  log_status "Installing yay (AUR helper)…"
  sudo pacman -Syu --needed --noconfirm git base-devel
  tmpdir="$(mktemp -d)"
  pushd "$tmpdir" >/dev/null
  git clone https://aur.archlinux.org/yay.git
  pushd yay >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  popd >/dev/null
  rm -rf "$tmpdir"
  log_success "yay installed."
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
  #figlet
  fzf
  ghostty
  glow
  gsettings-qt
  gtk-engine-murrine
  hexyl
  hypridle
  hyprpaper
  # iwgtk        <-- moved to AUR
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
  # pacseek     <-- moved to AUR
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
  # waypaper    <-- moved to AUR
  wireplumber
  wl-clip-persist
  wl-clipboard
  # wlogout     <-- if you want it, uncomment and keep here (repo)
  xclip
  xdg-desktop-portal-kde
  # xorg-wayland <-- if you want it, uncomment and keep here (repo)
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
sleep 0.3

# Refresh system first
log_status "Refreshing system packages (pacman -Syu)…"
sudo pacman -Syu --noconfirm

# Ensure yay is available for AUR
ensure_yay

# Install official packages with pacman
log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

# Install AUR packages with yay
log_status "Installing AUR packages…"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

# Verify essential subset
ESSENTIAL_CHECK=(
  nwg-dock-hyprland
  nwg-drawer
  nwg-look
  python-pywal16
  python-pywalfox
  qt5-declarative
  wlogout
  xsettingsd
  yazi
)

MISSING=()
for pkg in "${ESSENTIAL_CHECK[@]}"; do
  if ! pacman -Qq "$pkg" &>/dev/null; then
    MISSING+=("$pkg")
  fi
done

if (( ${#MISSING[@]} )); then
  log_status "Installing missing essentials: ${MISSING[*]}"
  yay -S --needed --noconfirm "${MISSING[@]}"
else
  say "All essential packages are already installed."
fi

sleep 0.5
mark_completed "Install packages"
clear
