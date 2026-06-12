#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
#
# Uses a curated "necessary only" list (lean Hyprland + terminal workflow + Thunar).
# Pure Arch (no EndeavourOS/KDE/Plasma remnants).
# See the package sets section below for the full rationale and grouping.
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

say() { echo -e "$*"; }

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

# -------------------- package sets --------------------
#
# Curated "necessary" packages only.
#
# Rules followed here:
#   - Lean core: terminal workflow (zsh + lf + neovim + starship) + Hyprland (no KDE/Plasma)
#   - Thunar as primary file manager (no Dolphin/KDE file integration)
#   - No full Plasma bloat, no EndeavourOS-specific packages
#   - Browsers: brave (primary), google-chrome, firefox (fallback)
#   - Terminals: kitty (main), ghostty (secondary)
#   - Screenshots: hyprshot
#   - Authentication: gnome-keyring + polkit-gnome
#   - Greeter: sddm (no KDE)
#   - Other: fuzzel (launcher), libreoffice, timeshift (with separate partition)
#   - Still using pywalfox for theming
#   - Prefer pacman when possible (especially after Chaotic-AUR is enabled)
#   - Keep AUR list small — move packages to OFFICIAL_PKGS once they are available via Chaotic
#
# This list was refined from actual usage + the dots repo curation.
# Reference: ~/.dots/packages/install.sh (or the dots git repo)

OFFICIAL_PKGS=(
    # --- Bootstrap / essentials ---
    base-devel
    git
    reflector
    networkmanager

    # --- Shell & core terminal workflow ---
    zsh
    eza
    fzf
    zoxide
    bat
    trash-cli
    stow
    lf
    yazi
    neovim
    lazygit
    starship

    # lf / yazi file preview support
    chafa
    mupdf-tools
    tesseract
    tesseract-data-eng
    ffmpeg
    ffmpegthumbnailer

    # yazi (modern TUI file manager, alongside lf)

    # --- Hyprland (lean, no full desktop, no KDE/Plasma) ---
    hyprland
    hyprpicker
    grim
    slurp
    wl-clipboard
    brightnessctl
    xdg-desktop-portal-hyprland
    xdg-desktop-portal

    # Authentication (gnome instead of hyprpolkitagent / KDE polkit)
    polkit-gnome
    gnome-keyring

    # PipeWire audio
    pipewire
    wireplumber
    pipewire-pulse
    pipewire-alsa

    # --- Theming foundation ---
    uv
    qt6ct
    papirus-icon-theme
    adw-gtk-theme
    ttf-material-symbols-variable

    # --- Daily utilities + launchers ---
    jq
    curl
    fastfetch
    btop
    duf
    dust
    ncdu
    man-db
    man-pages
    pavucontrol
    gum
    fuzzel

    # --- Terminals ---
    kitty

    # --- File manager (Thunar, no Dolphin/KDE) ---
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    tumbler
    gvfs

    # --- Browser (brave primary, with fallbacks) ---
    firefox

    # --- Office ---
    libreoffice-fresh

    # --- Backup (timeshift with separate partition) ---
    timeshift

    # --- Hyprgruv / personal additions ---
    # Move packages here (from AUR_PKGS) once Chaotic-AUR is enabled for faster installs.

    # --- Additional tools (user requested) ---
    7zip
    # blueberry
    atuin
    bpytop
    cava-bg
    clang
    cliphist
    cmatrix
    discount
    # ffmpegthumbs
    htop
    # imagemagick
    media-player-info
    nm-connection-editor
    pacutils
    obs-studio
    ttf-nerd-fonts-symbols
    udiskie
    # zram-generator
)

AUR_PKGS=(
    # === Theming (critical for this dots/hyprgruv setup) ===
    matugen-git
    python-pywalfox # still using pywalfox
    bibata-cursor-theme-bin

    # === Terminals ===
    ghostty-bin

    # === Browsers ===
    brave-bin
    google-chrome

    # === Screenshots ===
    hyprshot

    # === Tools declared in dots manifests ===
    opencode-bin

    # === Additional tools (user requested, AUR) ===
    displaylink
    masterpdfeditor
    otf-apple-sf-pro
    timeshift-autosnap
    udiskie-dmenu-git
    vscodium-bin
    wl-clip-persist
    wl-clipboard-history-git
    wlogout

    # === Personal / usually still AUR or preferred -git versions ===
    # Move anything below to OFFICIAL_PKGS as soon as Chaotic provides it.
    # zsh-thefuck-git
    # etc.
)

# -------------------- run --------------------
say "   📦️  Installing essential packages…"
sleep 0.15

log_status "Ensuring pacman keyring is usable"
ensure_pacman_keyring

# Minimal pacman.conf change: enable parallel downloads.
# Nothing else special here — chaotic-aur setup is deferred until after first login
# (user will run the chaotic.sh script post-reboot when they want it).
log_status "Setting ParallelDownloads in pacman.conf for faster downloads"
if ! grep -q '^ParallelDownloads' /etc/pacman.conf 2>/dev/null; then
  sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi

log_status "Refreshing system packages (pacman -Syyu)…"
sudo pacman -Syyu --noconfirm

ensure_yay

log_status "Installing Hyprland and core dependencies right after yay…"
sudo pacman -S --needed --noconfirm \
    hyprland xdg-desktop-portal xdg-desktop-portal-hyprland \
    waybar fuzzel wl-clipboard grim slurp brightnessctl \
    polkit-gnome gnome-keyring \
    kitty thunar thunar-volman thunar-archive-plugin tumbler \
    pipewire pipewire-pulse wireplumber \
    networkmanager pavucontrol sddm \
    yazi \
    stow \
    noto-fonts ttf-nerd-fonts-symbols ttf-dejavu \
    git base-devel reflector jq curl fastfetch btop duf dust ncdu man-db man-pages \
    7zip atuin bpytop cava clang cliphist cmatrix discount htop \
    media-player-info nm-connection-editor pacutils obs-studio udiskie

log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

log_status "Installing AUR packages…"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

ESSENTIAL_CHECK=(brave-bin ghostty-bin hyprshot python-pywalfox qt5-declarative wlogout xsettingsd displaylink masterpdfeditor otf-apple-sf-pro timeshift-autosnap udiskie-dmenu-git vscodium-bin wl-clip-persist wl-clipboard-history-git wlogout)
MISSING=()
for pkg in "${ESSENTIAL_CHECK[@]}"; do pacman -Qq "$pkg" &>/dev/null || MISSING+=("$pkg"); done
if ((${#MISSING[@]})); then
    log_status "Installing missing essentials: ${MISSING[*]}"
    yay -S --needed --noconfirm "${MISSING[@]}"
else
    say "All essential packages are already installed."
fi

sleep 0.2
mark_completed "Install packages"
