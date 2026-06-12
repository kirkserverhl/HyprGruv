#!/bin/bash
# setup-chaotic-aur.sh
# Properly sets up Chaotic-AUR repo + mirrorlist on fresh Arch installs
# Run with: bash setup-chaotic-aur.sh  (or sudo if needed)

set -euo pipefail

echo "=== Chaotic-AUR Setup Script ==="

# Check for root/sudo
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo or as root."
    exit 1
fi

# Key and packages
KEY="3056513887B78AEB"
KEYSERVER="keyserver.ubuntu.com"
CDN="https://cdn-mirror.chaotic.cx/chaotic-aur"

# Backup pacman.conf
PACMAN_CONF="/etc/pacman.conf"
BACKUP_CONF="${PACMAN_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
if [[ ! -f "${BACKUP_CONF}" ]]; then
    cp "${PACMAN_CONF}" "${BACKUP_CONF}"
    echo "✅ Backed up ${PACMAN_CONF} to ${BACKUP_CONF}"
fi

# Step 1: Import and sign key if needed
echo "🔑 Importing and signing Chaotic-AUR key..."
pacman-key --recv-key "${KEY}" --keyserver "${KEYSERVER}" || true
pacman-key --lsign-key "${KEY}"

# Step 2: Install keyring + mirrorlist (idempotent)
echo "📦 Installing chaotic-keyring and chaotic-mirrorlist..."
pacman -U --noconfirm "${CDN}/chaotic-keyring.pkg.tar.zst" \
    "${CDN}/chaotic-mirrorlist.pkg.tar.zst" 2>/dev/null ||
    pacman -S --noconfirm chaotic-keyring chaotic-mirrorlist

# Step 3: Add repo to pacman.conf if not present
if ! grep -q "\[chaotic-aur\]" "${PACMAN_CONF}"; then
    echo "📝 Adding [chaotic-aur] section to ${PACMAN_CONF}..."
    cat >>"${PACMAN_CONF}" <<EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF
    echo "✅ Chaotic-AUR repo added (at the end of pacman.conf - important for priority)."
else
    echo "✅ [chaotic-aur] already configured."
fi

# Step 4: Refresh databases
echo "🔄 Refreshing package databases..."
pacman -Syyu --noconfirm

echo "🎉 Chaotic-AUR setup complete!"
echo "You can now install packages like:  sudo pacman -S package-name"
echo ""
echo "Recommended next steps:"
echo "  - Update your mirrorlist: sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist"
echo "  - Install an AUR helper if you don't have one (e.g., yay or paru)"
echo ""
echo "Script done. Enjoy the prebuilts! 🚀"
