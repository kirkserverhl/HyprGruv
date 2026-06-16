#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
# Uses a curated "necessary only" list (lean Hyprland + terminal workflow + Thunar).

sleep 2
clear

set -euo pipefail
IFS=$'\n\t'
__________               __
\______   _____    ____ |  | ______    ____   ____   ______
 |     ___\__  \ _/ ___\|  |/ \__  \  / ___\_/ __ \ /  ___/
 |    |    / __ \\  \___|    < / __ \/ /_/  \  ___/ \___ \
 |____|   (____  /\___  |__|_ (____  \___  / \___  /____  >
               \/     \/     \/    \/_____/      \/     \/

echo ""

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

say() { echo -e "$*"; }

# Install one AUR package without tripping set -e (command substitution + failed yay exits otherwise)
install_aur_pkg() {
    local pkg="$1"
    local output
    if output=$(yay -S --needed --noconfirm "$pkg" 2>&1); then
        say "  ✓ $pkg"
        return 0
    fi
    log_warning "AUR package failed: $pkg"
    echo "$output" | tail -12 | sed 's/^/    | /'
    return 1
}

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

# Ensure the fundamental Arch repos ([core], [extra], [multilib]) are present
# and that /etc/pacman.d/mirrorlist contains at least one usable Server line.
# This is critical in VMs, after previous partial runs, or when chaotic bootstrap
# leaves the config in a weird state. We call it early and after chaotic logic.
repair_official_repos() {
    local conf="/etc/pacman.conf"
    local ml="/etc/pacman.d/mirrorlist"

    # Guarantee the three main sections exist with a standard Include.
    # (Some minimal/test images or prior sed surgery can drop them.)
    for section in core extra; do
        if ! grep -q "^\[$section\]" "$conf" 2>/dev/null; then
            log_status "Adding missing [$section] section to pacman.conf"
            printf '\n[%s]\nInclude = /etc/pacman.d/mirrorlist\n' "$section" | sudo tee -a "$conf" >/dev/null
        fi
    done

    # Multilib (x86_64 only) — reuse the spirit of preflight's ensure_multilib_enabled but lighter.
    if [[ "$(uname -m)" == "x86_64" ]] && ! grep -q '^\[multilib\]' "$conf" 2>/dev/null; then
        log_status "Adding missing [multilib] section"
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a "$conf" >/dev/null
    fi

    # Force a sane mirrorlist if it is missing, empty, or has no active Server lines.
    # Using a couple of reliable mirrors helps with flaky VM NAT/geo mirrors.
    if [[ ! -s "$ml" ]] || ! grep -qE '^\s*Server\s*=' "$ml" 2>/dev/null; then
        log_status "Seeding/repairing official mirrorlist (reliable defaults)..."
        {
            echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch'
            echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch'
            echo 'Server = https://ftp.halifax.rwth-aachen.de/archlinux/$repo/os/$arch'
        } | sudo tee "$ml" >/dev/null
    fi
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

OFFICIAL_PKGS=(
    # --- Bootstrap / essentials ---
    base-devel
    git
    reflector
    networkmanager
    nm-connection-editor
    gparted

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
    pipewire-jack # preferred JACK implementation (replaces/conflicts with jack2)

    # --- Theming foundation ---
    matugen
    uv
    qt6ct
    papirus-icon-theme
    adw-gtk-theme
    # ttf-material-symbols-variable

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
    toilet
    toilet-fonts
    sl
    zsh

    # Greeter / display manager (SDDM, no Plasma/KDE bits)
    sddm

    # --- Terminals ---
    kitty
    ghostty
    tmux

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

    # --- Additional tools (user requested) ---
    7zip
    bpytop
    clang
    cliphist
    cmatrix
    discount
    ffmpegthumbs
    htop
    media-player-info
    nm-connection-editor
    nvim
    pacutils
    ttf-nerd-fonts-symbols
    udiskie
    # blueman
    # bluez
    # bluez-utils
    # blueman
    # zram-generator, imagemagick

    # --- Audio / widgets / display utilities ---
    cava
    kew
    opencode
    quickshell
    wlr-randr
    aha
    mpv
)
AUR_PKGS=(
    python-pywalfox
    bibata-cursor-theme-bin

    # === Browsers / Terminals ===
    brave-bin
    google-chrome
    ghostty-git
    ghostty-shell-integration-git
    ghostty-terminfo-git

    # === tmux plugins / tooling ===
    tmux-continuum-git
    tmux-fingers
    tmux-language-server
    tmux-resurrect-git
    tmux-tad
    tmuxai
    tmuxinator

    hyprshot
    aylurs-gtk-shell-git # Aylur's Gtk Shell) — widgets, sidebars, bars, etc.

    # === Additional tools (user requested, AUR) ===
    atuin
    displaylink
    masterpdfeditor
    timeshift-autosnap
    udiskie-dmenu-git # companion for udiskie; not needed for now
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

# Make sure we have working official repos + a usable mirrorlist *before* anything else.
# This is the most common source of "target not found" in VM install tests.
repair_official_repos

# Fix any stale/broken chaotic-aur entry from previous failed runs
# (section present but no mirrorlist file -> pacman parse error on refresh)
if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    log_status "Removing stale [chaotic-aur] entry from pacman.conf (mirrorlist was missing)..."
    sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
fi

# Ensure we are on a pure Arch base (remove EndeavourOS etc. if the user is migrating).
purge_endeavouros_remnants || true

# Install yay (AUR helper) as early as possible in the packages phase.
# This ensures the "Installing yay" step is visible near the beginning (when needed)
# and that we can use yay for anything that requires it right away.
# (Previously this was buried after ~200 lines of chaotic setup + refreshes.)
log_status "Ensuring yay (AUR helper) is available early…"
ensure_yay

if [[ "${SKIP_CHAOTIC:-0}" == "1" ]]; then
    log_warning "SKIP_CHAOTIC=1 — skipping Chaotic-AUR keyring bootstrap and repo enable (you said you might not need it right now)"
else
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
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
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
        # On failure this run, *always* remove the [chaotic-aur] section.
        # Previously we only removed when the mirrorlist file itself was absent.
        # Leaving a stale Include here causes:
        #   - "chaotic-aur downloading..." even when not ready
        #   - provider prompts for packages that have variants in chaotic
        #   - potential parse/sync problems that make official core/extra appear "missing"
        if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
            log_status "Removing [chaotic-aur] section (bootstrap did not succeed this run)"
            sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
        fi
        # Clean the local db file too so we don't have a half-cached broken repo
        sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* 2>/dev/null || true
    fi
fi

# After chaotic (success or skip/fail), make absolutely sure official repos + mirrorlist are solid
# before we do the big refresh and the "core dependencies" install list.
repair_official_repos

# Minimal pacman.conf change: enable parallel downloads.
log_status "Setting ParallelDownloads in pacman.conf for faster downloads"
if ! grep -q '^ParallelDownloads' /etc/pacman.conf 2>/dev/null; then
    sudo sed -i '/^\[options\]/a ParallelDownloads = 5' /etc/pacman.conf
fi

# One last defensive repair + force a clean official-focused refresh.
# (VMs with latency/NAT can have partial syncs; we want core/extra visible.)
repair_official_repos
log_status "Refreshing system packages (pacman -Syy)…"
# Always strip chaotic here if it is present but not fully ready — we only want official + multilib
# for the core Hyprland/desktop packages that follow.
if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    log_status "Temporarily ensuring no broken [chaotic-aur] before main package phase"
    sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
    sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* 2>/dev/null || true
fi
sudo pacman -Syy --noconfirm || log_warning "pacman -Syy reported issues (continuing)"

# Make sure we have a fresh arch keyring (helps with signature issues in fresh/VM installs)
sudo pacman -S --needed --noconfirm archlinux-keyring 2>/dev/null || true

# Final sanity: if basic packages still aren't visible, the test environment probably
# has no usable network/mirrors. We warn loudly instead of letting 50 "target not found" scroll by.
if ! pacman -Si git >/dev/null 2>&1; then
    log_error "Official repos still cannot resolve basic packages (e.g. git)."
    log_error "Check your VM network, /etc/pacman.d/mirrorlist, and pacman.conf."
    log_error "You can try: sudo pacman -Syyu  then re-run this installer with FORCE=1"
    # We continue (some environments recover on the next -S), but the upcoming list will likely fail.
fi

# yay was already ensured early (see top of this file). We keep the comment for history.
log_status "Installing Hyprland and core dependencies…"

# PipeWire JACK handling: pipewire-jack provides the 'jack' virtual package.
# jack2 is the legacy implementation and they conflict on the jack API.
# We must resolve this *before* the big list, otherwise --noconfirm + conflict
# removal causes "unresolvable package conflicts" (as seen in VM testing).
if pacman -Qq jack2 &>/dev/null; then
    log_status "Removing conflicting jack2 package (replaced by pipewire-jack)..."
    sudo pacman -Rdd --noconfirm jack2 2>/dev/null || true
fi

# Install the PipeWire audio stack (including jack replacement) in its own
# transaction first. This keeps dependency resolution clean.
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-pulse pipewire-jack wireplumber

sudo pacman -S --needed --noconfirm \
    hyprland xdg-desktop-portal xdg-desktop-portal-hyprland \
    hyprcursor hyprpicker hyprsunset \
    hyprlock waybar hyprshot hyprtoolkit \
    atuin fuzzel wl-clipboard grim slurp brightnessctl \
    polkit-gnome gnome-keyring ncdu \
    kitty thunar thunar-volman thunar-archive-plugin tumbler \
    mpv networkmanager nm-connection-editor pavucontrol sddm \
    obsidian yazi \
    piper stow \
    qt6-declarative qt5-declarative qt6ct rustup \
    powerdevil \
    sl zsh \
    starship \
    noto-fonts ttf-nerd-fonts-symbols ttf-dejavu \
    git base-devel reflector jq curl fastfetch btop duf dust ncdu man-db man-pages \
    media-player-info nm-connection-editor pacutils \
    tmux tmuxinator \
    doxygen \
    dust \
    e2fsprogs \
    ex-vi-compat

log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

# Rust AUR builds need an active default toolchain *before* yay.
if command -v rustup >/dev/null 2>&1; then
    log_status "Setting rustup default toolchain to stable (for Rust AUR builds)…"
    if rustup default stable; then
        log_success "rustup default stable"
    else
        log_warning "rustup default stable failed — run manually if Rust AUR builds fail"
    fi
else
    log_warning "rustup not in PATH — skipping 'rustup default stable'"
fi

log_status "Installing AUR packages…"
# Install one-by-one so a single problematic/flaky AUR package does not abort the installer.
AUR_FAILED=()
for pkg in "${AUR_PKGS[@]}"; do
    install_aur_pkg "$pkg" || AUR_FAILED+=("$pkg")
done
if ((${#AUR_FAILED[@]})); then
    log_warning "Some AUR packages failed (${#AUR_FAILED[@]}): ${AUR_FAILED[*]}"
    log_warning "Install continues — re-run later: yay -S --needed <package>"
else
    say "All AUR packages installed successfully."
fi

# ------------------------------------------------------------------
# VM guest tools (only when running inside a virtual machine).
# This helps video, dynamic resolution, clipboard, time sync, etc.
# Critical for getting the SDDM greeter (and graphical session) to
# appear reliably on boot in VirtualBox, VMware, QEMU/KVM, etc.
# ------------------------------------------------------------------
if [[ "${IS_VM:-false}" == "true" ]]; then
    log_status "VM detected ($HYPERVISOR) — installing hypervisor guest packages"
    GUEST_PKGS=()
    case "$HYPERVISOR" in
    virtualbox)
        GUEST_PKGS=(virtualbox-guest-utils)
        ;;
    vmware)
        GUEST_PKGS=(open-vm-tools)
        ;;
    qemu | kvm | generic-vm)
        GUEST_PKGS=(qemu-guest-agent spice-vdagent)
        ;;
    hyperv)
        GUEST_PKGS=(hyperv)
        ;;
    *)
        GUEST_PKGS=(qemu-guest-agent)
        ;;
    esac

    if ((${#GUEST_PKGS[@]})); then
        sudo pacman -S --needed --noconfirm "${GUEST_PKGS[@]}" || log_warning "Some guest packages may have failed to install"
    fi

    # Enable the corresponding services (safe if the unit doesn't exist)
    for svc in vboxservice.service qemu-guest-agent.service spice-vdagent.service vmtoolsd.service; do
        if systemctl list-unit-files | grep -q "^${svc}"; then
            sudo systemctl enable --now "$svc" 2>/dev/null || true
        fi
    done
    log_success "VM guest integration packages + services processed"
fi

ESSENTIAL_CHECK=(brave-bin hyprshot python-pywalfox qt5-declarative wlogout xsettingsd displaylink masterpdfeditor timeshift-autosnap vscodium-bin wl-clip-persist wdisplays wl-clipboard-history-git wlogout aylurs-gtk-shell-git)
# (otf-apple-sf-pro, pacseek-bin, udiskie-dmenu-git etc. removed for now to avoid flaky builds/conflicts during testing)
MISSING=()
for pkg in "${ESSENTIAL_CHECK[@]}"; do
    pacman -Qq "$pkg" &>/dev/null || MISSING+=("$pkg")
done
if ((${#MISSING[@]})); then
    log_status "Installing missing essentials one-by-one (resilient)..."
    for pkg in "${MISSING[@]}"; do
        if install_aur_pkg "$pkg"; then
            say "    (essential)"
        else
            log_warning "Essential package failed: $pkg (continuing; may need manual install later)"
        fi
    done
else
    say "All essential packages are already installed."
fi
sleep 0.2

if ((${#AUR_FAILED[@]})); then
    log_warning "Install packages finished with ${#AUR_FAILED[@]} AUR failure(s) — proceeding to stow."
fi

# Opening wallpaper + first matugen palette.
# On a fresh install, hypr configs are not stowed yet — install.sh runs
# default_wp.sh after stow, immediately before reboot.
if [[ "${SKIP_WALLPAPER:-0}" != "1" ]]; then
    if [[ -x "$HOME/.config/hypr/scripts/set_wallpaper.sh" ]]; then
        log_status "Applying opening wallpaper and default matugen theme…"
        bash "$HYPR_DIR/lib/scripts/default_wp.sh" || log_warning "default_wp.sh finished with warnings"
    else
        log_status "Opening wallpaper deferred until after stow (install.sh, before reboot)"
    fi
else
    log_status "SKIP_WALLPAPER=1 — skipping opening wallpaper step"
fi

mark_completed "Install packages"
exit 0
