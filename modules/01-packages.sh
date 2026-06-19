#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
# Uses a curated "necessary only" list (lean Hyprland + terminal workflow + Thunar).

sleep 2
clear

set -euo pipefail
IFS=$'\n\t'
# __________               __
# \______   _____    ____ |  | ______    ____   ____   ______
#  |     ___\__  \ _/ ___\|  |/ \__  \  / ___\_/ __ \ /  ___/
#  |    |    / __ \\  \___|    < / __ \/ /_/  \  ___/ \___ \
#  |____|   (____  /\___  |__|_ (____  \___  / \___  /____  >
#                \/     \/     \/    \/_____/      \/     \/

echo ""

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "${REPO_DOTFILES_SCRIPTS}/header.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "${REPO_DOTFILES_SCRIPTS}/colors.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

say() { echo -e "$*"; }

# Install one AUR package without tripping set -e (command substitution + failed yay exits otherwise)
install_aur_pkg() {
    local pkg="$1"
    local output
    if pacman -Qq "$pkg" &>/dev/null; then
        say "  ✓ $pkg (already installed)"
        return 0
    fi
    if output=$(yay -S --needed --noconfirm "$pkg" 2>&1); then
        say "  ✓ $pkg"
        return 0
    fi
    log_error "AUR package failed: $pkg"
    echo "$output" | tail -12 | sed 's/^/    | /'
    if hyprgruv_strict_enabled; then
        hyprgruv_strict_abort "AUR package failed: $pkg"
    fi
    log_warning "AUR package failed (continuing — HYPRGRUV_STRICT=0): $pkg"
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
# Canonical lists live in lib/packages/manifest.sh (PACMAN_PKGS, AUR_PKGS, NEW_PKGS).
# Post-install / cross-device sync: bash ~/.hyprgruv/lib/scripts/sync-packages.sh
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/packages/manifest.sh"
OFFICIAL_PKGS=("${PACMAN_PKGS[@]}")
AUR_MANIFEST_PKGS=("${AUR_PKGS[@]}")
# Bootstrap stack (yay, hyprland, hyprpm, gum, waypaper) is installed in 00-preflight.sh.
# Keep those names in lib/packages/*.list for sync-packages.sh — skip re-install here.
hyprgruv_filter_bootstrap_from_manifest OFFICIAL_PKGS
hyprgruv_filter_bootstrap_from_manifest AUR_MANIFEST_PKGS

# -------------------- run --------------------
say "   📦️  Installing essential packages…"
hyprgruv_strict_banner
hyprgruv_forbid_skip_var SKIP_CHAOTIC
sleep 0.15

# Make sure we have working official repos + a usable mirrorlist *before* anything else.
# This is the most common source of "target not found" in VM install tests.
repair_official_repos

# Bootstrap stack (yay, hyprland, hyprpm, gum, waypaper) was installed in 00-preflight.sh.
hyprgruv_require_cmd yay
hyprgruv_require_pkg hyprland
hyprgruv_require_cmd hyprpm
hyprgruv_require_cmd gum
hyprgruv_waypaper_installed || hyprgruv_strict_abort "waypaper not available — re-run 00-preflight.sh"
hyprgruv_require_pkg waypaper-engine
log_success "Bootstrap stack verified (from preflight)"

# Fix any stale/broken chaotic-aur entry from previous failed runs
# (section present but no mirrorlist file -> pacman parse error on refresh)
if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null && [[ ! -f /etc/pacman.d/chaotic-mirrorlist ]]; then
    log_status "Removing stale [chaotic-aur] entry from pacman.conf (mirrorlist was missing)..."
    sudo sed -i '/^\[chaotic-aur\]/,/^$/d' /etc/pacman.conf || true
fi

# Ensure we are on a pure Arch base (remove EndeavourOS etc. if the user is migrating).
purge_endeavouros_remnants || hyprgruv_strict_abort "Failed to purge EndeavourOS remnants"

if [[ "${SKIP_CHAOTIC:-0}" == "1" ]]; then
    log_warning "SKIP_CHAOTIC=1 — skipping Chaotic-AUR keyring bootstrap and repo enable"
    if hyprgruv_strict_enabled; then
        hyprgruv_strict_abort "SKIP_CHAOTIC=1 is forbidden while HYPRGRUV_STRICT=1"
    fi
else
    log_status "Ensuring pacman keyring is usable"
    ensure_pacman_keyring

    # Install Chaotic-AUR from the beginning so the repo is fully ready before
    # the refresh and before the Hyprland/core package installs.
    # Robust to VM/network flakiness: only enable [chaotic-aur] if the bootstrap pkgs actually install.
    log_status "Installing Chaotic-AUR from the beginning..."
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com \
        || hyprgruv_strict_abort "Failed to receive Chaotic-AUR key"
    sudo pacman-key --lsign-key 3056513887B78AEB \
        || hyprgruv_strict_abort "Failed to locally sign Chaotic-AUR key"

    CHAOTIC_BOOTSTRAP_OK=0
    if sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'; then
        CHAOTIC_BOOTSTRAP_OK=1
        log_success "Chaotic-AUR keyring + mirrorlist installed successfully"
    else
        hyprgruv_strict_abort "Chaotic-AUR bootstrap download/install failed"
        log_warning "Chaotic-AUR bootstrap download/install failed — skipping repo"
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
sudo pacman -Syy --noconfirm || hyprgruv_strict_abort "pacman -Syy failed"

# Make sure we have a fresh arch keyring (helps with signature issues in fresh/VM installs)
sudo pacman -S --needed --noconfirm archlinux-keyring || hyprgruv_strict_abort "archlinux-keyring install failed"

if ! pacman -Si git >/dev/null 2>&1; then
    hyprgruv_strict_abort "Official repos cannot resolve basic packages (e.g. git) — check VM network/mirrors"
fi

log_status "Installing core dependencies…"

# PipeWire JACK handling: pipewire-jack provides the 'jack' virtual package.
# jack2 is the legacy implementation and they conflict on the jack API.
# We must resolve this *before* the big list, otherwise --noconfirm + conflict
# removal causes "unresolvable package conflicts" (as seen in VM testing).
if pacman -Qq jack2 &>/dev/null; then
    log_status "Removing conflicting jack2 package (replaced by pipewire-jack)..."
    sudo pacman -Rdd --noconfirm jack2 || hyprgruv_strict_abort "Failed to remove conflicting jack2"
fi

# Install PipeWire first (jack2 conflict) — full manifest follows in one pass.
sudo pacman -S --needed --noconfirm \
    pipewire pipewire-pulse pipewire-jack wireplumber \
    || hyprgruv_strict_abort "PipeWire stack install failed"

log_status "Installing official repo packages from manifest…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}" \
    || hyprgruv_strict_abort "Official manifest package install failed"

# Rust AUR builds need an active default toolchain *before* yay.
if command -v rustup >/dev/null 2>&1; then
    log_status "Setting rustup default toolchain to stable (for Rust AUR builds)…"
    if rustup default stable; then
        log_success "rustup default stable"
    else
        hyprgruv_strict_abort "rustup default stable failed"
    fi
else
    log_warning "rustup not in PATH — skipping 'rustup default stable'"
fi

log_status "Installing AUR packages…"
# Install one-by-one so a single problematic/flaky AUR package does not abort the installer.
AUR_FAILED=()
for pkg in "${AUR_MANIFEST_PKGS[@]}"; do
    install_aur_pkg "$pkg" || AUR_FAILED+=("$pkg")
done
if ((${#AUR_FAILED[@]})); then
    hyprgruv_strict_abort "AUR install failures (${#AUR_FAILED[@]}): ${AUR_FAILED[*]}"
    log_warning "Some AUR packages failed (${#AUR_FAILED[@]}): ${AUR_FAILED[*]}"
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
        sudo pacman -S --needed --noconfirm "${GUEST_PKGS[@]}" \
            || hyprgruv_strict_abort "VM guest package install failed: ${GUEST_PKGS[*]}"
    fi

    # Enable the corresponding services (safe if the unit doesn't exist)
    for svc in vboxservice.service qemu-guest-agent.service spice-vdagent.service vmtoolsd.service; do
        if systemctl list-unit-files | grep -q "^${svc}"; then
            sudo systemctl enable --now "$svc" 2>/dev/null || true
        fi
    done
    log_success "VM guest integration packages + services processed"
fi

ESSENTIAL_CHECK=(aylurs-gtk-shell-git brave-bin hyprshot qt5-declarative wlogout xsettingsd displaylink timeshift-autosnap vscodium-bin wl-clip-persist wdisplays wl-clipboard-history-git wlogout cbonsai-git dipc)
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
            hyprgruv_strict_abort "Essential package failed: $pkg"
        fi
    done
else
    say "All essential packages are already installed."
fi
sleep 0.2

hyprgruv_require_cmd yay
hyprgruv_require_pkg hyprland

# Opening wallpaper + first matugen palette.
# On a fresh install, hypr configs are not stowed yet — install.sh runs
# default_wp.sh after stow, immediately before reboot.
if [[ "${SKIP_WALLPAPER:-0}" != "1" ]]; then
    if [[ -x "$HOME/.config/hyprgruv/scripts/set_wallpaper.sh" ]]; then
        log_status "Applying opening wallpaper and default matugen theme…"
        bash "$HYPR_DIR/lib/scripts/default_wp.sh" || hyprgruv_strict_abort "default_wp.sh failed during packages step"
    else
        log_status "Opening wallpaper deferred until after stow (install.sh, before reboot)"
    fi
else
    log_status "SKIP_WALLPAPER=1 — skipping opening wallpaper step"
fi

mark_completed "Install packages"
exit 0
