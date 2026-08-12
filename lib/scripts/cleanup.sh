#!/usr/bin/env bash
# cleanup.sh — safe system cleanup (pacman / AUR cache, optional extras)
#
# Default is cache-only (no package removals). Designed for:
#   • Interactive terminal (gum confirm + sudo password on TTY)
#   • Installer / reminder launch (works without silent sudo failures)
#
# Never runs pacman/yay -Sc or -Scc (interactive + breaks on download-* dirs).
# System cache: paccache -rk2 / -ruk0 + rm download-* leftovers.
# User AUR cache: ~/.cache/yay or ~/.cache/paru only.
#
# Usage:
#   cleanup.sh                 # confirm, then clean caches
#   cleanup.sh --yes           # skip confirm
#   cleanup.sh --orphans       # also offer to remove pacman orphans
#   cleanup.sh --journal       # also vacuum journald (needs sudo)
#   cleanup.sh --dry-run       # show planned steps only
#
# Palette: common.sh → gruvbox default / matugen if present (gum + toilet graffiti)

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HYPR_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

YES=0
ORPHANS=0
JOURNAL=0
DRY_RUN=0

usage() {
    cat <<'EOF'
cleanup.sh — safe system cleanup

  cleanup.sh              Confirm, then clean package caches
  cleanup.sh --yes        Skip confirmation
  cleanup.sh --orphans    Also prompt to remove orphan packages
  cleanup.sh --journal    Also vacuum journald logs (sudo)
  cleanup.sh --dry-run    Print steps only
  -h, --help              This help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --yes | -y) YES=1; shift ;;
    --orphans) ORPHANS=1; shift ;;
    --journal) JOURNAL=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
done

# Resolve AUR helper (aur.sh may contain "yay" / "paru")
resolve_aur_helper() {
    local aur_script helper=""
    for aur_script in \
        "${REPO_DOTFILES_SCRIPTS:-$HYPR_DIR/home/.config/hyprgruv/scripts}/aur.sh" \
        "${DOTFILES_SCRIPTS:-$HOME/.config/hyprgruv/scripts}/aur.sh" \
        "$HOME/.config/hyprgruv/scripts/aur.sh"
    do
        if [[ -f "$aur_script" ]]; then
            helper="$(tr -d '[:space:]' <"$aur_script")"
            break
        fi
    done
    [[ -z "$helper" ]] && helper="yay"
    printf '%s\n' "$helper"
}

AUR_HELPER="$(resolve_aur_helper)"
FAILURES=0
DID_ANY=0

run_step() {
    local label="$1"
    shift
    log_status "$label"
    if [[ $DRY_RUN -eq 1 ]]; then
        local pretty=""
        local a
        for a in "$@"; do pretty+="$a "; done
        log_status "[dry-run] $pretty"
        return 0
    fi
    if "$@"; then
        log_success "  ok"
        DID_ANY=1
        return 0
    fi
    log_warning "  failed (continuing)"
    FAILURES=$((FAILURES + 1))
    return 0
}

has_sudo_tty() {
    # Need a real TTY for password prompts (fixes: sudo: a terminal is required…)
    [[ -e /dev/tty ]] && { : </dev/tty; } 2>/dev/null
}

sudo_cmd() {
    if has_sudo_tty; then
        sudo "$@" </dev/tty
    else
        # Non-interactive / no TTY — try passwordless, else skip
        if sudo -n true 2>/dev/null; then
            sudo -n "$@"
        else
            return 2
        fi
    fi
}

bytes_human() {
    local b="${1:-0}"
    # Guard non-numeric / empty (e.g. arithmetic fell through)
    [[ "$b" =~ ^-?[0-9]+$ ]] || b=0
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec --suffix=B "$b" 2>/dev/null || echo "${b}B"
    else
        echo "${b}B"
    fi
}

dir_size() {
    local d="$1" size=""
    [[ -d "$d" ]] || {
        echo 0
        return 0
    }
    # du exits non-zero when some subdirs are unreadable (common in ~/.cache/yay
    # after root-owned makepkg trees). With set -o pipefail that would abort the
    # whole script — capture size best-effort and always succeed.
    size="$(du -sb "$d" 2>/dev/null | awk '{print $1}' || true)"
    [[ "$size" =~ ^[0-9]+$ ]] || size=0
    printf '%s\n' "$size"
    return 0
}

# ── UI ───────────────────────────────────────────────────────────────────────
clear 2>/dev/null || true
display_header "Cleanup"

if declare -F gum_apply_matugen_theme >/dev/null 2>&1; then
    gum_apply_matugen_theme 2>/dev/null || true
fi

if [[ $YES -eq 0 && $DRY_RUN -eq 0 ]]; then
    if declare -F gum_confirm_prompt >/dev/null 2>&1; then
        if ! gum_confirm_prompt "Perform system cleanup (caches only)?"; then
            log_status "Cleanup cancelled"
            exit 0
        fi
    else
        read -rp "Perform system cleanup (caches only)? [y/N] " ans || true
        [[ "${ans:-}" =~ ^[Yy] ]] || {
            log_status "Cleanup cancelled"
            exit 0
        }
    fi
fi

echo ""
log_status "AUR helper: $AUR_HELPER"
[[ $DRY_RUN -eq 1 ]] && log_status "Dry run — no changes"

# ── 1) User-owned AUR helper cache (no sudo) ─────────────────────────────────
AUR_CACHE=""
case "$AUR_HELPER" in
yay) AUR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/yay" ;;
paru) AUR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/paru" ;;
*) AUR_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/$AUR_HELPER" ;;
esac

if [[ -d "$AUR_CACHE" ]]; then
    before="$(dir_size "$AUR_CACHE")"
    log_status "Cleaning user $AUR_HELPER cache ($(bytes_human "$before")) → $AUR_CACHE"
    if [[ $DRY_RUN -eq 0 ]]; then
        # Remove package build trees; keep the cache root.
        # User-owned entries first; root-owned leftovers need sudo (optional).
        find "$AUR_CACHE" -mindepth 1 -maxdepth 1 -user "$(id -u)" -exec rm -rf {} + 2>/dev/null || true
        find "$AUR_CACHE" -mindepth 1 -maxdepth 1 ! -user "$(id -u)" -exec rm -rf {} + 2>/dev/null || true
        # Still something left (root-owned dirs common after yay as root once)?
        leftovers="$(find "$AUR_CACHE" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "${leftovers:-0}" -gt 0 ]] && has_sudo_tty; then
            log_status "  removing $leftovers leftover entr$( [[ $leftovers -eq 1 ]] && echo y || echo ies ) (may need sudo)…"
            sudo_cmd find "$AUR_CACHE" -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
        elif [[ "${leftovers:-0}" -gt 0 ]]; then
            log_warning "  $leftovers entr$( [[ $leftovers -eq 1 ]] && echo y || echo ies ) left (root-owned? re-run in a terminal with sudo)"
        fi
        after="$(dir_size "$AUR_CACHE")"
        freed=$((before - after))
        [[ $freed -lt 0 ]] && freed=0
        log_success "  freed ~$(bytes_human "$freed")"
        DID_ANY=1
    else
        log_status "[dry-run] would clear $AUR_CACHE"
    fi
else
    log_status "No user $AUR_HELPER cache at $AUR_CACHE"
fi

# ── 2) System pacman cache — NEVER use pacman/yay -Sc/-Scc ───────────────────
# -Sc/-Scc prompts interactively and fails on leftover download-* directories.
# Use paccache (pacman-contrib) + explicit rm of partial download dirs instead.
PKG_CACHE="/var/cache/pacman/pkg"

clean_pacman_pkg_cache() {
    # Returns: 0 ok, 2 no sudo, 1 other failure
    if ! command -v paccache >/dev/null 2>&1; then
        log_warning "paccache not found (install pacman-contrib) — skipped $PKG_CACHE"
        return 1
    fi

    log_status "Cleaning system pacman cache ($PKG_CACHE)…"
    log_status "  keep last 2 versions of installed pkgs; drop uninstalled; remove download-* dirs"

    if [[ $DRY_RUN -eq 1 ]]; then
        paccache -d -k2 2>/dev/null || true
        paccache -d -uk0 2>/dev/null || true
        log_status "[dry-run] sudo paccache -rk2 && sudo paccache -ruk0"
        log_status "[dry-run] sudo find $PKG_CACHE -maxdepth 1 -type d -name 'download-*' -exec rm -rf {} +"
        return 0
    fi

    # Capture rc before any other command — `if ! cmd; then rc=$?` is always 0
    local rc=0
    sudo_cmd paccache -rk2 || rc=$?
    if [[ $rc -ne 0 ]]; then
        if [[ $rc -eq 2 ]]; then
            log_warning "  skipped — need sudo in a real terminal (or: sudo paccache -rk2)"
            return 2
        fi
        log_warning "  paccache -rk2 failed"
        return 1
    fi

    # Remove cached packages no longer installed
    sudo_cmd paccache -ruk0 2>/dev/null || true

    # Partial/interrupted downloads: pacman -Scc cannot delete these dirs
    if [[ -d "$PKG_CACHE" ]]; then
        local n
        n="$(find "$PKG_CACHE" -mindepth 1 -maxdepth 1 -type d -name 'download-*' 2>/dev/null | wc -l | tr -d ' ')"
        if [[ "${n:-0}" -gt 0 ]]; then
            log_status "  removing $n stuck download-* director$( [[ $n -eq 1 ]] && echo y || echo ies )…"
            if sudo_cmd find "$PKG_CACHE" -mindepth 1 -maxdepth 1 -type d -name 'download-*' -exec rm -rf {} +; then
                log_success "  download leftovers removed"
            else
                log_warning "  could not remove some download-* dirs"
                return 1
            fi
        fi
    fi

    log_success "  pacman cache cleaned"
    return 0
}

if clean_pacman_pkg_cache; then
    DID_ANY=1
else
    rc=$?
    [[ $rc -eq 1 ]] && FAILURES=$((FAILURES + 1))
fi

# ── 3) Light user clutter (safe) ─────────────────────────────────────────────
for d in \
    "${XDG_CACHE_HOME:-$HOME/.cache}/thumbnails" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/mesa_shader_cache" \
    "${XDG_CACHE_HOME:-$HOME/.cache}/mpv/shaders/cache"
do
    if [[ -d "$d" ]]; then
        run_step "Cleaning $(basename "$(dirname "$d")")/$(basename "$d")…" \
            bash -c "rm -rf \"$d\"/* 2>/dev/null || true"
    fi
done

# ── 4) Optional: journal vacuum ──────────────────────────────────────────────
if [[ $JOURNAL -eq 1 ]]; then
    log_status "Vacuuming journald (keep 14 days)…"
    if [[ $DRY_RUN -eq 1 ]]; then
        log_status "[dry-run] journalctl --vacuum-time=14d"
    else
        if sudo_cmd journalctl --vacuum-time=14d; then
            log_success "  journal trimmed"
            DID_ANY=1
        else
            log_warning "  journal vacuum skipped/failed"
            FAILURES=$((FAILURES + 1))
        fi
    fi
fi

# ── 5) Optional: orphans ─────────────────────────────────────────────────────
if [[ $ORPHANS -eq 1 ]]; then
    mapfile -t orphan_pkgs < <(pacman -Qdtq 2>/dev/null || true)
    if ((${#orphan_pkgs[@]})); then
        log_status "Orphans (${#orphan_pkgs[@]}): ${orphan_pkgs[*]}"
        do_rm=0
        if [[ $DRY_RUN -eq 1 ]]; then
            log_status "[dry-run] would: sudo pacman -Rns ${orphan_pkgs[*]}"
        elif [[ $YES -eq 1 ]]; then
            do_rm=1
        elif declare -F gum_confirm_prompt >/dev/null 2>&1; then
            gum_confirm_prompt "Remove ${#orphan_pkgs[@]} orphan package(s)?" && do_rm=1 || true
        else
            read -rp "Remove orphans? [y/N] " ans || true
            [[ "${ans:-}" =~ ^[Yy] ]] && do_rm=1
        fi
        if [[ $do_rm -eq 1 && $DRY_RUN -eq 0 ]]; then
            if sudo_cmd pacman -Rns --noconfirm "${orphan_pkgs[@]}"; then
                log_success "  orphans removed"
                DID_ANY=1
            else
                log_warning "  orphan removal failed"
                FAILURES=$((FAILURES + 1))
            fi
        fi
    else
        log_status "No orphan packages"
    fi
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
bash "$HYPR_DIR/lib/scripts/system-maintain-remind.sh" --clear 2>/dev/null || true

if [[ $FAILURES -gt 0 ]]; then
    log_warning "Cleanup finished with $FAILURES warning(s)"
elif [[ $DID_ANY -eq 1 || $DRY_RUN -eq 1 ]]; then
    log_success "Cleanup complete"
else
    log_status "Nothing cleaned (already tidy, or privileged steps skipped)"
fi

echo ""
if command -v duf >/dev/null 2>&1; then
    # Local disks only — hide tmpfs/dev clutter that looked like noise
    duf --only local --theme ansi 2>/dev/null || duf --only local 2>/dev/null || duf
else
    df -hT | head -20
fi

echo ""
if [[ -t 0 && $DRY_RUN -eq 0 ]]; then
    read -rp "Press Enter to exit…" _ || true
fi

if command -v nerdfetch >/dev/null 2>&1 && [[ -t 1 ]]; then
    nerdfetch 2>/dev/null || true
fi

exit 0
