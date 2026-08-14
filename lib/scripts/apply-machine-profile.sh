#!/usr/bin/env bash
# apply-machine-profile.sh — laptop vs desktop profile for Hyprgruv provisioning
#
# Writes machine-local settings (XDG state + gitignored settings/*.sh), generates
# hypridle, tunes blur, enables power tooling, and optional lid / deploy-target.
#
# Usage:
#   bash ~/.hyprgruv/lib/scripts/apply-machine-profile.sh              # apply saved / detect
#   bash ~/.hyprgruv/lib/scripts/apply-machine-profile.sh --prompt      # interactive
#   bash ~/.hyprgruv/lib/scripts/apply-machine-profile.sh laptop       # set + apply
#   bash ~/.hyprgruv/lib/scripts/apply-machine-profile.sh desktop
#   MACHINE_TYPE=laptop bash .../apply-machine-profile.sh --yes
#
# Env:
#   MACHINE_TYPE / HYPRGRUV_MACHINE   laptop|desktop (skips detect)
#   SKIP_MACHINE_PROMPT=1             never ask (use saved / detect / MACHINE_TYPE)
#   HYPRGRUV_NATURAL_SCROLL=true|false
#   HYPRGRUV_DEPLOY_TARGET=0|1        force deploy-target marker on/off
#   HYPRGRUV_LID_SUSPEND=0|1          laptop lid → suspend (default 1 on laptop)
#   HYPRGRUV_SKIP_PACKAGES=1          do not install/enable power packages
#   HYPRGRUV_STRICT                 inherited from installer when sourced path

set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
if [[ ! -f "$HYPR_DIR/lib/common.sh" ]]; then
    # Fallback: script lives in lib/scripts/
    HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
SETTINGS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/settings"
PROFILE_ENV="$STATE_DIR/profile.env"
MACHINE_FILE="$STATE_DIR/machine"
HYPRIDLE_OUT="$STATE_DIR/hypridle.conf"
BLUR_OUT="$STATE_DIR/hypr-blur.conf"
DEPLOY_MARKER_STATE="$STATE_DIR/deploy-target"
# Legacy path still checked by repo-update-check.sh
DEPLOY_MARKER_CFG="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/deploy-target"
LOGIND_DROPIN="/etc/systemd/logind.conf.d/99-hyprgruv-lid.conf"

DO_PROMPT=0
DO_YES=0
EXPLICIT_TYPE=""

usage() {
    sed -n '2,22p' "$0" | sed 's/^# \?//'
}

while [[ $# -gt 0 ]]; do
    case "$1" in
    --prompt | -p) DO_PROMPT=1 ;;
    --yes | -y) DO_YES=1 ;;
    --help | -h)
        usage
        exit 0
        ;;
    laptop | desktop | auto)
        EXPLICIT_TYPE="$1"
        ;;
    *)
        log_error "Unknown argument: $1"
        usage
        exit 1
        ;;
    esac
    shift
done

mkdir -p "$STATE_DIR" "$SETTINGS_DIR"

# ---------------------------------------------------------------------------
# Detection / I/O helpers
# ---------------------------------------------------------------------------
detect_machine_type() {
    local chassis bat
    if [[ -n "${MACHINE_TYPE:-}" ]]; then
        echo "${MACHINE_TYPE}"
        return
    fi
    if [[ -n "${HYPRGRUV_MACHINE:-}" ]]; then
        echo "${HYPRGRUV_MACHINE}"
        return
    fi
    if [[ -f "$MACHINE_FILE" ]]; then
        tr -d '[:space:]' <"$MACHINE_FILE"
        return
    fi
    if declare -F get_choice >/dev/null 2>&1; then
        local saved
        saved="$(get_choice machine_type "")"
        if [[ "$saved" == "laptop" || "$saved" == "desktop" ]]; then
            echo "$saved"
            return
        fi
    fi

    chassis="$(hostnamectl 2>/dev/null | awk -F': ' '/Chassis/ {print tolower($2); exit}')"
    case "$chassis" in
    laptop | convertible | portable | handset)
        echo laptop
        return
        ;;
    esac

    for bat in /sys/class/power_supply/*/type; do
        [[ -f "$bat" ]] || continue
        if grep -qx Battery "$bat" 2>/dev/null; then
            echo laptop
            return
        fi
    done

    echo desktop
}

detect_gpu_vendor() {
    # Only VGA/3D/Display lines — never match "Corporation" (contains "ati").
    local lines
    lines="$(lspci 2>/dev/null | grep -iE 'vga compatible|3d controller|display controller' || true)"
    if echo "$lines" | grep -qi nvidia; then
        if echo "$lines" | grep -qiE 'intel|amd |radeon|advanced micro devices'; then
            echo hybrid-nvidia
        else
            echo nvidia
        fi
        return
    fi
    if echo "$lines" | grep -qiE 'amd |radeon|advanced micro devices'; then
        echo amd
        return
    fi
    if echo "$lines" | grep -qi intel; then
        echo intel
        return
    fi
    echo generic
}

detect_igpu_libva() {
    # Hybrid systems: pick the iGPU VA-API driver. Empty if none found.
    local lines
    lines="$(lspci 2>/dev/null | grep -iE 'vga compatible|3d controller|display controller' || true)"
    if echo "$lines" | grep -qi intel; then
        echo iHD
        return
    fi
    if echo "$lines" | grep -qiE 'amd |radeon|advanced micro devices'; then
        echo radeonsi
        return
    fi
    echo ""
}

write_setting() {
    local name="$1"
    local value="$2"
    printf '%s\n' "$value" >"$SETTINGS_DIR/${name}.sh"
}

read_setting_file() {
    local name="$1"
    local fallback="${2:-}"
    local f="$SETTINGS_DIR/${name}.sh"
    if [[ -f "$f" ]]; then
        tr -d '[:space:]' <"$f"
        return
    fi
    printf '%s' "$fallback"
}

bool_norm() {
    case "${1,,}" in
    1 | true | yes | on | y) echo true ;;
    *) echo false ;;
    esac
}

# ---------------------------------------------------------------------------
# Interactive prompt
# ---------------------------------------------------------------------------
hardware_guess_machine() {
    local c bat
    c="$(hostnamectl 2>/dev/null | awk -F': ' '/Chassis/ {print tolower($2); exit}')"
    case "$c" in
    laptop | convertible | portable | handset) echo laptop; return ;;
    esac
    for bat in /sys/class/power_supply/*/type; do
        [[ -f "$bat" ]] || continue
        if grep -qx Battery "$bat" 2>/dev/null; then
            echo laptop
            return
        fi
    done
    echo desktop
}

prompt_machine_type() {
    local detected choice
    # Env / CLI win; else hardware guess for the prompt label
    if [[ -n "${MACHINE_TYPE:-}" ]]; then
        detected="$MACHINE_TYPE"
    elif [[ -n "${HYPRGRUV_MACHINE:-}" ]]; then
        detected="$HYPRGRUV_MACHINE"
    elif [[ -f "$MACHINE_FILE" ]]; then
        detected="$(tr -d '[:space:]' <"$MACHINE_FILE")"
    else
        detected="$(hardware_guess_machine)"
    fi
    [[ "$detected" == "laptop" || "$detected" == "desktop" ]] || detected="$(hardware_guess_machine)"

    if [[ "${SKIP_MACHINE_PROMPT:-0}" == "1" || "$DO_YES" -eq 1 ]]; then
        if [[ -n "$EXPLICIT_TYPE" && "$EXPLICIT_TYPE" != "auto" ]]; then
            echo "$EXPLICIT_TYPE"
        else
            echo "$detected"
        fi
        return
    fi

    if [[ -n "$EXPLICIT_TYPE" && "$EXPLICIT_TYPE" != "auto" && "$DO_PROMPT" -eq 0 ]]; then
        echo "$EXPLICIT_TYPE"
        return
    fi

    if ! command -v gum >/dev/null 2>&1; then
        log_warning "gum not found — using detected machine type: $detected"
        echo "$detected"
        return
    fi

    hyprgruv_section_intro "Machine profile" 2>/dev/null || display_header "Machine profile"
    cat <<EOF

Hyprgruv will tailor input, idle, power, GPU env, and performance for this machine.

  Detected suggestion: ${detected}
  GPU detect (informational): $(detect_gpu_vendor)

EOF

    choice="$(
        gum_choose_prompt \
            --header "Is this a laptop or a desktop?" \
            "Auto (${detected})" \
            "Laptop" \
            "Desktop"
    )" || choice="Auto (${detected})"

    case "$choice" in
    Laptop | laptop) echo laptop ;;
    Desktop | desktop) echo desktop ;;
    *) echo "$detected" ;;
    esac
}

prompt_laptop_extras() {
    # Sets globals: NATURAL_SCROLL, WANT_DEPLOY, WANT_LID
    NATURAL_SCROLL="${HYPRGRUV_NATURAL_SCROLL:-}"
    WANT_DEPLOY="${HYPRGRUV_DEPLOY_TARGET:-}"
    WANT_LID="${HYPRGRUV_LID_SUSPEND:-}"

    # Default: classic trackpad scroll (not "natural"/inverse). Seamless with most
    # terminal + mouse muscle memory; override with HYPRGRUV_NATURAL_SCROLL=true.
    if [[ "${SKIP_MACHINE_PROMPT:-0}" == "1" || "$DO_YES" -eq 1 ]]; then
        NATURAL_SCROLL="$(bool_norm "${NATURAL_SCROLL:-false}")"
        WANT_DEPLOY="${WANT_DEPLOY:-1}"
        WANT_LID="${WANT_LID:-1}"
        return
    fi

    if ! command -v gum >/dev/null 2>&1; then
        NATURAL_SCROLL="$(bool_norm "${NATURAL_SCROLL:-false}")"
        WANT_DEPLOY="${WANT_DEPLOY:-1}"
        WANT_LID="${WANT_LID:-1}"
        return
    fi

    if [[ -z "$NATURAL_SCROLL" ]]; then
        # Default No = classic scroll (finger down → content down / scrollbar down)
        if gum_confirm_prompt "Enable natural (macOS-style / inverse) touchpad scrolling? (default: classic)"; then
            NATURAL_SCROLL=true
        else
            NATURAL_SCROLL=false
        fi
    else
        NATURAL_SCROLL="$(bool_norm "$NATURAL_SCROLL")"
    fi

    if [[ -z "$WANT_DEPLOY" ]]; then
        if gum_confirm_prompt "Treat this machine as a deploy/pull target (repo update checks)?"; then
            WANT_DEPLOY=1
        else
            WANT_DEPLOY=0
        fi
    fi

    if [[ -z "$WANT_LID" ]]; then
        if gum_confirm_prompt "Suspend when laptop lid is closed?"; then
            WANT_LID=1
        else
            WANT_LID=0
        fi
    fi
}

# ---------------------------------------------------------------------------
# Profile values
# ---------------------------------------------------------------------------
apply_profile_values() {
    local machine="$1"
    local gpu
    gpu="$(detect_gpu_vendor)"

    local natural_scroll=false
    local touchpad_tap=false
    local touchpad_dwt=false
    local scroll_factor=1.0
    local workspace_swipe=false
    local monitors_mode=desktop
    local animations_enabled=true
    local blur_passes=3
    local blur_size=10
    local shadow_enabled=true
    local lock_timeout=900
    local dpms_timeout=960
    local suspend_timeout=0
    local libva=""
    local want_deploy=0
    local want_lid=0

    # VA-API only. Never write WLR_NO_HARDWARE_CURSORS / __GLX_VENDOR_* —
    # those are obsolete (Aquamarine) or leak onto the wrong GPU.
    # Hybrid: decode on the iGPU (battery + OBS). Dedicated NVIDIA: nvidia.
    case "$gpu" in
    nvidia)
        libva=nvidia
        ;;
    hybrid-nvidia)
        libva="$(detect_igpu_libva)"
        ;;
    amd)
        libva=radeonsi
        ;;
    intel)
        libva=iHD
        ;;
    *)
        libva=""
        ;;
    esac

    if [[ "$machine" == "laptop" ]]; then
        # Classic scroll by default (not inverse/natural) — better in terminals
        natural_scroll="$(bool_norm "${NATURAL_SCROLL:-false}")"
        touchpad_tap=true
        touchpad_dwt=true
        scroll_factor=0.6
        workspace_swipe=true
        monitors_mode=laptop
        # --- GPU / battery: lighter decorations (not Blitz — Blitz is work-focus, all off)
        # Cost of blur ≈ O(passes × size²); prefer 1 pass + small size on iGPU.
        animations_enabled=true
        blur_passes=1
        blur_size=6
        shadow_enabled=true
        # Idle: dim → lock → DPMS → suspend (see write_hypridle_conf)
        lock_timeout=300
        dpms_timeout=360
        suspend_timeout=900
        want_deploy="${WANT_DEPLOY:-1}"
        want_lid="${WANT_LID:-1}"
    else
        natural_scroll="$(bool_norm "${HYPRGRUV_NATURAL_SCROLL:-false}")"
        touchpad_tap=false
        touchpad_dwt=false
        scroll_factor=1.0
        workspace_swipe=false
        monitors_mode=desktop
        # Desktop: richer blur when dGPU / AC power is common
        animations_enabled=true
        blur_passes=3
        blur_size=10
        shadow_enabled=true
        lock_timeout=900
        dpms_timeout=960
        suspend_timeout=0
        want_deploy="${HYPRGRUV_DEPLOY_TARGET:-0}"
        want_lid=0
    fi

    # Persist machine marker
    printf '%s\n' "$machine" >"$MACHINE_FILE"
    if declare -F save_choice >/dev/null 2>&1; then
        save_choice machine_type "$machine" || true
    fi

    # Settings files (Lua + shell consumers)
    write_setting machine "$machine"
    write_setting natural_scroll "$natural_scroll"
    write_setting touchpad_tap "$touchpad_tap"
    write_setting touchpad_dwt "$touchpad_dwt"
    write_setting touchpad_scroll_factor "$scroll_factor"
    write_setting workspace_swipe "$workspace_swipe"
    write_setting monitors_mode "$monitors_mode"
    write_setting animations_enabled "$animations_enabled"
    write_setting gpu_vendor "$gpu"
    write_setting libva_driver "${libva:-}"
    # Always 0: overwrite any leftover NVIDIA/WLR force from older profiles.
    write_setting wlr_no_hw_cursors 0
    write_setting shadow_enabled "$shadow_enabled"
    write_setting blur_passes "$blur_passes"
    write_setting blur_size "$blur_size"

    # Idle timeouts (settings scripts used by hyprgruv-settings UI)
    write_setting hypridle_hyprlock_timeout "$lock_timeout"
    write_setting hypridle_dpms_timeout "$dpms_timeout"
    write_setting hypridle_suspend_timeout "$suspend_timeout"

    # profile.env for shell tooling
    cat >"$PROFILE_ENV" <<EOF
# Generated by apply-machine-profile.sh — do not commit
MACHINE=$machine
GPU_VENDOR=$gpu
LIBVA_DRIVER=$libva
WLR_NO_HW_CURSORS=0
NATURAL_SCROLL=$natural_scroll
TOUCHPAD_TAP=$touchpad_tap
TOUCHPAD_DWT=$touchpad_dwt
TOUCHPAD_SCROLL_FACTOR=$scroll_factor
WORKSPACE_SWIPE=$workspace_swipe
MONITORS_MODE=$monitors_mode
ANIMATIONS_ENABLED=$animations_enabled
SHADOW_ENABLED=$shadow_enabled
HYPRIDLE_LOCK=$lock_timeout
HYPRIDLE_DPMS=$dpms_timeout
HYPRIDLE_SUSPEND=$suspend_timeout
DEPLOY_TARGET=$want_deploy
LID_SUSPEND=$want_lid
APPLIED_AT=$(date -Iseconds)
EOF

    write_hypridle_conf "$machine" "$lock_timeout" "$dpms_timeout" "$suspend_timeout"
    write_blur_conf "$blur_size" "$blur_passes"
    apply_deploy_marker "$want_deploy"
    apply_lid_policy "$want_lid"
    apply_fn_lock "$machine"
    apply_logitech_hidpp_udev
    ensure_power_stack "$machine" "$gpu"
    ensure_laptop_fingerprint "$machine"
    ensure_git_sync_role "$machine" "$want_deploy"

    log_success "Machine profile applied: $machine (GPU=$gpu, libva=${libva:-none})"
    log_status "State: $PROFILE_ENV"
    log_status "Hypridle: $HYPRIDLE_OUT"
    if command -v hyprctl >/dev/null 2>&1 && [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        log_status "Reloading Hyprland + hypridle…"
        hyprctl reload >/dev/null 2>&1 || true
        restart_hypridle
        if [[ -x "${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/scripts/apply-hypr-blur.sh" ]]; then
            HYPR_BLUR_CONF="$BLUR_OUT" bash "${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/scripts/apply-hypr-blur.sh" >/dev/null 2>&1 || true
        fi
    fi
}

write_hypridle_conf() {
    local machine="$1"
    local lock_t="$2"
    local dpms_t="$3"
    local susp_t="$4"
    local lock_conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprlock/hyprlock.conf"
    local lock_cmd="pidof hyprlock || hyprlock -c ${lock_conf}"
    local dim_t=0

    # Laptop: dim a bit before lock (battery-friendly, less abrupt)
    if [[ "$machine" == "laptop" ]]; then
        dim_t=$((lock_t > 60 ? lock_t - 60 : 0))
    fi

    cat >"$HYPRIDLE_OUT" <<EOF
# Generated by apply-machine-profile.sh — machine-local (not stowed)
# machine=${machine}  lock=${lock_t}s  dpms=${dpms_t}s  suspend=${susp_t}s
general {
    lock_cmd = ${lock_cmd}
    before_sleep_cmd = loginctl lock-session
    after_sleep_cmd = hyprctl dispatch dpms on
    ignore_dbus_inhibit = false
}

EOF

    if [[ "$dim_t" -gt 0 ]] && command -v brightnessctl >/dev/null 2>&1; then
        cat >>"$HYPRIDLE_OUT" <<EOF
# Dim display before lock (laptop)
listener {
    timeout = ${dim_t}
    on-timeout = brightnessctl -s set 15%
    on-resume = brightnessctl -r
}

EOF
    fi

    cat >>"$HYPRIDLE_OUT" <<EOF
# Screen lock
listener {
    timeout = ${lock_t}
    on-timeout = loginctl lock-session
}

# Display power off
listener {
    timeout = ${dpms_t}
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
EOF

    if [[ "${susp_t}" -gt 0 ]] 2>/dev/null; then
        cat >>"$HYPRIDLE_OUT" <<EOF

# Suspend (laptops) — lock already handled by before_sleep_cmd
listener {
    timeout = ${susp_t}
    on-timeout = systemctl suspend
}
EOF
    fi
}

# Fingerprint readers: fprintd only helps if libfprint has a driver.
# Many Goodix USB IDs appear in lsusb but are unsupported by stock libfprint —
# enroll then fails with NoSuchDevice (common: 27c6:55b4 on Lenovo Yoga).
ensure_laptop_fingerprint() {
    local machine="$1"
    [[ "$machine" == "laptop" ]] || return 0

    local usb_line="" vid_pid=""
    usb_line="$(lsusb 2>/dev/null | grep -iE 'fingerprint|goodix' || true)"
    if [[ -z "$usb_line" ]]; then
        log_status "No fingerprint reader in lsusb — skip fprintd"
        return 0
    fi

    vid_pid="$(echo "$usb_line" | grep -oE '[0-9a-fA-F]{4}:[0-9a-fA-F]{4}' | head -1 | tr '[:upper:]' '[:lower:]')"
    log_status "Fingerprint USB present: $usb_line"

    # Stock libfprint does not support these Goodix IDs (as of common Arch packages).
    # Experimental AUR forks exist but may require a risky device flash.
    case "$vid_pid" in
    27c6:55b4 | 27c6:55a4 | 27c6:5110 | 27c6:538c | 27c6:5840)
        log_warning "Goodix $vid_pid is usually NOT supported by stock libfprint/fprintd."
        log_warning "That is why fprintd-enroll says: No devices available"
        log_status "Options:"
        log_status "  1) Password-only lock (default — fully supported)"
        log_status "  2) Experimental: AUR libfprint-goodixtls-55x4 / -fixed (55b4)"
        log_status "     May require goodix-fp-dump firmware flash — can brick the sensor."
        log_status "     Read: https://aur.archlinux.org/packages/libfprint-goodixtls-55x4"
        log_status "Hyprgruv will NOT auto-install experimental fingerprint forks."
        # Keep fprintd out of the way; don't rewrite PAM until a device enumerates
        write_setting fingerprint_status "unsupported-stock:${vid_pid}"
        return 0
        ;;
    esac

    log_status "Fingerprint hardware detected — ensuring stock fprintd"

    if [[ "${HYPRGRUV_SKIP_PACKAGES:-0}" != "1" ]]; then
        if ! pacman -Qq fprintd &>/dev/null; then
            if command -v yay >/dev/null 2>&1; then
                yay -S --needed --noconfirm fprintd 2>/dev/null \
                    || log_warning "Could not install fprintd"
            elif sudo -n true 2>/dev/null || [[ -t 0 ]]; then
                sudo pacman -S --needed --noconfirm fprintd 2>/dev/null \
                    || log_warning "Could not install fprintd"
            fi
        fi
    fi

    if ! pacman -Qq fprintd &>/dev/null; then
        write_setting fingerprint_status "pkg-missing"
        return 0
    fi

    # Only wire PAM if libfprint can actually see a device
    local seen=0
    if command -v python3 >/dev/null 2>&1; then
        if python3 - <<'PY' 2>/dev/null; then
import gi
gi.require_version("FPrint", "2.0")
from gi.repository import FPrint
ctx = FPrint.Context()
ctx.enumerate()
raise SystemExit(0 if ctx.get_devices() else 1)
PY
            seen=1
        fi
    fi

    if [[ $seen -eq 0 ]]; then
        log_warning "fprintd installed but libfprint reports 0 devices — skip hyprlock PAM"
        log_status "Use password unlock. Optional experimental drivers only if you accept risk."
        write_setting fingerprint_status "no-libfprint-device:${vid_pid:-unknown}"
        return 0
    fi

    sudo systemctl enable --now fprintd.service 2>/dev/null \
        || log_warning "Could not enable fprintd.service"
    if [[ -f /etc/pam.d/hyprlock ]] && ! grep -q 'pam_fprintd' /etc/pam.d/hyprlock 2>/dev/null; then
        if sudo -n true 2>/dev/null || [[ -t 0 ]]; then
            log_status "Configuring /etc/pam.d/hyprlock for fingerprint (password still works)"
            sudo tee /etc/pam.d/hyprlock >/dev/null <<'EOF'
#%PAM-1.0
# Hyprgruv laptop: password OR fingerprint unlocks hyprlock
auth        sufficient      pam_unix.so try_first_pass nullok
auth        sufficient      pam_fprintd.so
auth        required        pam_deny.so

account     include         login
password    include         login
session     include         login
EOF
        fi
    fi
    write_setting fingerprint_status "ready:${vid_pid:-ok}"
    log_status "Enroll: fprintd-enroll   List: fprintd-list \$USER   Verify: fprintd-verify"
}

write_blur_conf() {
    local size="$1"
    local passes="$2"
    local machine_file="${MACHINE_FILE:-$STATE_DIR/machine}"
    local machine="desktop"
    [[ -f "$machine_file" ]] && machine="$(tr -d '[:space:]' <"$machine_file")"

    # Laptop: lean global blur (1 pass / small size); Blitz (work) turns blur off entirely.
    local noise="0.01" contrast="0.8" vibrancy="0.2"
    local lock_passes="$passes" lock_size=2
    if [[ "$machine" == "laptop" ]]; then
        noise="0.02"
        contrast="0.75"
        vibrancy="0.15"
        lock_passes=1
        lock_size=2
    fi

    cat >"$BLUR_OUT" <<EOF
# Generated by apply-machine-profile.sh — machine-local blur ($machine)
# Cost ≈ O(passes × size²). Laptop defaults conserve iGPU; desktop is richer.
decoration_enabled=1
decoration_size=${size}
decoration_passes=${passes}
decoration_noise=${noise}
decoration_contrast=${contrast}
decoration_vibrancy=${vibrancy}

layer_rofi_blur=1
layer_rofi_ignore_alpha=0.2
layer_waypaper_blur=1
layer_waypaper_ignore_alpha=0.10
layer_wlogout_blur=1
layer_wlogout_ignore_alpha=0.0001
layer_hyprlock_blur=1
layer_hyprlock_ignore_alpha=0.05
hyprlock_bg_blur_passes=${lock_passes}
hyprlock_bg_blur_size=${lock_size}
EOF
}

apply_deploy_marker() {
    local want="$1"
    if [[ "$want" == "1" ]]; then
        touch "$DEPLOY_MARKER_STATE"
        mkdir -p "$(dirname "$DEPLOY_MARKER_CFG")"
        # Prefer state; also touch config path if writable and not a broken layout
        if [[ -d "$(dirname "$DEPLOY_MARKER_CFG")" ]]; then
            touch "$DEPLOY_MARKER_CFG" 2>/dev/null || true
        fi
        log_status "Deploy target enabled (update checks allowed)"
    else
        rm -f "$DEPLOY_MARKER_STATE" "$DEPLOY_MARKER_CFG" 2>/dev/null || true
    fi
}

apply_fn_lock() {
    # F1–F12 are not assigned distribution-wide. On IdeaPad/Yoga, turn Fn-lock
    # on so the F-row emits F1–F12 without holding Fn. No-op on other machines.
    local machine="$1"
    local fnlock_script="${XDG_CONFIG_HOME:-$HOME/.config}/hyprgruv/scripts/fn-lock.sh"
    local udev_src="$HYPR_DIR/lib/udev/99-hyprgruv-fnlock.rules"
    local udev_dst="/etc/udev/rules.d/99-hyprgruv-fnlock.rules"

    if [[ "$machine" != "laptop" ]]; then
        return 0
    fi

    if [[ -x "$fnlock_script" ]]; then
        bash "$fnlock_script" || true
    fi

    if [[ ! -f "$udev_src" ]]; then
        return 0
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        log_status "Fn-lock udev rule skipped (needs passwordless sudo); login script still sets it"
        return 0
    fi
    if sudo install -m 644 "$udev_src" "$udev_dst"; then
        log_status "Installed $udev_dst (F-row = F1–F12 without Fn)"
    fi
}

apply_logitech_hidpp_udev() {
    # MX Mechanical F3/F4 set the keyboard's own LEDs via HID++ hidraw.
    local udev_src="$HYPR_DIR/lib/udev/99-hyprgruv-logitech-hidpp.rules"
    local udev_dst="/etc/udev/rules.d/99-hyprgruv-logitech-hidpp.rules"

    if [[ ! -f "$udev_src" ]]; then
        return 0
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        return 0
    fi
    if ! sudo -n true 2>/dev/null; then
        log_status "Logitech HID++ udev rule skipped (needs passwordless sudo)"
        return 0
    fi
    if sudo install -m 644 "$udev_src" "$udev_dst"; then
        log_status "Installed $udev_dst (MX Mechanical keyboard backlight)"
        sudo udevadm control --reload-rules 2>/dev/null || true
        sudo udevadm trigger --subsystem-match=hidraw 2>/dev/null || true
    fi
}

apply_lid_policy() {
    local want="$1"
    if [[ "$want" == "1" ]]; then
        if ! command -v sudo >/dev/null 2>&1; then
            log_warning "sudo missing — cannot install lid logind drop-in"
            return 0
        fi
        log_status "Installing logind lid→suspend drop-in…"
        if ! sudo -n true 2>/dev/null && ! [[ -t 0 ]]; then
            log_warning "No passwordless sudo / TTY — skip lid drop-in (re-run with sudo later)"
            log_status "Manual: sudo tee $LOGIND_DROPIN <<'EOF' … HandleLidSwitch=suspend"
            return 0
        fi
        if sudo mkdir -p /etc/systemd/logind.conf.d \
            && sudo tee "$LOGIND_DROPIN" >/dev/null <<'EOF'
# Managed by Hyprgruv apply-machine-profile.sh (laptop)
[Login]
HandleLidSwitch=suspend
HandleLidSwitchExternalPower=suspend
HandleLidSwitchDocked=ignore
EOF
        then
            sudo systemctl kill -s HUP systemd-logind.service 2>/dev/null \
                || sudo systemctl restart systemd-logind.service 2>/dev/null \
                || log_warning "Could not reload logind — reboot to apply lid policy"
        else
            log_warning "Could not install lid logind drop-in (sudo failed)"
        fi
    else
        if [[ -f "$LOGIND_DROPIN" ]]; then
            log_status "Removing laptop lid logind drop-in (desktop profile)…"
            sudo rm -f "$LOGIND_DROPIN" 2>/dev/null || true
            sudo systemctl kill -s HUP systemd-logind.service 2>/dev/null || true
        fi
    fi
}

ensure_power_stack() {
    local machine="$1"
    local gpu="$2"

    if [[ "${HYPRGRUV_SKIP_PACKAGES:-0}" == "1" ]]; then
        log_status "HYPRGRUV_SKIP_PACKAGES=1 — skipping power package ensure"
        return 0
    fi

    local pkgs=(power-profiles-daemon upower)
    # brightnessctl already in pacman.list; ensure on laptops
    [[ "$machine" == "laptop" ]] && pkgs+=(brightnessctl)

    local need=()
    local p
    for p in "${pkgs[@]}"; do
        pacman -Qq "$p" &>/dev/null || need+=("$p")
    done

    if ((${#need[@]})); then
        log_status "Installing power stack: ${need[*]}"
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed --noconfirm "${need[@]}" || log_warning "Failed to install: ${need[*]}"
        elif sudo -n true 2>/dev/null || [[ -t 0 ]]; then
            sudo pacman -S --needed --noconfirm "${need[@]}" || log_warning "Failed to install: ${need[*]}"
        else
            log_warning "Cannot install without sudo TTY: ${need[*]}"
        fi
    fi

    if pacman -Qq power-profiles-daemon &>/dev/null; then
        if systemctl is-enabled power-profiles-daemon.service &>/dev/null; then
            :
        else
            sudo systemctl enable --now power-profiles-daemon.service 2>/dev/null \
                || log_warning "Could not enable power-profiles-daemon (sudo)"
        fi
        # Avoid stacking with auto-cpufreq / tlp if user installed them manually
        if systemctl is-enabled auto-cpufreq.service &>/dev/null; then
            log_warning "auto-cpufreq is enabled — disable it to avoid fighting power-profiles-daemon"
        fi
        if systemctl is-enabled tlp.service &>/dev/null; then
            log_warning "tlp is enabled — disable it to avoid fighting power-profiles-daemon"
        fi
    fi

    # Hybrid NVIDIA laptop hint only (do not force install or NVIDIA env)
    if [[ "$machine" == "laptop" && "$gpu" == "hybrid-nvidia" ]]; then
        log_status "Hybrid NVIDIA detected. Optional later: nvidia + nvidia-utils + supergfxctl (not auto-installed)."
        log_status "VA-API stays on the iGPU. Do not set __GLX_VENDOR_LIBRARY_NAME or WLR_NO_HARDWARE_CURSORS."
    fi
}

restart_hypridle() {
    local bin=""
    if command -v hypridle >/dev/null 2>&1; then
        bin="$(command -v hypridle)"
    elif [[ -x /usr/bin/hypridle ]]; then
        bin=/usr/bin/hypridle
    else
        log_warning "hypridle not installed — idle config written; install hypridle package"
        return 0
    fi
    pkill -x hypridle 2>/dev/null || true
    sleep 0.2
    if [[ -f "$HYPRIDLE_OUT" ]]; then
        "$bin" -c "$HYPRIDLE_OUT" &
    else
        "$bin" &
    fi
}

# git-sync role: desktop → source (git-eod push); laptop/deploy → deploy (git-eod-pull)
ensure_git_sync_role() {
    local machine="$1"
    local want_deploy="$2"
    local role="source"
    if [[ "$machine" == "laptop" || "$want_deploy" == "1" ]]; then
        role="deploy"
    fi

    # shellcheck source=/dev/null
    if [[ -f "$HYPR_DIR/lib/scripts/git-eod-common.sh" ]]; then
        source "$HYPR_DIR/lib/scripts/git-eod-common.sh"
        # Keep existing FOLLOW if conf already present
        if [[ -f "$GIT_SYNC_CONF" ]]; then
            git_sync_init_conf "$role" 0
        else
            git_sync_init_conf "$role" 1
        fi
        log_status "git-sync ROLE=$role (FOLLOW=$(git_sync_conf_get FOLLOW))"
        log_status "Manage optional repos: git-sync list | follow | local-only | inventory"
    fi

    # Login + periodic sync reminders (role-aware)
    systemctl --user daemon-reload 2>/dev/null || true
    if systemctl --user enable --now git-eod-remind.timer 2>/dev/null; then
        log_status "Enabled git-eod-remind.timer (boot + 12h catch-up)"
    else
        log_warning "Could not enable git-eod-remind.timer (reload user systemd after session login)"
    fi
    if systemctl --user enable --now system-critical-alert.timer 2>/dev/null; then
        log_status "Enabled system-critical-alert.timer (sticky SwayNC threshold alerts)"
    else
        log_warning "Could not enable system-critical-alert.timer"
    fi
    if systemctl --user enable gpu-screen-recorder-ui.service 2>/dev/null; then
        log_status "Enabled gpu-screen-recorder-ui.service (Alt+Z overlay)"
        if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            systemctl --user start gpu-screen-recorder-ui.service 2>/dev/null || true
        fi
    else
        log_warning "Could not enable gpu-screen-recorder-ui.service"
    fi
    # Deploy machines: also poll origin for hyprgruv commits (rofi menu)
    if [[ "$role" == "deploy" || "$want_deploy" == "1" ]]; then
        if systemctl --user enable --now hyprgruv-update-check.timer 2>/dev/null; then
            log_status "Enabled hyprgruv-update-check.timer (deploy pull prompts)"
        else
            log_warning "Could not enable hyprgruv-update-check.timer"
        fi
    else
        systemctl --user disable --now hyprgruv-update-check.timer 2>/dev/null || true
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
    local machine

    if [[ -n "$EXPLICIT_TYPE" && "$EXPLICIT_TYPE" != "auto" && "$DO_PROMPT" -eq 0 && "${SKIP_MACHINE_PROMPT:-0}" != "1" && "$DO_YES" -eq 0 ]]; then
        # CLI: apply-machine-profile.sh laptop
        machine="$EXPLICIT_TYPE"
        if [[ "$machine" == "laptop" ]]; then
            NATURAL_SCROLL="$(bool_norm "${HYPRGRUV_NATURAL_SCROLL:-false}")"
            WANT_DEPLOY="${HYPRGRUV_DEPLOY_TARGET:-1}"
            WANT_LID="${HYPRGRUV_LID_SUSPEND:-1}"
        fi
    elif [[ "$DO_PROMPT" -eq 1 || ! -f "$MACHINE_FILE" || "${FORCE:-0}" == "1" ]]; then
        machine="$(prompt_machine_type)"
        if [[ "$machine" == "auto" ]]; then
            machine="$(detect_machine_type)"
        fi
        if [[ "$machine" == "laptop" ]]; then
            prompt_laptop_extras
        fi
    else
        machine="$(tr -d '[:space:]' <"$MACHINE_FILE")"
        [[ "$machine" == "laptop" || "$machine" == "desktop" ]] || machine="$(detect_machine_type)"
        if [[ "$machine" == "laptop" ]]; then
            NATURAL_SCROLL="$(bool_norm "${HYPRGRUV_NATURAL_SCROLL:-$(read_setting_file natural_scroll false)}")"
            WANT_DEPLOY="${HYPRGRUV_DEPLOY_TARGET:-$([[ -f $DEPLOY_MARKER_STATE || -f $DEPLOY_MARKER_CFG ]] && echo 1 || echo 0)}"
            WANT_LID="${HYPRGRUV_LID_SUSPEND:-1}"
        fi
    fi

    case "$machine" in
    laptop | desktop) ;;
    *)
        log_error "Invalid machine type: $machine"
        exit 1
        ;;
    esac

    log_status "Applying Hyprgruv machine profile: $machine"
    apply_profile_values "$machine"
}

main
