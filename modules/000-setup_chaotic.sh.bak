#!/bin/bash
# 000-setup_chaotic.sh
# Robust standalone script to set up Chaotic-AUR (key + keyring + mirrorlist + pacman.conf entry).
# This is the correct "first step" for Chaotic-AUR.
#
# Run as:   sudo bash ~/.hyprgruv/modules/000-setup_chaotic.sh
#
# Why this is needed (and why just copying assets/pacman.conf is NOT enough):
#   - The [chaotic-aur] section in pacman.conf does "Include = /etc/pacman.d/chaotic-mirrorlist"
#   - That file (and the trusted keys) only appear after installing chaotic-keyring + chaotic-mirrorlist.
#   - Those two packages are NOT in the official Arch repos — you must bootstrap them with direct
#     pacman -U of the .pkg.tar.zst URLs *before* the repo section is active.
#   - Simply dropping a pacman.conf that references the mirrorlist will cause:
#       "error: config file /etc/pacman.d/chaotic-mirrorlist could not be read: No such file or directory"
#       or signature/keyring failures on the next pacman run.
#   - The "you do not have sufficient permissions to read the pacman keyring" error is almost always
#     caused by running pacman-key commands without root, or a corrupted /etc/pacman.d/gnupg directory
#     (common after partial/failed installs or in VMs). We fix that first here.
#
# This script is deliberately defensive for VMs (network flakiness, NAT, slow CDN).
# It will only enable the [chaotic-aur] section if the bootstrap actually succeeds.

set -euo pipefail

# --- Must be root ---
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Please run with sudo:  sudo bash $0"
    exit 1
fi

echo "=== Chaotic-AUR Setup (robust) ==="

KEY="3056513887B78AEB"
KEYSERVER="keyserver.ubuntu.com"
CDN="https://cdn-mirror.chaotic.cx/chaotic-aur"
PACMAN_CONF="/etc/pacman.conf"

# 1. Backup pacman.conf (idempotent)
BACKUP_CONF="${PACMAN_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
if [[ ! -f "$BACKUP_CONF" ]]; then
    cp -a "$PACMAN_CONF" "$BACKUP_CONF"
    echo "✅ Backed up $PACMAN_CONF to $BACKUP_CONF"
fi

# 2. Fix the pacman keyring permission/read error (the #1 cause of your VM failure)
#    This is the critical first real step.
ensure_pacman_keyring() {
    echo "🔐 Checking pacman keyring usability..."
    if pacman-key --list-keys >/dev/null 2>&1; then
        echo "✅ Keyring is readable."
        return 0
    fi

    echo "⚠️  Pacman keyring not readable or uninitialized (permissions error or bad state)."
    echo "    Reinitializing /etc/pacman.d/gnupg as root..."

    rm -rf /etc/pacman.d/gnupg
    pacman-key --init
    pacman-key --populate archlinux

    # One more check
    if ! pacman-key --list-keys >/dev/null 2>&1; then
        echo "❌ Keyring still unreadable after re-init. Check ownership:"
        echo "    ls -ld /etc/pacman.d/gnupg ; ls -l /etc/pacman.d/gnupg/"
        echo "    Typical fix: chown -R root:root /etc/pacman.d/gnupg && chmod 700 /etc/pacman.d/gnupg"
        exit 1
    fi
    echo "✅ Keyring reinitialized and readable."
}
ensure_pacman_keyring

# 3. Import + locally sign the Chaotic-AUR master key (do this before installing their keyring pkg)
echo "🔑 Importing and locally signing Chaotic-AUR key..."
pacman-key --recv-key "${KEY}" --keyserver "${KEYSERVER}" || true
pacman-key --lsign-key "${KEY}" || true

# 4. Bootstrap install of chaotic-keyring + chaotic-mirrorlist via direct CDN URLs.
#    This must succeed BEFORE we add the [chaotic-aur] section (chicken/egg).
#    The fallback pacman -S would only work after the repo is enabled, so we avoid it.
echo "📦 Bootstrapping chaotic-keyring and chaotic-mirrorlist (direct download)..."
CHAOTIC_OK=0
if pacman -U --noconfirm \
    "${CDN}/chaotic-keyring.pkg.tar.zst" \
    "${CDN}/chaotic-mirrorlist.pkg.tar.zst" ; then
    CHAOTIC_OK=1
    echo "✅ chaotic-keyring + chaotic-mirrorlist installed via direct bootstrap."
else
    echo "⚠️  Direct bootstrap from CDN failed (very common in VMs due to network/NAT/latency)."
    echo "    The [chaotic-aur] section will NOT be enabled yet."
    echo "    You can re-run this script after fixing network, or manually:"
    echo "      curl -LO ${CDN}/chaotic-keyring.pkg.tar.zst"
    echo "      curl -LO ${CDN}/chaotic-mirrorlist.pkg.tar.zst"
    echo "      pacman -U --noconfirm *.pkg.tar.zst"
fi

# 5. ONLY add the repo section if we actually have the mirrorlist file now.
MIRRORLIST="/etc/pacman.d/chaotic-mirrorlist"
if [[ $CHAOTIC_OK -eq 1 && -f "$MIRRORLIST" ]]; then
    if ! grep -q '^\[chaotic-aur\]' "$PACMAN_CONF"; then
        echo "📝 Adding [chaotic-aur] section to $PACMAN_CONF..."
        printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' >> "$PACMAN_CONF"
        echo "✅ Chaotic-AUR repo enabled."
    else
        echo "✅ [chaotic-aur] already present in pacman.conf."
    fi

    # De-prefer known flaky mirrors (e.g. warp.dev has caused issues)
    echo "🪞 Sanitizing $MIRRORLIST (commenting problematic mirrors)..."
    sed -i -E 's|^[[:space:]]*Server[[:space:]]*=[[:space:]]*.*(warp\.dev).*|# &|' "$MIRRORLIST" || true
else
    # Safety: never leave a broken Include pointing at a non-existent file
    if grep -q '^\[chaotic-aur\]' "$PACMAN_CONF" && [[ ! -f "$MIRRORLIST" ]]; then
        echo "🧹 Removing broken [chaotic-aur] section (mirrorlist file missing)..."
        if awk '
            BEGIN { insec=0 }
            /^\[chaotic-aur\]/ { insec=1; next }
            /^\[/ && insec { insec=0 }
            { if (!insec) print }
        ' "$PACMAN_CONF" > "${PACMAN_CONF}.tmp.$$"; then
            mv "${PACMAN_CONF}.tmp.$$" "$PACMAN_CONF" || true
        else
            rm -f "${PACMAN_CONF}.tmp.$$" || true
        fi
    fi
fi

# 6. Clean any EndeavourOS (or other derivative) remnants so we stay pure Arch + chaotic.
#    (safe to run even if nothing to do)
if grep -q '^\[endeavouros\]' "$PACMAN_CONF" 2>/dev/null; then
    echo "🧹 Purging EndeavourOS remnants..."
    # (lightweight inline version of the purge in lib/common.sh)
    if awk '
        BEGIN { insec=0 }
        /^\[endeavouros\]/ { insec=1; next }
        /^\[/ && insec { insec=0 }
        { if (!insec) print }
    ' "$PACMAN_CONF" > "${PACMAN_CONF}.tmp.$$"; then
        mv "${PACMAN_CONF}.tmp.$$" "$PACMAN_CONF" || true
    else
        rm -f "${PACMAN_CONF}.tmp.$$" || true
    fi
    rm -f /etc/pacman.d/endeavouros-mirrorlist 2>/dev/null || true
    pacman -Rdd --noconfirm endeavouros-keyring endeavouros-mirrorlist 2>/dev/null || true
fi

# 7. Hard refresh. We do -Syy (not full -Syyu) here so this script stays focused on repo setup.
#    A later full system update can be done by the main installer or manually.
echo "🔄 Refreshing pacman databases (Syy)..."
rm -f /var/lib/pacman/sync/chaotic-aur.db* 2>/dev/null || true
if pacman -Syy --noconfirm; then
    echo "✅ Databases refreshed."
else
    echo "⚠️  pacman -Syy had warnings/errors (continuing; you may need to run it again after network improves)."
fi

echo ""
echo "🎉 Chaotic-AUR setup script finished."
if [[ $CHAOTIC_OK -eq 1 && -f "$MIRRORLIST" ]] && grep -q '^\[chaotic-aur\]' "$PACMAN_CONF"; then
    echo "   Chaotic-AUR is ENABLED. You can now install packages from it (e.g. brave-bin, ghostty-bin, etc.)."
else
    echo "   Chaotic-AUR is NOT fully enabled yet (bootstrap step failed or skipped)."
    echo "   Re-run this script after ensuring good outbound network from the VM."
    echo "   Or use the DRY-capable version:"
    echo "     DRY_RUN=1 bash ~/.hyprgruv/lib/scripts/chaotic.sh"
    echo "     bash ~/.hyprgruv/lib/scripts/chaotic.sh"
fi
echo ""
echo "Next recommended (after full install):"
echo "  sudo reflector --latest 10 --sort rate --save /etc/pacman.d/mirrorlist"
echo "  sudo pacman -Syyu"
echo ""
echo "Done."
