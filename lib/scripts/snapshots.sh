#!/usr/bin/env bash
# snapshots.sh — guided Timeshift + grub-btrfs + optional off-disk replica
#
# Layers (all optional):
#   1. Local Timeshift snapshots + GRUB boot entries (grub-btrfs --timeshift-auto)
#   2. Incremental replica to a separate disk (btrbk send/receive, or rsync)
#   3. Weekly rsync of that replica to a NAS mount
#
# Non-interactive (optional):
#   SNAPSHOTS_SETUP=skip|local|full
#   BACKUP_DISK=/dev/sda1
#   BACKUP_MOUNT=/mnt/backup-ssd
#   NAS_DEST=/mnt/nas/HyprGruv/snapshots
#   SNAPSHOTS_TIMER=hourly|daily|weekly
#   SNAPSHOTS_HOOK=1
#   SNAPSHOTS_FIRST=0
#   SNAPSHOTS_FORMAT=0
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

SNAP_TEMPLATES="$HYPR_DIR/lib/snapshot"
TIMESHIFT_JSON="/etc/timeshift/timeshift.json"
AUTOSNAP_CONF="/etc/timeshift-autosnap.conf"
BTRBK_CONF="/etc/btrbk/hyprgruv.conf"
SNAP_ENV="/etc/hyprgruv/snapshots.env"
BTRFS_ROOT_MNT="/mnt/btrfs-root"
DEFAULT_BACKUP_MNT="/mnt/backup-ssd"
DEFAULT_NAS_DEST="/mnt/nas/HyprGruv/snapshots"

BACKUP_MOUNT="${BACKUP_MOUNT:-$DEFAULT_BACKUP_MNT}"
NAS_DEST="${NAS_DEST:-$DEFAULT_NAS_DEST}"

LAYER1=0
LAYER2=0
LAYER2_KIND=""
LAYER3=0
ROOT_FSTYPE=""
ROOT_UUID=""
ROOT_SOURCE=""
ROOT_DEV=""
ROOT_LUKS=0
ROOT_DISK=""
DID_GRUB_MKCONFIG=0

ensure_cmd() {
    local c="$1" install_msg="$2" pkg="$3"
    if command -v "$c" >/dev/null 2>&1; then
        return 0
    fi
    log_status "$install_msg"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "$pkg"
    else
        sudo pacman -S --needed --noconfirm "$pkg"
    fi
}

is_noninteractive() {
    [[ -n "${SNAPSHOTS_SETUP:-}" ]]
}

confirm() {
    local prompt="$1"
    if command -v gum >/dev/null 2>&1; then
        gum_confirm_prompt "$prompt"
    else
        local ans=""
        if _hyprgruv_has_tty; then
            read -rp "$prompt [y/N]: " ans </dev/tty
        else
            read -rp "$prompt [y/N]: " ans
        fi
        [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
    fi
}

pick() {
    hyprgruv_pick "$@"
}

ask_text() {
    local prompt="$1"
    local default="${2:-}"
    local reply=""
    if command -v gum >/dev/null 2>&1; then
        set +e
        if _hyprgruv_has_tty && ! [[ -t 0 ]]; then
            reply="$(gum input --prompt "$prompt " --value "$default" </dev/tty)"
        else
            reply="$(gum input --prompt "$prompt " --value "$default")"
        fi
        set -e
    fi
    if [[ -z "$reply" ]]; then
        if _hyprgruv_has_tty; then
            read -rp "$prompt ${default:+[$default] }: " reply </dev/tty
        else
            read -rp "$prompt ${default:+[$default] }: " reply
        fi
        reply="${reply:-$default}"
    fi
    printf '%s\n' "$reply"
}

backup_file() {
    local path="$1"
    [[ -e "$path" ]] || return 0
    sudo cp -a "$path" "${path}.bak.$(date +%Y%m%d_%H%M%S)"
}

install_pkg() {
    local pkg="$1"
    if pacman -Qq "$pkg" &>/dev/null; then
        log_success "$pkg already installed"
        return 0
    fi
    log_status "Installing $pkg…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm "$pkg"
    else
        sudo pacman -S --needed --noconfirm "$pkg"
    fi
}

device_uuid() {
    local dev="$1"
    lsblk -no UUID "$dev" 2>/dev/null | awk 'NF{print; exit}'
}

device_fstype() {
    local dev="$1"
    local fs=""
    fs="$(lsblk -no FSTYPE "$dev" 2>/dev/null | awk 'NF && $1 != "crypto_LUKS" {print; exit}')"
    if [[ -z "$fs" ]]; then
        fs="$(blkid -s TYPE -o value "$dev" 2>/dev/null | awk 'NF{print; exit}')"
    fi
    printf '%s\n' "$fs"
}

fstab_has_uuid() {
    local uuid="$1"
    grep -qE "^[[:space:]]*UUID=${uuid}[[:space:]]" /etc/fstab 2>/dev/null
}

fstab_has_mount() {
    local mnt="$1"
    awk -v m="$mnt" '$1 !~ /^#/ && $2 == m { found=1 } END { exit !found }' /etc/fstab
}

fstab_add() {
    local line="$1"
    local comment="${2:-# hyprgruv snapshots.sh}"
    if grep -Fqx "$line" /etc/fstab 2>/dev/null; then
        return 0
    fi
    backup_file /etc/fstab
    printf '\n%s\n%s\n' "$comment" "$line" | sudo tee -a /etc/fstab >/dev/null
}

crypttab_add() {
    local name="$1" uuid="$2" opts="${3:-none nofail,noauto}"
    sudo touch /etc/crypttab
    if grep -qE "^[[:space:]]*${name}[[:space:]]" /etc/crypttab 2>/dev/null; then
        return 0
    fi
    backup_file /etc/crypttab
    printf '%s UUID=%s %s\n' "$name" "$uuid" "$opts" | sudo tee -a /etc/crypttab >/dev/null
}

install_template() {
    local src="$1" dest="$2"
    shift 2
    [[ -f "$src" ]] || {
        log_error "Missing template: $src"
        return 1
    }
    local content
    content="$(cat "$src")"
    while (( $# >= 2 )); do
        local key="$1" val="$2"
        content="${content//$key/$val}"
        shift 2
    done
    sudo mkdir -p "$(dirname "$dest")"
    printf '%s\n' "$content" | sudo tee "$dest" >/dev/null
}

write_snap_env() {
    sudo mkdir -p /etc/hyprgruv
    sudo tee "$SNAP_ENV" >/dev/null <<EOF
# Generated by hyprgruv lib/scripts/snapshots.sh
HYPRGRUV_ROOT_FSTYPE=${ROOT_FSTYPE}
HYPRGRUV_ROOT_LUKS=${ROOT_LUKS}
HYPRGRUV_LAYER1=${LAYER1}
HYPRGRUV_LAYER2=${LAYER2}
HYPRGRUV_LAYER2_KIND=${LAYER2_KIND}
HYPRGRUV_LAYER3=${LAYER3}
HYPRGRUV_BACKUP_MOUNT=${BACKUP_MOUNT}
HYPRGRUV_BTRBK_TARGET=${BACKUP_MOUNT}/btrbk
HYPRGRUV_NAS_DEST=${NAS_DEST}
EOF
    sudo chmod 644 "$SNAP_ENV"
}

detect_root() {
    ROOT_SOURCE="$(findmnt -no SOURCE /)"
    # btrfs findmnt prints /dev/nvme0n1p2[/@] — strip the subvol suffix
    ROOT_DEV="${ROOT_SOURCE%%[*}"
    ROOT_DEV="${ROOT_DEV%% *}"
    ROOT_FSTYPE="$(findmnt -no FSTYPE /)"
    ROOT_UUID="$(findmnt -no UUID /)"
    ROOT_DISK="$(lsblk -nrso NAME,TYPE "$ROOT_DEV" 2>/dev/null | awk '$2=="disk"{print $1; exit}')"
    if [[ -z "$ROOT_DISK" ]]; then
        ROOT_DISK="$(lsblk -ndo PKNAME "$ROOT_DEV" 2>/dev/null | awk 'NF{print; exit}')"
    fi
    ROOT_DISK="${ROOT_DISK##*/}"
}

detect_luks() {
    ROOT_LUKS=0
    if [[ "$ROOT_DEV" == /dev/mapper/* || "$ROOT_SOURCE" == /dev/mapper/* ]]; then
        ROOT_LUKS=1
    fi
    if grep -qE 'rd\.luks|cryptdevice=' /proc/cmdline 2>/dev/null; then
        ROOT_LUKS=1
    fi
    if [[ -f /etc/crypttab ]] && grep -qvE '^[[:space:]]*(#|$)' /etc/crypttab; then
        ROOT_LUKS=1
    fi
    if [[ -n "$ROOT_DEV" ]] && lsblk -no TYPE,FSTYPE "$ROOT_DEV" 2>/dev/null | grep -qE 'crypt|crypto_LUKS'; then
        ROOT_LUKS=1
    fi
    if [[ -n "$ROOT_DEV" ]] && lsblk -nso FSTYPE "$ROOT_DEV" 2>/dev/null | grep -qx crypto_LUKS; then
        ROOT_LUKS=1
    fi
}

root_is_btrfs() {
    [[ "$ROOT_FSTYPE" == "btrfs" ]]
}

grub_btrfsd_healthy() {
    systemctl cat grub-btrfsd.service 2>/dev/null | grep -q -- '--timeshift-auto' \
        && systemctl is-enabled grub-btrfsd.service &>/dev/null
}

print_detection() {
    echo ""
    echo "  Root source : ${ROOT_DEV:-${ROOT_SOURCE:-unknown}}"
    echo "  Filesystem  : ${ROOT_FSTYPE:-unknown}"
    echo "  UUID        : ${ROOT_UUID:-unknown}"
    echo "  Disk        : ${ROOT_DISK:-unknown}"
    if [[ "$ROOT_LUKS" -eq 1 ]]; then
        echo "  Encryption  : LUKS (snapshots stay inside the unlocked volume)"
    else
        echo "  Encryption  : none detected"
    fi
    echo ""
}

want_layer1() {
    case "${SNAPSHOTS_SETUP:-}" in
        skip) return 1 ;;
        local | full) return 0 ;;
    esac
    if root_is_btrfs; then
        confirm "Set up local Timeshift snapshots and GRUB boot entries?"
    else
        confirm "Root is ${ROOT_FSTYPE:-unknown} — set up Timeshift in rsync mode (no GRUB snapshot menu)?"
    fi
}

want_layer2() {
    case "${SNAPSHOTS_SETUP:-}" in
        skip | local) return 1 ;;
        full) return 0 ;;
    esac
    confirm "Replicate to a separate disk (Kingston / backup SSD)?"
}

want_layer3() {
    case "${SNAPSHOTS_SETUP:-}" in
        skip | local) return 1 ;;
        full)
            [[ -n "${NAS_DEST:-}" && -d "$(dirname "$NAS_DEST")" ]]
            return $?
            ;;
    esac
    local nas_mnt
    nas_mnt="$(nas_mount_from_dest "$NAS_DEST")"
    if findmnt "$nas_mnt" >/dev/null 2>&1; then
        confirm "Also copy the off-disk replica to the NAS weekly (${NAS_DEST})?"
    else
        confirm "NAS is not mounted at ${nas_mnt}. Configure a weekly replica anyway (no-ops until mounted)?"
    fi
}

nas_mount_from_dest() {
    local dest="$1"
    if [[ "$dest" == /mnt/nas/* || "$dest" == /mnt/nas ]]; then
        echo "/mnt/nas"
        return
    fi
    echo "$(df -P "$dest" 2>/dev/null | awk 'NR==2{print $6}')"
}

ensure_btrfs_toplevel() {
    [[ -n "$ROOT_UUID" ]] || return 1
    sudo mkdir -p "$BTRFS_ROOT_MNT"
    if ! findmnt "$BTRFS_ROOT_MNT" >/dev/null 2>&1; then
        sudo mount -o "subvolid=5,noatime,compress=zstd" "UUID=${ROOT_UUID}" "$BTRFS_ROOT_MNT"
    fi
    if ! fstab_has_mount "$BTRFS_ROOT_MNT"; then
        fstab_add \
            "UUID=${ROOT_UUID}  ${BTRFS_ROOT_MNT}  btrfs  subvolid=5,noatime,compress=zstd  0  0" \
            "# hyprgruv: btrfs top-level (btrbk + Timeshift siblings)"
    fi
}

write_timeshift_json() {
    local mode="$1"
    local uuid="$2"
    local btrfs_mode="false"
    local include_home="false"
    if [[ "$mode" == "btrfs" ]]; then
        btrfs_mode="true"
        include_home="true"
    fi
    sudo mkdir -p /etc/timeshift
    if [[ -f "$TIMESHIFT_JSON" ]]; then
        if is_noninteractive || confirm "Timeshift config exists. Overwrite ${TIMESHIFT_JSON}?"; then
            backup_file "$TIMESHIFT_JSON"
        else
            log_status "Keeping existing Timeshift config"
            return 0
        fi
    fi
    sudo tee "$TIMESHIFT_JSON" >/dev/null <<EOF
{
  "backup_device_uuid" : "${uuid}",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "${btrfs_mode}",
  "include_btrfs_home_for_backup" : "${include_home}",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "true",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "true",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "2",
  "count_daily" : "5",
  "count_hourly" : "5",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
EOF
    log_success "Wrote $TIMESHIFT_JSON (${mode} mode)"
}

write_autosnap_conf() {
    if [[ -f "$AUTOSNAP_CONF" ]] && grep -q '^skipAutosnap=' "$AUTOSNAP_CONF"; then
        log_status "Keeping existing $AUTOSNAP_CONF"
        return 0
    fi
    [[ -f "$AUTOSNAP_CONF" ]] && backup_file "$AUTOSNAP_CONF"
    sudo tee "$AUTOSNAP_CONF" >/dev/null <<'EOF'
skipAutosnap=false
deleteSnapshots=true
maxSnapshots=15
updateGrub=true
snapshotDescription={timeshift-autosnap} {created before upgrade}
EOF
    log_success "Wrote $AUTOSNAP_CONF"
}

fix_grub_btrfsd() {
    local dest="/etc/systemd/system/grub-btrfsd.service.d/hyprgruv.conf"
    install_template "$SNAP_TEMPLATES/grub-btrfsd-dropin.conf" "$dest"
    sudo systemctl daemon-reload
    sudo systemctl enable --now grub-btrfsd.service
    if systemctl is-active --quiet grub-btrfsd.service; then
        log_success "grub-btrfsd is running with --timeshift-auto"
    else
        log_warning "grub-btrfsd enabled but not active yet (needs a Timeshift snapshot directory)"
        sudo systemctl reset-failed grub-btrfsd.service 2>/dev/null || true
        sudo systemctl restart grub-btrfsd.service 2>/dev/null || true
    fi
}

maybe_grub_mkconfig() {
    [[ -d /boot/grub ]] || {
        log_warning "/boot/grub missing — skip grub-mkconfig"
        return 0
    }
    log_status "Rebuilding GRUB config (snapshot submenu)"
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    DID_GRUB_MKCONFIG=1
}

setup_layer1_btrfs() {
    install_pkg timeshift
    install_pkg grub-btrfs
    install_pkg timeshift-autosnap
    write_timeshift_json btrfs "$ROOT_UUID"
    write_autosnap_conf
    fix_grub_btrfsd
    maybe_grub_mkconfig
    LAYER1=1

    local do_first=0
    case "${SNAPSHOTS_FIRST:-}" in
        1 | yes | true) do_first=1 ;;
        0 | no | false) do_first=0 ;;
        *)
            if ! is_noninteractive && confirm "Create an initial Timeshift snapshot now?"; then
                do_first=1
            fi
            ;;
    esac
    if [[ "$do_first" -eq 1 ]]; then
        log_status "Creating initial Timeshift snapshot…"
        sudo timeshift --create --comments "hyprgruv-initial" || log_warning "timeshift --create failed"
        sudo timeshift --list || true
        if [[ "$DID_GRUB_MKCONFIG" -eq 1 ]]; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg || true
        fi
    fi
}

setup_layer1_rsync() {
    install_pkg timeshift
    install_pkg timeshift-autosnap
    local uuid="$ROOT_UUID"
    if [[ -n "${BACKUP_DISK:-}" ]]; then
        uuid="$(device_uuid "$BACKUP_DISK" || true)"
    fi
    write_timeshift_json rsync "${uuid:-$ROOT_UUID}"
    write_autosnap_conf
    LAYER1=1
    log_status "ext4/other root: Timeshift rsync mode (no grub-btrfs submenu)"
}

candidate_lines() {
    local NAME TYPE SIZE FSTYPE MOUNTPOINT UUID PKNAME
    local pkname model pk_dev shown_fs
    while IFS= read -r line; do
        eval "$line"
        [[ "${TYPE:-}" == "part" ]] || continue
        [[ -n "${NAME:-}" ]] || continue
        pkname="${PKNAME:-}"
        pkname="${pkname##*/}"
        if [[ -n "$ROOT_DISK" && ( "$pkname" == "$ROOT_DISK" || "${NAME##*/}" == "$ROOT_DISK"* ) ]]; then
            continue
        fi
        pk_dev="$pkname"
        [[ -z "$pk_dev" || "$pk_dev" == /dev/* ]] || pk_dev="/dev/${pk_dev}"
        model=""
        if [[ -n "$pk_dev" && -b "$pk_dev" ]]; then
            model="$(lsblk -ndno MODEL "$pk_dev" 2>/dev/null | tr -s ' ' || true)"
        fi
        shown_fs="${FSTYPE:-}"
        if [[ -z "$shown_fs" && -n "${MOUNTPOINT:-}" && "$MOUNTPOINT" != "-" ]]; then
            shown_fs="$(findmnt -no FSTYPE "$MOUNTPOINT" 2>/dev/null || true)"
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$NAME" "${SIZE:-?}" "${shown_fs:-none}" "${MOUNTPOINT:--}" "${model:-disk}" "${UUID:-}"
    done < <(lsblk -pP -o NAME,TYPE,SIZE,FSTYPE,MOUNTPOINT,UUID,PKNAME)
}

choose_backup_disk() {
    if [[ -n "${BACKUP_DISK:-}" ]]; then
        printf '%s\n' "$BACKUP_DISK"
        return 0
    fi

    local -a labels=()
    local -a devices=()
    local name size fstype mnt model
    while IFS=$'\t' read -r name size fstype mnt model _; do
        [[ -n "$name" ]] || continue
        devices+=("$name")
        labels+=("${name}  ${size}  ${fstype}  ${mnt}  ${model}")
    done < <(candidate_lines)

    if ((${#labels[@]} == 0)); then
        log_warning "No extra partitions found (anything not on ${ROOT_DISK:-root disk})"
        if is_noninteractive; then
            return 1
        fi
        local typed
        typed="$(ask_text "Device path to use as backup disk (empty to skip):" "")"
        [[ -n "$typed" ]] || return 1
        printf '%s\n' "$typed"
        return 0
    fi

    if is_noninteractive; then
        printf '%s\n' "${devices[0]}"
        return 0
    fi

    labels+=("Enter device path…")
    labels+=("Skip")

    hyprgruv_tty_echo ""
    hyprgruv_tty_echo "  Extra-disk replica (not the Timeshift / GRUB disk)."
    hyprgruv_tty_echo "  Choose ONE partition for the off-disk copy."
    local choice
    choice="$(pick "Backup disk:" "${labels[@]}")" || return 1
    case "$choice" in
        Skip | "") return 1 ;;
        "Enter device path…")
            ask_text "Device path:" "/dev/sda1"
            ;;
        *)
            backup_dev_from_choice "$choice"
            ;;
    esac
}

backup_dev_from_choice() {
    local raw="$1"
    local token=""
    token="$(printf '%s\n' "$raw" | grep -oE '/dev/[^[:space:]]+' | head -1 || true)"
    if [[ -z "$token" ]]; then
        log_error "Could not read a /dev/… path from: $raw"
        return 1
    fi
    printf '%s\n' "$token"
}

is_root_backing() {
    local dev="$1"
    local short="${dev#/dev/}"
    local pk src_short
    pk="$(lsblk -ndo PKNAME "$dev" 2>/dev/null || true)"
    pk="${pk##*/}"
    src_short="${ROOT_DEV#/dev/}"
    src_short="${src_short%%[*}"
    [[ "$short" == "$ROOT_DISK" || "$pk" == "$ROOT_DISK" || "$short" == "$src_short" ]] && return 0
    return 1
}

prepare_backup_disk() {
    local dev="$1"
    [[ -b "$dev" ]] || {
        log_error "Not a block device: $dev"
        return 1
    }
    if is_root_backing "$dev"; then
        log_error "Refusing to use root disk device $dev"
        return 1
    fi

    local fstype current_mnt
    fstype="$(device_fstype "$dev")"
    current_mnt="$(lsblk -no MOUNTPOINT "$dev" | awk 'NF{print; exit}')"

    if [[ -n "$current_mnt" ]]; then
        BACKUP_MOUNT="$current_mnt"
        log_status "$dev already mounted at $BACKUP_MOUNT"
        if [[ -e "$BACKUP_MOUNT/hyprgruv-home" ]]; then
            log_status "Existing hyprgruv-home tree left untouched"
        fi
        return 0
    fi

    if [[ -z "$fstype" || "$fstype" == "crypto_LUKS" ]]; then
        # lsblk often misses a filesystem when a stale signature is also present.
        local probe=""
        probe="$(sudo blkid -s TYPE -o value "$dev" 2>/dev/null | awk 'NF{print; exit}')"
        [[ -n "$probe" && "$probe" != "crypto_LUKS" ]] && fstype="$probe"
    fi

    if [[ -n "$fstype" && "$fstype" != "crypto_LUKS" ]]; then
        sudo mkdir -p "$BACKUP_MOUNT"
        sudo mount "$dev" "$BACKUP_MOUNT"
        log_success "Mounted $dev → $BACKUP_MOUNT ($fstype)"
        ensure_backup_fstab "$dev" "$fstype" ""
        return 0
    fi

    if sudo wipefs -n "$dev" 2>/dev/null | grep -qiE 'btrfs|ext[234]|xfs|ntfs|vfat|exfat|f2fs'; then
        log_error "$dev has a filesystem signature lsblk missed — refusing to format (data would be lost)"
        sudo wipefs -n "$dev" || true
        return 1
    fi

    local do_format=0
    local use_luks=0
    if [[ "${SNAPSHOTS_FORMAT:-0}" == "1" ]]; then
        do_format=1
        [[ "$ROOT_LUKS" -eq 1 ]] && use_luks=1
    elif is_noninteractive; then
        log_error "$dev has no filesystem and SNAPSHOTS_FORMAT!=1 — will not format unattended"
        return 1
    else
        echo ""
        log_warning "$dev has no usable filesystem."
        if [[ "$ROOT_LUKS" -eq 1 ]]; then
            echo "  Root is LUKS. A plaintext backup disk would hold an unlocked copy of the encrypted system."
            local fmt
            fmt="$(pick "Format ${dev} as:" \
                "LUKS + Btrfs (recommended with encrypted root)" \
                "Plain Btrfs (data at rest will not be encrypted)" \
                "Cancel")" || return 1
            case "$fmt" in
                "LUKS + Btrfs"*)
                    do_format=1
                    use_luks=1
                    ;;
                "Plain Btrfs"*)
                    do_format=1
                    use_luks=0
                    ;;
                *) return 1 ;;
            esac
        else
            if confirm "Format ${dev} as Btrfs for snapshot replicas? This erases the device."; then
                do_format=1
            else
                return 1
            fi
        fi
        local short="${dev##*/}"
        local typed
        typed="$(ask_text "Type ${short} to confirm format:" "")"
        if [[ "$typed" != "$short" ]]; then
            log_warning "Confirmation mismatch — not formatting"
            return 1
        fi
    fi

    [[ "$do_format" -eq 1 ]] || return 1

    if [[ "$use_luks" -eq 1 ]]; then
        install_pkg cryptsetup
        log_status "LUKS formatting $dev (you will be prompted for a passphrase)…"
        sudo cryptsetup luksFormat "$dev"
        sudo cryptsetup open "$dev" hyprgruv-backup
        sudo mkfs.btrfs -f -L hyprgruv-backup /dev/mapper/hyprgruv-backup
        local luks_uuid
        luks_uuid="$(device_uuid "$dev")"
        crypttab_add hyprgruv-backup "$luks_uuid" "none nofail,noauto"
        sudo mkdir -p "$BACKUP_MOUNT"
        sudo mount /dev/mapper/hyprgruv-backup "$BACKUP_MOUNT"
        ensure_backup_fstab "/dev/mapper/hyprgruv-backup" btrfs "noauto"
        log_success "LUKS+Btrfs backup ready at $BACKUP_MOUNT (unlock manually after reboot)"
        log_status "Unlock: sudo cryptsetup open $dev hyprgruv-backup && sudo mount $BACKUP_MOUNT"
    else
        sudo mkfs.btrfs -f -L hyprgruv-backup "$dev"
        sudo mkdir -p "$BACKUP_MOUNT"
        sudo mount "$dev" "$BACKUP_MOUNT"
        ensure_backup_fstab "$dev" btrfs ""
        log_success "Btrfs backup ready at $BACKUP_MOUNT"
    fi
}

ensure_backup_fstab() {
    local src="$1" fstype="$2" extra="${3:-}"
    local opts="noatime,compress=zstd,nofail,x-systemd.device-timeout=8"
    [[ "$fstype" == "btrfs" ]] || opts="defaults,nofail,x-systemd.device-timeout=8"
    [[ -n "$extra" ]] && opts="${opts},${extra}"

    if [[ "$src" == /dev/mapper/* ]]; then
        if ! fstab_has_mount "$BACKUP_MOUNT"; then
            fstab_add "${src}  ${BACKUP_MOUNT}  ${fstype}  ${opts}  0  0" \
                "# hyprgruv: backup disk (nofail — missing disk must not block boot)"
        fi
        return 0
    fi
    local uuid
    uuid="$(device_uuid "$src")"
    [[ -n "$uuid" ]] || {
        log_warning "No UUID for $src — skipping fstab"
        return 0
    }
    if fstab_has_uuid "$uuid"; then
        return 0
    fi
    fstab_add "UUID=${uuid}  ${BACKUP_MOUNT}  ${fstype}  ${opts}  0  0" \
        "# hyprgruv: backup disk (nofail — missing disk must not block boot)"
}

write_btrbk_conf() {
    sudo mkdir -p /etc/btrbk
    [[ -f "$BTRBK_CONF" ]] && backup_file "$BTRBK_CONF"
    sudo mkdir -p "${BTRFS_ROOT_MNT}/btrbk_snapshots" "${BACKUP_MOUNT}/btrbk"
    sudo tee "$BTRBK_CONF" >/dev/null <<EOF
# Generated by hyprgruv lib/scripts/snapshots.sh
timestamp_format            long
transaction_log             /var/log/btrbk.log
snapshot_preserve_min       6h
snapshot_preserve           24h 7d
target_preserve_min         24h
target_preserve             24h 7d 4w
incremental                 yes

volume ${BTRFS_ROOT_MNT}
  snapshot_dir              btrbk_snapshots
  target send-receive       ${BACKUP_MOUNT}/btrbk
  subvolume @
  subvolume @home
EOF
    log_success "Wrote $BTRBK_CONF"
}

pick_timer_calendar() {
    local choice="${SNAPSHOTS_TIMER:-}"
    if [[ -z "$choice" ]] && ! is_noninteractive; then
        choice="$(pick "Off-disk replica frequency:" \
            "Daily (recommended)" \
            "Hourly" \
            "Weekly" \
            "Timer off (pacman hook only)")" || choice="Daily (recommended)"
    fi
    case "${choice,,}" in
        hourly) echo "hourly" ;;
        weekly) echo "weekly" ;;
        *"timer off"* | off | none) echo "off" ;;
        *) echo "daily" ;;
    esac
}

want_pacman_hook() {
    case "${SNAPSHOTS_HOOK:-}" in
        0 | no | false) return 1 ;;
        1 | yes | true) return 0 ;;
    esac
    if is_noninteractive; then
        return 0
    fi
    confirm "Also run the replica after every package upgrade (pacman hook)?"
}

install_btrbk_units() {
    local calendar="$1"
    install_template \
        "$SNAP_TEMPLATES/hyprgruv-btrbk.service" \
        /etc/systemd/system/hyprgruv-btrbk.service \
        __BACKUP_MOUNT__ "$BACKUP_MOUNT" \
        __BTRFS_ROOT__ "$BTRFS_ROOT_MNT"
    if [[ "$calendar" != "off" ]]; then
        install_template \
            "$SNAP_TEMPLATES/hyprgruv-btrbk.timer" \
            /etc/systemd/system/hyprgruv-btrbk.timer \
            __ON_CALENDAR__ "$calendar"
        sudo systemctl daemon-reload
        sudo systemctl enable --now "hyprgruv-btrbk.timer"
        log_success "Enabled hyprgruv-btrbk.timer ($calendar)"
    else
        sudo systemctl daemon-reload
        log_status "No btrbk timer (hook-only or manual)"
    fi
    if want_pacman_hook; then
        sudo mkdir -p /etc/pacman.d/hooks
        sudo cp -a "$SNAP_TEMPLATES/hyprgruv-btrbk.hook" /etc/pacman.d/hooks/zz-hyprgruv-btrbk.hook
        log_success "Installed pacman hook zz-hyprgruv-btrbk.hook"
    fi
}

install_rsync_units() {
    local calendar="$1"
    install_template \
        "$SNAP_TEMPLATES/hyprgruv-rsync-backup.service" \
        /etc/systemd/system/hyprgruv-rsync-backup.service \
        __BACKUP_MOUNT__ "$BACKUP_MOUNT"
    if [[ "$calendar" != "off" ]]; then
        # Reuse btrbk timer shape with a different unit name
        install_template \
            "$SNAP_TEMPLATES/hyprgruv-btrbk.timer" \
            /etc/systemd/system/hyprgruv-rsync-backup.timer \
            __ON_CALENDAR__ "$calendar"
        sudo sed -i 's/hyprgruv btrbk off-disk replica/Hyprgruv rsync backup/' \
            /etc/systemd/system/hyprgruv-rsync-backup.timer
        sudo systemctl daemon-reload
        sudo systemctl enable --now hyprgruv-rsync-backup.timer
        log_success "Enabled hyprgruv-rsync-backup.timer ($calendar)"
    else
        sudo systemctl daemon-reload
    fi
}

setup_layer2() {
    local dev
    dev="$(choose_backup_disk)" || {
        log_status "No backup disk selected"
        return 0
    }
    [[ "$dev" == /dev/* ]] || dev="/dev/${dev#/dev/}"
    prepare_backup_disk "$dev" || {
        log_warning "Could not prepare $dev — skipping off-disk replica"
        return 0
    }

    local tgt_fstype
    tgt_fstype="$(findmnt -no FSTYPE "$BACKUP_MOUNT" 2>/dev/null || true)"
    local calendar
    calendar="$(pick_timer_calendar)"

    if root_is_btrfs && [[ "$tgt_fstype" == "btrfs" ]]; then
        install_pkg btrbk
        ensure_btrfs_toplevel
        write_btrbk_conf
        install_btrbk_units "$calendar"
        LAYER2=1
        LAYER2_KIND="btrbk"
        if ! is_noninteractive && confirm "Run the first btrbk send now? (can take a while on first copy of @home)"; then
            sudo btrbk -c "$BTRBK_CONF" run || log_warning "btrbk run finished with errors"
        else
            log_status "Later: sudo btrbk -c $BTRBK_CONF run"
        fi
    else
        log_status "Using rsync replica (root=${ROOT_FSTYPE}, target=${tgt_fstype:-unknown})"
        install_rsync_units "$calendar"
        LAYER2=1
        LAYER2_KIND="rsync"
        if ! is_noninteractive && confirm "Run the first rsync now?"; then
            sudo systemctl start hyprgruv-rsync-backup.service || log_warning "rsync backup failed"
        else
            log_status "Later: sudo systemctl start hyprgruv-rsync-backup.service"
        fi
    fi
}

setup_layer3() {
    [[ "$LAYER2" -eq 1 ]] || {
        log_status "NAS replica skipped (no off-disk layer)"
        return 0
    }
    want_layer3 || {
        log_status "NAS replica skipped"
        return 0
    }
    if ! is_noninteractive; then
        NAS_DEST="$(ask_text "NAS destination:" "$NAS_DEST")"
    fi
    local nas_mnt
    nas_mnt="$(nas_mount_from_dest "$NAS_DEST")"
    [[ -n "$nas_mnt" ]] || nas_mnt="/mnt/nas"

    local btrbk_target="${BACKUP_MOUNT}/btrbk"
    [[ "$LAYER2_KIND" == "rsync" ]] && btrbk_target="${BACKUP_MOUNT}/rsync-root"

    install_template \
        "$SNAP_TEMPLATES/hyprgruv-nas-replica.service" \
        /etc/systemd/system/hyprgruv-nas-replica.service \
        __BACKUP_MOUNT__ "$BACKUP_MOUNT" \
        __NAS_MOUNT__ "$nas_mnt" \
        __NAS_DEST__ "$NAS_DEST" \
        __BTRBK_TARGET__ "$btrbk_target"
    sudo cp -a "$SNAP_TEMPLATES/hyprgruv-nas-replica.timer" \
        /etc/systemd/system/hyprgruv-nas-replica.timer
    sudo systemctl daemon-reload
    sudo systemctl enable --now hyprgruv-nas-replica.timer
    LAYER3=1
    log_success "Weekly NAS replica → $NAS_DEST (no-ops unless ${nas_mnt} is mounted)"
}

print_summary() {
    echo ""
    log_success "Snapshot setup complete"
    echo ""
    echo "  Layer 1 (local)     : $([[ $LAYER1 -eq 1 ]] && echo enabled || echo skipped)"
    echo "  Layer 2 (off-disk)  : $([[ $LAYER2 -eq 1 ]] && echo "enabled ($LAYER2_KIND → $BACKUP_MOUNT)" || echo skipped)"
    echo "  Layer 3 (NAS)       : $([[ $LAYER3 -eq 1 ]] && echo "enabled → $NAS_DEST" || echo skipped)"
    echo "  Root filesystem     : $ROOT_FSTYPE"
    echo "  LUKS                : $([[ $ROOT_LUKS -eq 1 ]] && echo yes || echo no)"
    echo ""
    echo "Restore:"
    if [[ $LAYER1 -eq 1 ]] && root_is_btrfs; then
        echo "  • GRUB → snapshot submenu → pick a Timeshift snapshot"
        echo "    (on LUKS, unlock first as usual; snapshot entries keep rd.luks / cryptdevice)"
        echo "  • or: sudo timeshift --restore"
    elif [[ $LAYER1 -eq 1 ]]; then
        echo "  • sudo timeshift --restore"
    fi
    if [[ "$LAYER2_KIND" == "btrbk" ]]; then
        echo "  • Off-disk: sudo btrbk -c $BTRBK_CONF list"
        echo "  • Manual send: sudo btrbk -c $BTRBK_CONF run"
    elif [[ "$LAYER2_KIND" == "rsync" ]]; then
        echo "  • Off-disk tree: $BACKUP_MOUNT/rsync-root"
    fi
    echo "  • Re-run this wizard: bash ~/.hyprgruv/lib/scripts/snapshots.sh"
    echo "    or Settings → System → Snapshots"
    echo ""
}

# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------
ensure_cmd gum "Installing gum…" gum

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true
gum_apply_matugen_theme 2>/dev/null || true

if [[ "${HYPRGRUV_FROM_CONFIG:-0}" != "1" ]]; then
    display_header "Snapshots"
fi

if [[ "${SNAPSHOTS_SETUP:-}" == "skip" ]]; then
    log_status "SNAPSHOTS_SETUP=skip — nothing to do"
    exit 0
fi

detect_root
detect_luks
print_detection

echo "Three optional layers (Yes/No for each next — this is not a 1-3 menu):"
echo "  • Local Timeshift snapshots (same disk, instant rollback"
if root_is_btrfs; then
    echo "     + GRUB menu via grub-btrfs --timeshift-auto)"
else
    echo "     — rsync mode on ${ROOT_FSTYPE}, no GRUB snapshot menu)"
fi
echo "  • Extra-disk replica on a separate drive (btrfs send/receive, or rsync)"
echo "  • Weekly copy of that replica to a NAS mount"
echo ""
if [[ "$ROOT_LUKS" -eq 1 ]]; then
    log_warning "Root is encrypted. Local snapshots stay inside the unlocked volume."
    log_warning "A plaintext extra disk would hold an unlocked copy — you will be asked before formatting."
    echo ""
fi

if grub_btrfsd_healthy && [[ -f "$TIMESHIFT_JSON" ]] && ! is_noninteractive; then
    log_status "Timeshift + grub-btrfsd (--timeshift-auto) already look configured."
    existing="$(pick "Existing snapshot stack:" \
        "Reconfigure everything" \
        "Add or change off-disk / NAS replica only" \
        "Skip")" || existing="Skip"
    case "$existing" in
        "Add or change off-disk / NAS replica only")
            LAYER1=1
            if want_layer2; then
                setup_layer2
            fi
            setup_layer3
            write_snap_env
            print_summary
            exit 0
            ;;
        Skip)
            log_status "Snapshot setup skipped"
            exit 0
            ;;
    esac
fi

if want_layer1; then
    if root_is_btrfs; then
        setup_layer1_btrfs
    else
        setup_layer1_rsync
    fi
else
    log_status "Local Timeshift setup skipped"
fi

if want_layer2; then
    setup_layer2
else
    log_status "Off-disk replica skipped"
fi

if [[ "$LAYER2" -eq 1 ]]; then
    setup_layer3
fi

write_snap_env
print_summary
exit 0
