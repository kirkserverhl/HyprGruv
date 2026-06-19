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
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
LOG_DIR="$STATE_DIR/logs"
PIDFILE="$STATE_DIR/sync-packages.pid"
mkdir -p "$LOG_DIR"

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
  --yes, -y              Skip confirmation prompt
  --foreground           Run installs in this shell (blocks until done)
  --background           Run installs in background after confirmation
  --help                 Show this help

Interactive sync (default): preview missing packages, confirm, then
install in the background so you can close the terminal. Logs live in
~/.local/state/hyprgruv/logs/

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
YES=0
FOREGROUND=0
BACKGROUND=0
EXECUTE=0
SYNC_ARGS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
    --dry-run) DRY_RUN=1; SYNC_ARGS+=(--dry-run) ;;
    --new-only) NEW_ONLY=1; SYNC_ARGS+=(--new-only) ;;
    --skip-new) SKIP_NEW=1; SYNC_ARGS+=(--skip-new) ;;
    --include-gpu) INCLUDE_GPU=1; SYNC_ARGS+=(--include-gpu) ;;
    --include-vm) INCLUDE_VM=1; SYNC_ARGS+=(--include-vm) ;;
    --yes | -y) YES=1; SYNC_ARGS+=(--yes) ;;
    --foreground) FOREGROUND=1; SYNC_ARGS+=(--foreground) ;;
    --background) BACKGROUND=1; SYNC_ARGS+=(--background) ;;
    --execute) EXECUTE=1 ;;
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

filter_missing_pkgs() {
    local pkg missing=()
    for pkg in "$@"; do
        pkg_installed "$pkg" || missing+=("$pkg")
    done
    printf '%s\n' "${missing[@]}"
}

confirm_sync() {
    local prompt="$1"
    if command -v gum &>/dev/null; then
        declare -F gum_apply_matugen_theme &>/dev/null && gum_apply_matugen_theme
        gum confirm "$prompt"
        return $?
    fi
    local ans
    read -rp "$prompt [y/N]: " ans
    [[ "$ans" =~ ^[Yy]$ ]]
}

want_background() {
    [[ $BACKGROUND -eq 1 ]] && return 0
    [[ $FOREGROUND -eq 1 ]] && return 1
    [[ -t 0 && -t 1 ]]
}

sync_already_running() {
    local pid
    [[ -f "$PIDFILE" ]] || return 1
    pid="$(<"$PIDFILE")"
    kill -0 "$pid" 2>/dev/null
}

prime_sudo_for_background() {
    log_status "Caching sudo credentials for background install…"
    sudo -v || {
        log_error "sudo authentication failed — cannot start background sync"
        return 1
    }
    sudo pacman -Sy --noconfirm || log_warning "pacman -Sy reported issues (continuing)"
}

spawn_background_sync() {
    local logfile pid
    logfile="$LOG_DIR/sync-packages_$(date +%Y%m%d_%H%M%S).log"

    if sync_already_running; then
        log_warning "Package sync already running (PID $(<"$PIDFILE"))"
        log_status "Tail the log: tail -f $LOG_DIR/sync-packages_*.log"
        return 0
    fi

    nohup bash "${BASH_SOURCE[0]}" --execute "${SYNC_ARGS[@]}" >"$logfile" 2>&1 &
    pid=$!
    printf '%s\n' "$pid" >"$PIDFILE"

    log_success "Package sync started in background (PID $pid)"
    say "  Log: $logfile"
    say "  Follow: tail -f $logfile"
    if command -v notify-send &>/dev/null; then
        notify-send -a "Hyprgruv" -i "system-software-update" \
            "Package sync started" \
            "Installing packages in the background. Log: $logfile"
    fi
}

notify_sync_complete() {
    local status="$1" detail="$2"
    if ! command -v notify-send &>/dev/null; then
        return 0
    fi
    if [[ "$status" == ok ]]; then
        notify-send -a "Hyprgruv" -i "emblem-default" \
            "Package sync complete" "$detail"
    else
        notify-send -a "Hyprgruv" -i "dialog-warning" \
            "Package sync finished with issues" "$detail"
    fi
}

show_sync_preview() {
    local pkg
    say "Packages to install:"
    if ((${#PACMAN_MISSING[@]})); then
        say ""
        say "  Official (${#PACMAN_MISSING[@]}):"
        for pkg in "${PACMAN_MISSING[@]}"; do
            say "    • $pkg"
        done
    fi
    if ((${#AUR_MISSING[@]})); then
        say ""
        say "  AUR (${#AUR_MISSING[@]}):"
        for pkg in "${AUR_MISSING[@]}"; do
            say "    • $pkg"
        done
    fi
    say ""
}

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

# --- Preview / confirm / dispatch ---
mapfile -t PACMAN_MISSING < <(filter_missing_pkgs "${PACMAN_INSTALL[@]}")
mapfile -t AUR_MISSING < <(filter_missing_pkgs "${AUR_INSTALL[@]}")

display_header "Package Sync" 2>/dev/null || say ""
say "Manifest: $MANIFEST"
say "Official: ${#PACMAN_INSTALL[@]}  |  AUR: ${#AUR_INSTALL[@]}  |  New (staging): ${#NEW_PKGS[@]}"
say "Missing:  ${#PACMAN_MISSING[@]} official  |  ${#AUR_MISSING[@]} AUR"
[[ $DRY_RUN -eq 1 ]] && log_warning "Dry-run mode — no packages will be installed"
say ""

if [[ $DRY_RUN -eq 1 ]]; then
    show_sync_preview
    if ((${#PACMAN_MISSING[@]} + ${#AUR_MISSING[@]} == 0)); then
        log_success "All manifest packages are already installed"
    else
        log_status "Would install ${#PACMAN_MISSING[@]} official and ${#AUR_MISSING[@]} AUR package(s)"
    fi
    exit 0
fi

if ((${#PACMAN_MISSING[@]} + ${#AUR_MISSING[@]} == 0)); then
    log_success "All manifest packages are already installed"
    exit 0
fi

show_sync_preview

if [[ $EXECUTE -eq 0 ]]; then
    if [[ $YES -eq 0 ]]; then
        if ! confirm_sync "Install ${#PACMAN_MISSING[@]} official and ${#AUR_MISSING[@]} AUR package(s)?"; then
            log_status "Package sync cancelled"
            exit 0
        fi
    fi

    if want_background; then
        prime_sudo_for_background || exit 1
        spawn_background_sync
        exit 0
    fi
fi

# --- Execute installs ---
cleanup_sync_pidfile() {
    rm -f "$PIDFILE"
}

trap cleanup_sync_pidfile EXIT

if [[ $EXECUTE -eq 1 ]]; then
    printf '%s\n' "$$" >"$PIDFILE"
fi

if [[ $EXECUTE -eq 0 ]]; then
    log_status "Refreshing package databases…"
    sudo pacman -Sy --noconfirm || log_warning "pacman -Sy reported issues (continuing)"
fi

pacman_ok=0
aur_ok=0

if ((${#PACMAN_MISSING[@]})); then
    install_pacman_batch "${PACMAN_MISSING[@]}" && pacman_ok=1 || pacman_ok=0
else
    pacman_ok=1
    log_status "No official packages to install"
fi

if ((${#AUR_MISSING[@]})); then
    install_aur_one_by_one "${AUR_MISSING[@]}" && aur_ok=1 || aur_ok=0
else
    aur_ok=1
    log_status "No AUR packages to install"
fi

say ""
if [[ $pacman_ok -eq 1 && $aur_ok -eq 1 ]]; then
    log_success "Package sync complete"
    notify_sync_complete ok "Installed ${#PACMAN_MISSING[@]} official and ${#AUR_MISSING[@]} AUR package(s)."
    exit 0
fi

log_warning "Package sync finished with some failures — review output above"
notify_sync_complete fail "Some packages failed — check ~/.local/state/hyprgruv/logs/"
exit 1