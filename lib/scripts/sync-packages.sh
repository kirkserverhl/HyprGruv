#!/usr/bin/env bash
# sync-packages.sh — package manifest management + cross-device install sync
#
# Subcommands:
#   add <pkg> [pkg...] [--pacman|--aur|--new] [--install]
#   promote <pkg> --to pacman|aur
#   list
#   sync [options]   (default when no subcommand is given)
#
# Sync installs with --needed --noconfirm:
#   Official repos: sudo pacman -S
#   AUR:            yay -S
#   NEW section:    auto-routed to pacman or yay

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
MANIFEST="$HYPR_DIR/lib/packages/manifest.sh"
MANIFEST_LIB="$HYPR_DIR/lib/packages/manifest-lib.sh"

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$MANIFEST_LIB" ]] || { echo "[ERROR] Missing: $MANIFEST_LIB"; exit 1; }
source "$MANIFEST_LIB"

usage() {
    cat <<'EOF'
Hyprgruv package sync — manifest lists in lib/packages/*.list

Subcommands:
  add <pkg> [pkg...]     Add to staging (new.list) by default
    --pacman             Add to pacman.list instead
    --aur                Add to aur.list instead
    --new                Add to new.list (default)
    --install            Run sync after adding (staging only unless section set)

  promote <pkg> --to <pacman|aur>
                         Move a package from new → confirmed section

  list                   Show package counts per section

  sync [options]         Install missing packages (default)

Sync options:
  --dry-run              Preview installs only
  --new-only             Install only new.list
  --skip-new             Skip new.list
  --include-gpu          Include GPU driver packages
  --include-vm           Include VM guest packages
  --help                 Show this help

Examples:
  ~/.hyprgruv/sync-packages.sh add helix --install
  ~/.hyprgruv/sync-packages.sh add brave-bin --aur
  ~/.hyprgruv/sync-packages.sh promote helix --to pacman
  ~/.hyprgruv/sync-packages.sh --dry-run
EOF
}

cmd_add() {
    local section=new install_after=0
    local -a pkgs=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
        --pacman | --official) section=pacman ;;
        --aur | --yay) section=aur ;;
        --new | --staging) section=new ;;
        --install) install_after=1 ;;
        --help | -h)
            usage
            return 0
            ;;
        -*)
            echo "[ERROR] Unknown add option: $1" >&2
            return 1
            ;;
        *)
            pkgs+=("$1")
            ;;
        esac
        shift
    done

    if ((${#pkgs[@]} == 0)); then
        echo "[ERROR] Usage: sync-packages.sh add <package> [package...]" >&2
        return 1
    fi

    manifest_add_package "$section" "${pkgs[@]}"
    manifest_summary
    echo ""
    echo "Commit and push from your desktop, then pull on the laptop to deploy."

    if [[ $install_after -eq 1 ]]; then
        echo ""
        if [[ "$section" == new ]]; then
            exec bash "${BASH_SOURCE[0]}" --new-only
        else
            exec bash "${BASH_SOURCE[0]}"
        fi
    fi
}

cmd_promote() {
    local pkg="" dest=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
        --to)
            dest="${2:-}"
            shift
            ;;
        --help | -h)
            usage
            return 0
            ;;
        -*)
            echo "[ERROR] Unknown promote option: $1" >&2
            return 1
            ;;
        *)
            [[ -z "$pkg" ]] && pkg="$1" || {
                echo "[ERROR] Only one package per promote" >&2
                return 1
            }
            ;;
        esac
        shift
    done

    [[ -n "$pkg" && -n "$dest" ]] || {
        echo "[ERROR] Usage: sync-packages.sh promote <pkg> --to pacman|aur" >&2
        return 1
    }

    manifest_promote_package "$pkg" "$dest"
    manifest_summary
}

cmd_list() {
    manifest_summary
    echo ""
    for section in pacman aur new; do
        local file
        file="$(manifest_list_file "$section")"
        echo "── $section ──"
        manifest_read_list "$file" | sed 's/^/  /'
        echo ""
    done
}

# Route subcommands before sync option parsing
SUBCMD="${1:-sync}"
case "$SUBCMD" in
add)
    shift
    cmd_add "$@"
    exit $?
    ;;
promote)
    shift
    cmd_promote "$@"
    exit $?
    ;;
list)
    shift
    cmd_list
    exit 0
    ;;
sync)
    shift
    ;;
--help | -h)
    usage
    exit 0
    ;;
--*)
    SUBCMD=sync
    ;;
*)
    SUBCMD=sync
    ;;
esac

# shellcheck source=/dev/null
[[ -f "$MANIFEST" ]] || { echo "[ERROR] Missing manifest: $MANIFEST"; exit 1; }
source "$MANIFEST"

# Defaults
DRY_RUN=0
NEW_ONLY=0
SKIP_NEW=0
INCLUDE_GPU=0
INCLUDE_VM=0

while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --new-only) NEW_ONLY=1 ;;
    --skip-new) SKIP_NEW=1 ;;
    --include-gpu) INCLUDE_GPU=1 ;;
    --include-vm) INCLUDE_VM=1 ;;
    --help | -h)
        usage
        exit 0
        ;;
    *)
        echo "[ERROR] Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
done

say() { echo -e "$*"; }

run_cmd() {
    if [[ $DRY_RUN -eq 1 ]]; then
        local joined=""
        for arg in "$@"; do joined+="$arg "; done
        say "  [dry-run] ${joined% }"
        return 0
    fi
    "$@"
}

repo_has() {
    pacman -Si "$1" &>/dev/null
}

pkg_installed() {
    pacman -Qq "$1" &>/dev/null
}

dedupe_sorted() {
    printf '%s\n' "$@" | awk 'NF && !seen[$0]++' | sort -u
}

ensure_yay() {
    command -v yay &>/dev/null && return 0
    log_status "yay not found — installing AUR helper…"
    run_cmd sudo pacman -S --needed --noconfirm git base-devel
    local tmpdir
    tmpdir="$(mktemp -d)"
    (
        cd "$tmpdir"
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
    )
    rm -rf "$tmpdir"
    command -v yay &>/dev/null || {
        log_error "yay installation failed"
        return 1
    }
    log_success "yay is available"
}

gpu_pacman_pkgs() {
    local vendor="${1:-generic}"
    case "$vendor" in
    amd)
        printf '%s\n' mesa vulkan-radeon libva-mesa-driver
        repo_has lib32-mesa && printf '%s\n' lib32-mesa lib32-vulkan-radeon
        ;;
    intel)
        printf '%s\n' mesa vulkan-intel libva-intel-driver
        repo_has lib32-mesa && printf '%s\n' lib32-mesa lib32-vulkan-intel
        ;;
    nvidia)
        printf '%s\n' nvidia nvidia-utils
        repo_has lib32-nvidia-utils && printf '%s\n' lib32-nvidia-utils
        ;;
    *)
        printf '%s\n' mesa
        repo_has lib32-mesa && printf '%s\n' lib32-mesa
        ;;
    esac
}

detect_gpu_vendor() {
    if lspci 2>/dev/null | grep -iE ' vga|3d|display' | grep -qi nvidia; then
        echo nvidia
    elif lspci 2>/dev/null | grep -iE ' vga|3d|display' | grep -qi amd; then
        echo amd
    elif lspci 2>/dev/null | grep -iE ' vga|3d|display' | grep -qi intel; then
        echo intel
    else
        echo generic
    fi
}

vm_guest_pkgs() {
    if declare -F detect_vm &>/dev/null; then
        detect_vm
    fi
    if [[ "${IS_VM:-false}" != "true" && $INCLUDE_VM -eq 0 ]]; then
        return 0
    fi
    local hv="${HYPERVISOR:-generic-vm}"
    case "$hv" in
    virtualbox) printf '%s\n' virtualbox-guest-utils ;;
    vmware) printf '%s\n' open-vm-tools ;;
    qemu | kvm | generic-vm) printf '%s\n' qemu-guest-agent spice-vdagent ;;
    hyperv) printf '%s\n' hyperv ;;
    *) printf '%s\n' qemu-guest-agent ;;
    esac
}

split_new_pkgs() {
    local pkg official=() aur=()
    for pkg in "${NEW_PKGS[@]}"; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
        if repo_has "$pkg"; then
            official+=("$pkg")
        else
            aur+=("$pkg")
        fi
    done
    NEW_OFFICIAL=("${official[@]}")
    NEW_AUR=("${aur[@]}")
}

install_pacman_batch() {
    local -a pkgs=("$@")
    ((${#pkgs[@]})) || return 0

    local missing=()
    for pkg in "${pkgs[@]}"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done

    if ((${#missing[@]} == 0)); then
        log_success "All ${#pkgs[@]} official package(s) already installed"
        return 0
    fi

    log_status "Installing ${#missing[@]} official package(s) via pacman…"
    if run_cmd sudo pacman -S --needed --noconfirm "${missing[@]}"; then
        log_success "Official packages synced"
        return 0
    fi
    log_warning "Batch pacman install had issues — retrying one-by-one…"
    local pkg failed=()
    for pkg in "${missing[@]}"; do
        if run_cmd sudo pacman -S --needed --noconfirm "$pkg"; then
            say "  ✓ $pkg"
        else
            failed+=("$pkg")
            log_warning "Failed: $pkg"
        fi
    done
    ((${#failed[@]})) && return 1
    return 0
}

install_aur_one_by_one() {
    local -a pkgs=("$@")
    ((${#pkgs[@]})) || return 0

    ensure_yay || return 1

    local pkg failed=() skipped=0
    log_status "Installing ${#pkgs[@]} AUR package(s) via yay…"
    for pkg in "${pkgs[@]}"; do
        if pkg_installed "$pkg"; then
            ((skipped++)) || true
            continue
        fi
        if run_cmd yay -S --needed --noconfirm "$pkg"; then
            say "  ✓ $pkg"
        else
            failed+=("$pkg")
            log_warning "AUR package failed: $pkg"
        fi
    done

    if ((${#failed[@]})); then
        log_warning "${#failed[@]} AUR package(s) failed: ${failed[*]}"
        return 1
    fi
    if [[ $skipped -eq ${#pkgs[@]} ]]; then
        log_success "All AUR packages already installed"
    else
        log_success "AUR packages synced"
    fi
    return 0
}

# --- Build install lists ---
PACMAN_INSTALL=()
AUR_INSTALL=()

if [[ $NEW_ONLY -eq 0 ]]; then
    mapfile -t PACMAN_INSTALL < <(dedupe_sorted "${PACMAN_PKGS[@]}")
    mapfile -t AUR_INSTALL < <(dedupe_sorted "${AUR_PKGS[@]}")
fi

if [[ $SKIP_NEW -eq 0 && ${#NEW_PKGS[@]} -gt 0 ]]; then
    split_new_pkgs
    if ((${#NEW_OFFICIAL[@]})); then
        mapfile -t _merged < <(dedupe_sorted "${PACMAN_INSTALL[@]}" "${NEW_OFFICIAL[@]}")
        PACMAN_INSTALL=("${_merged[@]}")
    fi
    if ((${#NEW_AUR[@]})); then
        mapfile -t _merged < <(dedupe_sorted "${AUR_INSTALL[@]}" "${NEW_AUR[@]}")
        AUR_INSTALL=("${_merged[@]}")
    fi
elif [[ $NEW_ONLY -eq 1 ]]; then
    split_new_pkgs
    PACMAN_INSTALL=("${NEW_OFFICIAL[@]}")
    AUR_INSTALL=("${NEW_AUR[@]}")
fi

if [[ $INCLUDE_GPU -eq 1 ]]; then
    vendor="$(detect_gpu_vendor)"
    log_status "Including GPU packages for: $vendor"
    mapfile -t _gpu < <(gpu_pacman_pkgs "$vendor")
    mapfile -t PACMAN_INSTALL < <(dedupe_sorted "${PACMAN_INSTALL[@]}" "${_gpu[@]}")
fi

mapfile -t _vm < <(vm_guest_pkgs)
if ((${#_vm[@]})); then
    log_status "Including VM guest packages: ${_vm[*]}"
    mapfile -t PACMAN_INSTALL < <(dedupe_sorted "${PACMAN_INSTALL[@]}" "${_vm[@]}")
fi

# --- Run ---
display_header "Package Sync" 2>/dev/null || say ""
say "Manifest: $MANIFEST"
say "Official: ${#PACMAN_INSTALL[@]}  |  AUR: ${#AUR_INSTALL[@]}  |  New (staging): ${#NEW_PKGS[@]}"
[[ $DRY_RUN -eq 1 ]] && log_warning "Dry-run mode — no packages will be installed"
say ""

if [[ $DRY_RUN -eq 0 ]]; then
    log_status "Refreshing package databases…"
    sudo pacman -Sy --noconfirm || log_warning "pacman -Sy reported issues (continuing)"
fi

pacman_ok=0
aur_ok=0

if ((${#PACMAN_INSTALL[@]})); then
    install_pacman_batch "${PACMAN_INSTALL[@]}" && pacman_ok=1 || pacman_ok=0
else
    pacman_ok=1
    log_status "No official packages to install"
fi

if ((${#AUR_INSTALL[@]})); then
    install_aur_one_by_one "${AUR_INSTALL[@]}" && aur_ok=1 || aur_ok=0
else
    aur_ok=1
    log_status "No AUR packages to install"
fi

say ""
if [[ $pacman_ok -eq 1 && $aur_ok -eq 1 ]]; then
    log_success "Package sync complete"
    exit 0
fi

log_warning "Package sync finished with some failures — review output above"
exit 1