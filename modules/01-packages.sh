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

say() { if command -v lsd-print >/dev/null 2>&1; then echo -e "$*" | lsd-print; else echo -e "$*"; fi; }

# -------------------- guards & repairs --------------------
sanitize_pacman_conf() {
  local conf="/etc/pacman.conf"
  [[ -f "$conf" ]] || return 0

  # Normalize CRLF → LF
  sudo sed -i 's/\r$//' "$conf"

  # Comment any stray `Server =` lines that appear while in [options]
  sudo awk '
    BEGIN{inopt=0}
    /^\[options\]/{inopt=1; print; next}
    /^\[/{inopt=0; print; next}
    { if(inopt && $0 ~ /^[[:space:]]*Server[[:space:]]*=/){print "#" $0}else{print}}
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
  sudo mv "$conf.tmp.$$" "$conf"

  # Ensure core/extra exist (defensive on fresh images)
  grep -q '^\[core\]'  "$conf" || echo -e "\n[core]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null
  grep -q '^\[extra\]' "$conf" || echo -e "\n[extra]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null
}

ensure_pacman_keyring() {
  # If listing keys fails (or perms wrong), reinit the keyring from scratch
  if ! sudo pacman-key --list-keys >/dev/null 2>&1; then
    log_status "Reinitializing pacman keyring"
    sudo rm -rf /etc/pacman.d/gnupg
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
  fi
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

ensure_chaotic_ready() {
  local conf="/etc/pacman.conf"
  local ml="/etc/pacman.d/chaotic-mirrorlist"

  # only act if pacman.conf references chaotic-aur
  grep -q '^\[chaotic-aur\]' "$conf" 2>/dev/null || return 0

  if [[ -f "$ml" ]]; then
    # de-prefer known flaky mirrors
    sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true
    return 0
  fi

  log_status "Chaotic listed in pacman.conf; preparing keyring + mirrorlist"
  # keys
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
  sudo pacman-key --lsign-key 3056513887B78AEB || true

  # packages (keyring + mirrorlist)
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

  # sanitize mirrorlist if it now exists
  [[ -f "$ml" ]] && sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true

  # clear stale DB
  sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true
}

# -------------------- package sets --------------------
OFFICIAL_PKGS=(
  archlinux-xdg-menu bash-language-server bat bluez bluez-utils btop cmake cpio duf fastfetch
  fzf ghostty glow gsettings-qt gtk-engine-murrine hexyl hypridle hyprpaper
  kate kdecoration konsole kvantum less mediainfo meson ncdu neovim network-manager-applet
  pacman-mirrorlist pavucontrol pkgconf python-ansicolors
  qt5-declarative qt5-graphicaleffects qt5-x11extras
  rofi-calc rofi-wayland starship stow sudo tig tmux tree udiskie waybar
  wireplumber wl-clip-persist wl-clipboard xclip xdg-desktop-portal-kde xsettingsd yazi zoxide zsh
)

AUR_PKGS=(
  aylurs-gtk-shell-git bpytop clipse diskonaut eza grimblast-git hyprgraphics hyprland-qt-support
  hyprpicker hyprshade iwgtk lscolors-git nwg-dock-hyprland nwg-drawer nwg-look pacseek
  progress-git python-pywal16 python-pywalfox qt6ct-kde smile waypaper wl-clipboard-history-git
)

# -------------------- run --------------------
say "   📦️  Installing essential packages…"
sleep 0.15

log_status "Sanitizing pacman.conf"
sanitize_pacman_conf

log_status "Ensuring pacman keyring is usable"
ensure_pacman_keyring

log_status "Preparing Chaotic-aur (if referenced)"
ensure_chaotic_ready

log_status "Refreshing system packages (pacman -Syyu)…"
sudo pacman -Syyu --noconfirm

ensure_yay

log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

log_status "Installing AUR packages…"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

ESSENTIAL_CHECK=(nwg-dock-hyprland nwg-drawer nwg-look python-pywal16 python-pywalfox qt5-declarative wlogout xsettingsd yazi)
MISSING=(); for pkg in "${ESSENTIAL_CHECK[@]}"; do pacman -Qq "$pkg" &>/dev/null || MISSING+=("$pkg"); done
if (( ${#MISSING[@]} )); then
  log_status "Installing missing essentials: ${MISSING[*]}"
  yay -S --needed --noconfirm "${MISSING[@]}"
else
  say "All essential packages are already installed."
fi

sleep 0.2
mark_completed "Install packages"
