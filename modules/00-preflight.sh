#!/usr/bin/env bash
# 00-preflight.sh — ensure base system prep on pure Arch (Hyprland installed first)
sleep 2
clear

set -euo pipefail
IFS=$'\n\t'

# __________             __________.__  .__       .__     __
# \______   _______  ____\_   _____|  | |__| ____ |  |___/  |
#  |     ___\_  __ _/ __ \|    __) |  | |  |/ ___\|  |  \   __\
#  |    |    |  | \\  ___/|     \  |  |_|  / /_/  |   Y  |  |
#  |____|    |__|   \___  \___  /  |____|__\___  /|___|  |__|
#                       \/    \/          /_____/      \/

echo ""

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Load helpers
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
}
[[ -f "$HYPR_DIR/lib/state.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
}
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

# --- Load your existing helpers for consistent look ---
source "${REPO_DOTFILES_SCRIPTS}/header.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "${REPO_DOTFILES_SCRIPTS}/colors.sh" 2>/dev/null \
    || source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

# Arch sanity
if ! command -v pacman >/dev/null 2>&1; then
    log_error "pacman not found. This preflight supports pure Arch only."
    exit 1
fi

log_status "Running preflight checks for Hyprland base…"

# ------------------------ helpers ------------------------
pkg_installed() { pacman -Qi "$1" &>/dev/null; }
repo_has() { pacman -Si "$1" &>/dev/null; }

# Purge EndeavourOS (or other distro) remnants early — supports migrating away to pure Arch.
purge_endeavouros_remnants || true
ensure_pkg() {
    local pkgs=()
    for p in "$@"; do pkg_installed "$p" || pkgs+=("$p"); done
    ((${#pkgs[@]})) && sudo pacman -S --noconfirm --needed "${pkgs[@]}" || true
}

ensure_multilib_enabled() {
    # already visible?
    pacman -Sl multilib &>/dev/null && return 0
    [[ "$(uname -m)" == "x86_64" ]] || return 0

    local conf="/etc/pacman.conf"
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"
    sudo cp -a "$conf" "$conf.bak.$ts"

    # Only touch the [multilib] block; do NOT alter anything else.
    # If the block exists but is commented, uncomment it and its Include line.
    if grep -n '^\[multilib\]' "$conf" >/dev/null 2>&1; then
        :
    else
        # Append a correct block if missing
        printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a "$conf" >/dev/null
    fi

    # Uncomment the block header and include line if they were commented
    sudo sed -i -E \
        -e 's/^[#[:space:]]*\[multilib\]/[multilib]/' \
        -e '0,/\[multilib\]/{/\[multilib\]/{n; s|^[#[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman\.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|}}' \
        "$conf"

    # Hard refresh
    sudo pacman -Syyu --noconfirm
}

# ------------------- one-time seed (optional) -------------------
# If you ever want to seed /etc/pacman.conf from assets only when missing:
# if [[ ! -f /etc/pacman.conf && -f "$ASSET_DIR/pacman.conf" ]]; then
#   log_status "Seeding /etc/pacman.conf from assets"
#   sudo install -m 0644 "$ASSET_DIR/pacman.conf" /etc/pacman.conf
# fi

# ------------------ minimal pacman prep ------------------
# Only multilib for 32-bit libs if needed. Chaotic-AUR setup (with mirrorlist) is
# handled later in 01-packages.sh so we never have a broken Include.
ensure_multilib_enabled || true

# ------------------ detect GPU + packages ----------------
GPU_VENDOR="generic"
if lspci | grep -iE ' vga|3d|display' | grep -qi nvidia; then
    GPU_VENDOR="nvidia"
elif lspci | grep -iE ' vga|3d|display' | grep -qi amd; then
    GPU_VENDOR="amd"
elif lspci | grep -iE ' vga|3d|display' | grep -qi intel; then GPU_VENDOR="intel"; fi
log_status "Detected GPU vendor: $GPU_VENDOR"

case "$GPU_VENDOR" in
amd)
    GFX_PKGS=(mesa vulkan-radeon libva-mesa-driver)
    LIB32_GFX=(lib32-mesa lib32-vulkan-radeon)
    ;;
intel)
    GFX_PKGS=(mesa vulkan-intel libva-intel-driver)
    LIB32_GFX=(lib32-mesa lib32-vulkan-intel)
    ;;
nvidia)
    GFX_PKGS=(nvidia nvidia-utils)
    LIB32_GFX=(lib32-nvidia-utils)
    ;;
*)
    GFX_PKGS=(mesa)
    LIB32_GFX=(lib32-mesa)
    ;;
esac

AVAILABLE_LIB32=()
for p in "${LIB32_GFX[@]}"; do repo_has "$p" && AVAILABLE_LIB32+=("$p"); done

BASE_PKGS=(networkmanager pipewire pipewire-pulse pipewire-jack wireplumber gvfs gvfs-mtp noto-fonts ttf-dejavu)
# Safe fallback for terminals (05-setup_defaults.sh not yet run in this flow; user sets via interactive or manually)
OPT_TERMS=(kitty alacritty)
OPT_EXTRAS=(wlogout swaybg hyprlock)

# ---------------------- install ----------------------
# Ensure mirrorlist is seeded early (same reason as in 01-packages)
if [[ ! -s /etc/pacman.d/mirrorlist ]]; then
    log_status "Seeding initial mirrorlist (bootstrap)..."
    echo 'Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch' | sudo tee /etc/pacman.d/mirrorlist >/dev/null
fi

log_status "Refreshing package databases"
sudo pacman -Syu --noconfirm

# Preempt the common pipewire-jack vs jack2 conflict (same issue that can appear
# later in 01-packages). Remove legacy jack2 if present so the PipeWire
# implementation can satisfy the 'jack' dependency without prompts or failures.
if pacman -Qq jack2 &>/dev/null; then
    log_status "Removing conflicting jack2 (will use pipewire-jack instead)..."
    sudo pacman -Rdd --noconfirm jack2 2>/dev/null || true
fi

# Hyprland must be available before the rest of the desktop stack.
HYPRLAND_CORE_PKGS=(hyprland xdg-desktop-portal xdg-desktop-portal-hyprland)
log_status "Installing Hyprland (priority — first desktop package)…"
ensure_pkg "${HYPRLAND_CORE_PKGS[@]}"
if ! pkg_installed hyprland; then
    log_error "Hyprland failed to install during preflight — aborting"
    exit 1
fi
log_success "Hyprland core stack installed"

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

# ---------------------- services ----------------------
log_status "Enabling services"
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now pipewire.service wireplumber.service pipewire-pulse.service 2>/dev/null || true
# SDDM enable moved to after packages in 03-setup for direct flow (Hyprland/Sddm after yay)

# Chaotic-AUR (with its own mirrorlist) is set up in 01-packages.sh after the pkgs are fetched via direct URL.
# We deliberately avoid early Include of chaotic-mirrorlist here.

# ------------------- optional assets -------------------
PREFLIGHT_DIR="$ASSET_DIR/preflight"
if [[ -d "$PREFLIGHT_DIR" ]]; then
    log_status "Applying preflight assets from $PREFLIGHT_DIR"
    [[ -d "$PREFLIGHT_DIR/etc" ]] && sudo rsync -a "$PREFLIGHT_DIR/etc/." /etc/
    [[ -d "$PREFLIGHT_DIR/usr_share" ]] && sudo rsync -a "$PREFLIGHT_DIR/usr_share/." /usr/share/
    if [[ -d "$PREFLIGHT_DIR/systemd" ]]; then
        sudo rsync -a "$PREFLIGHT_DIR/systemd/." /etc/systemd/system/
        sudo systemctl daemon-reload
    fi
    if [[ -f "$PREFLIGHT_DIR/env" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            key="${line%%=*}"
            if grep -qE "^${key}=" /etc/environment 2>/dev/null; then
                sudo sed -i 's|^'"$key"'=.*$|'"$line"'|' /etc/environment
            else
                echo "$line" | sudo tee -a /etc/environment >/dev/null
            fi
        done <"$PREFLIGHT_DIR/env"
    fi
fi

mark_completed "Preflight: Hyprland base"
log_success "Preflight check completed."
