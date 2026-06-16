#!/usr/bin/env bash
# pacseek.sh — optional Pacseek install (AUR binary; flaky as a required package)
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
}
[[ -f "$HYPR_DIR/lib/state.sh" ]] || {
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
}
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

ensure_cmd() {
    local c="$1" install_msg="$2" pkg="$3"
    if ! command -v "$c" >/dev/null 2>&1; then
        log_status "$install_msg"
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm "$pkg"
        else
            sudo pacman -S --needed --noconfirm "$pkg"
        fi
    fi
}

ensure_cmd gum "Installing gum…" gum

toilet -f graffiti Pacseek | lsd-print

gum_apply_matugen_theme

echo ""
echo "Pacseek is a TUI for browsing and installing Arch packages."
echo "This step installs the prebuilt AUR package (pacseek-bin)."
echo "Config lives in ~/.config/pacseek/ (stowed during install)."
sleep 0.5

if command -v pacseek >/dev/null 2>&1; then
    log_success "Pacseek is already installed ($(pacseek --version 2>/dev/null | head -1 || echo 'version unknown'))"
    exit 0
fi

if ! command -v yay >/dev/null 2>&1; then
    log_error "yay is required to install pacseek-bin"
    log_status "Install yay first, or try the official package: sudo pacman -S pacseek"
    exit 1
fi

log_status "Installing pacseek-bin from AUR…"
if yay -S --needed --noconfirm pacseek-bin; then
    log_success "Pacseek installed — run: pacseek"
else
    log_warning "pacseek-bin failed to build/install"
    log_status "You can try the official repo package instead: sudo pacman -S pacseek"
    exit 1
fi

