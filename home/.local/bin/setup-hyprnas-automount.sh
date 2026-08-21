#!/usr/bin/env bash
# Mount HyprNAS Archive at /mnt/nas on boot (systemd automount + nofail).
set -euo pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "This script must run as root (pkexec or sudo)." >&2
    exit 1
fi

CRED_SRC="/home/kirk/.config/samba/hyprnas.cred"
CRED_DST="/etc/samba/hyprnas.cred"
FSTAB="/etc/fstab"
MNT="/mnt/nas"
NAS_IP="192.168.1.141"
SHARE="//${NAS_IP}/Archive"
BOOT_UNIT="/etc/systemd/system/hyprnas-mount.service"
MARKER="# hyprgruv: HyprNAS Archive (automount, nofail — missing NAS must not block boot)"
OPTS="credentials=${CRED_DST},uid=1000,gid=1000,iocharset=utf8,vers=3.0,file_mode=0664,dir_mode=0775,nofail,_netdev,x-systemd.automount,x-systemd.after=network-online.target,x-systemd.wants=network-online.target,x-systemd.device-timeout=10s,x-systemd.mount-timeout=15s"
LINE="${SHARE}  ${MNT}  cifs  ${OPTS}  0  0"

if [[ ! -f "$CRED_SRC" ]]; then
    echo "Missing CIFS credentials: $CRED_SRC" >&2
    exit 1
fi

install -d -m 755 /etc/samba
install -m 600 -o root -g root "$CRED_SRC" "$CRED_DST"

if ! grep -qE '^[[:space:]]*192\.168\.1\.141[[:space:]]' /etc/hosts; then
    printf '192.168.1.141  HyprNAS hyprnas\n' >> /etc/hosts
fi

install -d -m 755 "$MNT"

if awk '$1 !~ /^#/ && $2 == "/mnt/nas" { found=1 } END { exit !found }' "$FSTAB"; then
    echo "fstab already has a /mnt/nas entry — leaving it unchanged"
else
    cp -a "$FSTAB" "${FSTAB}.bak.$(date +%Y%m%d_%H%M%S)"
    printf '\n%s\n%s\n' "$MARKER" "$LINE" >> "$FSTAB"
    echo "Appended HyprNAS entry to $FSTAB"
fi

cat > "$BOOT_UNIT" <<'EOF'
[Unit]
Description=Mount HyprNAS Archive after network is online
Documentation=file:///etc/fstab
After=network-online.target NetworkManager-wait-online.service mnt-nas.automount
Wants=network-online.target
Requires=mnt-nas.automount

[Service]
Type=oneshot
TimeoutStartSec=20
ExecStart=/usr/bin/systemctl start mnt-nas.mount
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
# fstab-generated automount units cannot be "enabled"; they start via local-fs.target.
systemctl start mnt-nas.automount
systemctl enable --now hyprnas-mount.service

sleep 1
if ! findmnt -t cifs -n "$MNT" >/dev/null; then
    echo "Mount unit started but $MNT is not a CIFS mountpoint" >&2
    systemctl --no-pager --full status mnt-nas.mount hyprnas-mount.service || true
    exit 1
fi

echo "Mounted:"
findmnt -n -o SOURCE,TARGET,FSTYPE "$MNT"
echo "Top-level:"
ls -la "$MNT"
echo
systemctl is-enabled hyprnas-mount.service
systemctl is-active mnt-nas.automount mnt-nas.mount hyprnas-mount.service
