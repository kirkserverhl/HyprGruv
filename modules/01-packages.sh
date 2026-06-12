#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
#
# Uses a curated "necessary only" list (lean Hyprland + terminal workflow + Thunar).
# Pure Arch (third-party distro remnants such as EndeavourOS are stripped on sight).
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
    # If listing keys fails (or perms wrong), reinit the keyring from scratch.
    # This directly addresses the "you do not have sufficient permissions to read the pacman keyring" error.
    if ! sudo pacman-key --list-keys >/dev/null 2>&1; then
        log_status "Reinitializing pacman keyring (fixing permissions/read errors)"
        sudo rm -rf /etc/pacman.d/gnupg
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
        # Ensure correct ownership/permissions (common source of read failures)
        sudo chown -R root:root /etc/pacman.d/gnupg 2>/dev/null || true
        sudo chmod 700 /etc/pacman.d/gnupg 2>/dev/null || true
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
#   - No full Plasma bloat; EndeavourOS (or other derivative) packages/repos are purged
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
    # ffmpegthumbnailer

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

# Fix any stale/broken chaotic-aur entry from previous failed runs
# (section present but no mirrorlist file -> pacman parse error on refresh)
if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    log_status "Removing stale [chaotic-aur] entry from pacman.conf (mirrorlist was missing)..."
    sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
fi

# Ensure we are on a pure Arch base (remove EndeavourOS etc. if the user is migrating).
purge_endeavouros_remnants || true

log_status "Ensuring pacman keyring is usable"
ensure_pacman_keyring

# Install Chaotic-AUR from the beginning so the repo is fully ready before
# the refresh and before the Hyprland/core package installs.
# Robust to VM/network flakiness: only enable [chaotic-aur] if the bootstrap pkgs actually install.
log_status "Installing Chaotic-AUR from the beginning..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
sudo pacman-key --lsign-key 3056513887B78AEB || true

CHAOTIC_BOOTSTRAP_OK=0
if sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' ; then
    CHAOTIC_BOOTSTRAP_OK=1
    log_success "Chaotic-AUR keyring + mirrorlist installed successfully"
else
    log_warning "Chaotic-AUR bootstrap download/install failed (common on VMs with NAT/latency). Will skip repo for now."
fi

# Add the repo section ONLY if we successfully got the mirrorlist file
if [[ $CHAOTIC_BOOTSTRAP_OK -eq 1 ]] && [[ -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
        printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
    fi

    # Sanitize the mirrorlist (only known-bad; extend patterns as needed)
    sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' /etc/pacman.d/chaotic-mirrorlist || true

    sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true
else
    # Ensure we never leave a broken [chaotic-aur] Include pointing at nothing
    if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
        log_status "Removing [chaotic-aur] (bootstrap did not produce mirrorlist file)"
        sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
    fi
fi

# Ensure the default mirrorlist is populated if missing or empty.
# We seed a basic reliable mirror to bootstrap. Once reflector is installed
# (in the core list), you can run a better generation later if desired.
if [[ ! -s /etc/pacman.d/mirrorlist ]]; then
    log_status "Seeding initial mirrorlist (bootstrap)..."
    echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

# Minimal pacman.conf change: enable parallel downloads.
log_status "Setting ParallelDownloads in pacman.conf for faster downloads"
if ! grep -q '^ParallelDownloads' /etc/pacman.conf 2>/dev/null; then
    sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi

log_status "Refreshing system packages (pacman -Syyu)…"
# Guard: if somehow a broken chaotic block is still present without mirrorlist, strip it first.
if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    log_warning "Stripping broken [chaotic-aur] before refresh (missing mirrorlist)"
    sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
fi
sudo pacman -Syyu --noconfirm || log_warning "pacman -Syyu reported issues (continuing; some updates may be pending)"

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
