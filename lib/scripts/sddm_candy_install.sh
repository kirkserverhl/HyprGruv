#!/usr/bin/env bash
# sddm_candy_install.sh — install Sugar Candy SDDM theme + hyprgruv config drop-ins
#
# Wallpaper flow (no reinstall needed day-to-day):
#   waypaper post_command → set_wallpaper.sh → update-sddm-wallpaper.sh
#   overwrites /usr/share/sddm/themes/sugar-candy/sddm-wallpaper.png in place.
#   theme.conf Background= always points at that path.
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from lib/scripts/
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"
    exit 1
fi
if [[ ! -f "$HYPR_DIR/lib/state.sh" ]]; then
    echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh"
    exit 1
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

# shellcheck source=/dev/null
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

# ------------------------------------------------------------
# Paths
# ------------------------------------------------------------
ASSET_DIR="$HYPR_DIR/assets/sddm"
THEMES_DIR="/usr/share/sddm/themes"
CONF_DIR="/etc/sddm.conf.d"
THEME_NAME="sugar-candy"
THEME_SRC="$ASSET_DIR/$THEME_NAME"
CONF_SRC="$ASSET_DIR/sddm.conf.d"
CONF_DEST="$CONF_DIR/50-hyprgruv.conf"
UPDATE_SDDM="$HOME/.config/hyprgruv/scripts/update-sddm-wallpaper.sh"
GREETER_SRC="$ASSET_DIR/hyprland-greeter.conf"
GREETER_DEST_DIR="/usr/share/hyprgruv/sddm"
GREETER_DEST="$GREETER_DEST_DIR/hyprland.conf"

display_header "SDDM Theme"

resolve_desktop_user() {
    if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
        printf '%s\n' "$SUDO_USER"
        return 0
    fi
    printf '%s\n' "${USER:-$(id -un)}"
}

DESKTOP_USER="$(resolve_desktop_user)"
DESKTOP_UID="$(id -u "$DESKTOP_USER" 2>/dev/null || id -u)"

ensure_sddm() {
    if pacman -Qq sddm &>/dev/null; then
        return 0
    fi
    log_status "sddm not found — installing…"
    if command -v yay >/dev/null 2>&1; then
        yay -S --needed --noconfirm sddm
    else
        sudo pacman -S --needed --noconfirm sddm
    fi
    pacman -Qq sddm &>/dev/null || {
        log_error "sddm package is not installed"
        return 1
    }
    log_success "sddm installed"
}

ensure_qt6_virtualkeyboard() {
    if pacman -Qq qt6-virtualkeyboard &>/dev/null; then
        return 0
    fi
    log_status "Installing qt6-virtualkeyboard (Sugar Candy on-screen keyboard)…"
    sudo pacman -S --needed --noconfirm qt6-virtualkeyboard
}

apply_qt6_compat() {
    local theme_dir="$1" qml meta
    for qml in "$theme_dir"/Main.qml "$theme_dir"/Components/*.qml; do
        [[ -f "$qml" ]] || continue
        if grep -q 'import QtGraphicalEffects 1.0' "$qml" 2>/dev/null; then
            sudo sed -i 's|import QtGraphicalEffects 1.0|import Qt5Compat.GraphicalEffects|g' "$qml"
            log_status "Patched Qt6 compat in $(basename "$qml")"
        fi
    done

    meta="$theme_dir/metadata.desktop"
    if [[ -f "$meta" ]] && ! grep -q '^QtVersion=6' "$meta" 2>/dev/null; then
        echo 'QtVersion=6' | sudo tee -a "$meta" >/dev/null
        log_status "Set QtVersion=6 in metadata.desktop"
    fi
}

# ------------------------------------------------------------
# Require SDDM + shipped assets
# ------------------------------------------------------------
ensure_sddm
ensure_qt6_virtualkeyboard

if [[ ! -d "$ASSET_DIR" ]]; then
    log_error "Assets not found: $ASSET_DIR"
    exit 1
fi
if [[ ! -d "$THEME_SRC" ]]; then
    log_error "Theme directory not found: $THEME_SRC"
    exit 1
fi
if [[ ! -d "$CONF_SRC" ]]; then
    log_error "SDDM config directory not found: $CONF_SRC"
    exit 1
fi

shopt -s nullglob
conf_src_files=("$CONF_SRC"/*)
shopt -u nullglob
if ((${#conf_src_files[@]} == 0)); then
    log_error "No config files found in $CONF_SRC"
    exit 1
fi

# ------------------------------------------------------------
# Install theme
# ------------------------------------------------------------
THEME_DEST="$THEMES_DIR/$THEME_NAME"
PRESERVE_WP=""

log_status "Preparing target directories…"
sudo install -d -m 0755 "$THEMES_DIR"
sudo install -d -m 0755 "$CONF_DIR"

if [[ -f "$THEME_DEST/sddm-wallpaper.png" ]]; then
    PRESERVE_WP="$(mktemp)"
    cp -f "$THEME_DEST/sddm-wallpaper.png" "$PRESERVE_WP"
    log_status "Preserving current SDDM wallpaper across theme reinstall"
fi

log_status "Installing theme: $THEME_SRC → $THEME_DEST"
sudo rm -rf "$THEME_DEST"
sudo cp -a "$THEME_SRC" "$THEME_DEST"

if [[ -n "$PRESERVE_WP" && -f "$PRESERVE_WP" ]]; then
    sudo cp -f "$PRESERVE_WP" "$THEME_DEST/sddm-wallpaper.png"
    rm -f "$PRESERVE_WP"
fi

apply_qt6_compat "$THEME_DEST"

# User-owned theme dir so waypaper can overwrite sddm-wallpaper.png without sudo.
log_status "Setting theme ownership to $DESKTOP_USER (for live wallpaper sync)"
sudo chown -R "$DESKTOP_USER:$DESKTOP_USER" "$THEME_DEST"
sudo chmod -R u+rwX,go+rX "$THEME_DEST"

# ------------------------------------------------------------
# Install SDDM config — replace all drop-ins with hyprgruv defaults
# ------------------------------------------------------------
BACKUP_DIR="$HOME/.local/backup/sddm_conf_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

log_status "Backing up existing SDDM drop-ins → $BACKUP_DIR"
shopt -s nullglob
for existing in "$CONF_DIR"/*.conf; do
    sudo cp -a "$existing" "$BACKUP_DIR/"
    sudo rm -f "$existing"
    log_status "Removed: $existing"
done
shopt -u nullglob

if [[ -f /etc/sddm.conf && ! -s /etc/sddm.conf ]]; then
    sudo rm -f /etc/sddm.conf
fi

# Ship a single authoritative drop-in (loads after any stray files if they reappear).
log_status "Installing SDDM config → $CONF_DEST"
sudo install -m 0644 "$CONF_SRC/default.conf" "$CONF_DEST"

# Minimal Hyprland config for Wayland greeter (path referenced by default.conf).
if [[ -f "$GREETER_SRC" ]]; then
    log_status "Installing SDDM greeter Hyprland config → $GREETER_DEST"
    sudo install -d -m 0755 "$GREETER_DEST_DIR"
    sudo install -m 0644 "$GREETER_SRC" "$GREETER_DEST"
else
    log_warning "Greeter config missing: $GREETER_SRC"
fi

# ------------------------------------------------------------
# Make SDDM the *active* display manager
#
# Common on EndeavourOS / multi-DE machines:
#   plasma-login-manager (plasmalogin) is display-manager.service
#   → sugar-candy never runs; greeter looks "stock" KDE/EOS.
#
# Order matters (lesson from a botched switch → TTY-only boot):
#   1) Detect + report rivals
#   2) enable -f sddm FIRST (steals display-manager.service alias)
#   3) Then disable other DMs (do NOT disable --now first — that can
#      remove display-manager.service with nothing to replace it)
#   4) Verify alias points at sddm; abort in strict mode if not
# ------------------------------------------------------------
list_display_manager_units() {
    # Units that install Alias=display-manager.service (or act as greeters).
    local -a known=(
        sddm.service
        plasmalogin.service
        gdm.service
        gdm3.service
        lightdm.service
        lxdm.service
        ly.service
        entrance.service
        greetd.service
        slim.service
    )
    local u
    for u in "${known[@]}"; do
        systemctl cat "$u" &>/dev/null || continue
        printf '%s\n' "$u"
    done
}

display_manager_alias_target() {
    readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true
}

claim_sddm_as_display_manager() {
    local unit competing state
    local -a installed=() active_or_enabled=()
    local -a rivals=()

    log_status "Checking for other login / display managers…"

    while IFS= read -r unit; do
        [[ -n "$unit" ]] || continue
        installed+=("$unit")
        if [[ "$unit" == "sddm.service" ]]; then
            continue
        fi
        rivals+=("$unit")
        if systemctl is-enabled "$unit" &>/dev/null 2>&1 \
            || systemctl is-active "$unit" &>/dev/null 2>&1; then
            active_or_enabled+=("$unit")
        fi
    done < <(list_display_manager_units)

    if ((${#installed[@]})); then
        log_status "Display managers present: ${installed[*]}"
    fi

    unit="$(display_manager_alias_target)"
    if [[ -n "$unit" ]]; then
        log_status "Current display-manager.service → $unit"
    else
        log_warning "No display-manager.service alias (would boot to TTY)"
    fi

    if ((${#active_or_enabled[@]})); then
        log_warning "Other login manager(s) enabled/active (typical after Plasma/GNOME install):"
        for competing in "${active_or_enabled[@]}"; do
            state=""
            systemctl is-enabled "$competing" &>/dev/null 2>&1 && state+="enabled "
            systemctl is-active "$competing" &>/dev/null 2>&1 && state+="active"
            log_warning "  - $competing (${state:-present})"
        done
        log_status "Hyprgruv requires SDDM for Sugar Candy — switching display-manager to sddm."
        log_status "(Other DEs stay installed; only the greeter unit is disabled.)"
    fi

    # --- 1) Claim the alias FIRST (never leave the system without a DM) ---
    log_status "Enabling SDDM as display-manager (enable -f replaces any existing alias)…"
    if ! sudo systemctl enable -f sddm.service; then
        log_warning "systemctl enable -f failed — trying manual alias + enable"
        sudo systemctl enable sddm.service 2>/dev/null || true
        if [[ -f /usr/lib/systemd/system/sddm.service ]]; then
            sudo ln -sfn /usr/lib/systemd/system/sddm.service /etc/systemd/system/display-manager.service
            sudo systemctl daemon-reload
        fi
    fi

    # --- 2) Disable rivals for *next boot* (no --now: avoid killing this session) ---
    for competing in "${rivals[@]}"; do
        if systemctl is-enabled "$competing" &>/dev/null 2>&1; then
            log_status "Disabling competing greeter for next boot: $competing"
            # disable without --now: keeps current session alive during install
            sudo systemctl disable "$competing" 2>/dev/null || true
        fi
    done

    sudo systemctl set-default graphical.target >/dev/null 2>&1 || true
    sudo systemctl daemon-reload 2>/dev/null || true

    # --- 3) Verify — critical so we never ship a TTY-only box ---
    unit="$(display_manager_alias_target)"
    if [[ "$unit" == *sddm.service ]] && systemctl is-enabled sddm.service &>/dev/null; then
        log_success "display-manager.service → sddm (Sugar Candy on next login/reboot)"
        if ((${#active_or_enabled[@]})); then
            log_status "Note: ${active_or_enabled[*]} may still be running this session; reboot to use SDDM only."
        fi
        return 0
    fi

    log_error "SDDM is not the active display manager (alias: ${unit:-missing})"
    log_error "Manual fix:"
    log_error "  sudo systemctl enable -f sddm.service"
    log_error "  sudo systemctl disable plasmalogin.service gdm.service lightdm.service 2>/dev/null"
    log_error "  readlink -f /etc/systemd/system/display-manager.service   # must end in sddm.service"
    if declare -F hyprgruv_strict_abort >/dev/null 2>&1; then
        hyprgruv_strict_abort "Failed to claim display-manager for SDDM"
    fi
    return 1
}
claim_sddm_as_display_manager

sync_sddm_wallpaper() {
    local script="$1"
    local user_home
    user_home="$(getent passwd "$DESKTOP_USER" | cut -d: -f6 2>/dev/null || echo "$HOME")"

    # Prefer running as the desktop user with a correct HOME (stow puts scripts under ~/.config).
    # Never fail the whole SDDM install solely because notify-send has no display.
    if [[ "$(id -un)" == "$DESKTOP_USER" ]]; then
        env HOME="$user_home" USER="$DESKTOP_USER" LOGNAME="$DESKTOP_USER" \
            bash "$script" && return 0
        return 1
    fi

    if command -v runuser >/dev/null 2>&1; then
        runuser -u "$DESKTOP_USER" -- env HOME="$user_home" USER="$DESKTOP_USER" LOGNAME="$DESKTOP_USER" \
            bash "$script" && return 0
        return 1
    fi

    if command -v sudo >/dev/null 2>&1; then
        sudo -u "$DESKTOP_USER" HOME="$user_home" bash "$script" && return 0
        return 1
    fi

    bash "$script"
}

if [[ -x "$UPDATE_SDDM" || -f "$UPDATE_SDDM" ]]; then
    log_status "Syncing SDDM wallpaper / theme colors from waypaper…"
    if sync_sddm_wallpaper "$UPDATE_SDDM"; then
        log_success "SDDM wallpaper synced"
    else
        log_warning "SDDM wallpaper sync failed (attempt 1) — retrying once…"
        sleep 1
        if sync_sddm_wallpaper "$UPDATE_SDDM"; then
            log_success "SDDM wallpaper synced on retry"
        else
            log_warning "SDDM wallpaper sync failed — run after login: $UPDATE_SDDM"
            log_warning "Theme is installed; personalization applies once wallpaper sync succeeds."
        fi
    fi
else
    log_warning "update-sddm-wallpaper.sh not found at $UPDATE_SDDM"
    log_warning "Run 02-stow.sh first, then: bash $UPDATE_SDDM"
fi

log_success "Sugar Candy theme and SDDM config installed"
echo
echo "SDDM theme installation complete."
echo "  Theme:     $THEME_DEST"
echo "  Config:    $CONF_DEST"
echo "  Greeter:   $GREETER_DEST"
echo "  Wallpaper: $THEME_DEST/sddm-wallpaper.png  (updated by waypaper)"
echo "  Display manager: $(display_manager_alias_target 2>/dev/null || echo sddm)"
echo
echo "Test greeter:  sudo sddm --test-mode"
echo "Live sync:     $UPDATE_SDDM"
echo
echo "If this machine also has Plasma/GNOME, other greeters were disabled so only"
echo "SDDM runs at boot (packages stay installed; you can re-enable them later)."

sleep 0.5
exit 0