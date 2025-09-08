#!/usr/bin/env bash
# 00-preflight.sh — ensure Hyprland base stack on Arch/EndeavourOS, with repo assets
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Load helpers
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/common.sh"; exit 1; }
[[ -f "$HYPR_DIR/lib/state.sh"  ]] || { echo "[ERROR] Missing: $HYPR_DIR/lib/state.sh";  exit 1; }
source "$HYPR_DIR/lib/common.sh"
source "$HYPR_DIR/lib/state.sh"

# Arch sanity
if ! command -v pacman >/dev/null 2>&1; then
  log_error "pacman not found. This preflight supports Arch/EndeavourOS only."
  exit 1
fi

log_status "Running preflight checks for Hyprland base…"

# ------------------------ helpers ------------------------
pkg_installed() { pacman -Qi "$1" &>/dev/null; }
repo_has()      { pacman -Si "$1" &>/dev/null; }
ensure_pkg() {
  local pkgs=(); for p in "$@"; do pkg_installed "$p" || pkgs+=("$p"); done
  ((${#pkgs[@]})) && sudo pacman -S --noconfirm --needed "${pkgs[@]}" || true
}

sanitize_pacman_conf() {
  local conf="/etc/pacman.conf"
  local ts; ts="$(date +%Y%m%d_%H%M%S)"
  [[ -f "$conf" ]] || return 0

  # Backup once
  sudo cp -a "$conf" "$conf.bak.$ts"

  # 1) Normalize CRLF → LF
  sudo sed -i 's/\r$//' "$conf"

  # 2) Comment any accidental 'Server =' lines that appear while in [options]
  #    We only comment those lines until the next section header.
  sudo awk '
    BEGIN{inopt=0}
    /^\[options\]/{inopt=1; print; next}
    /^\[/{inopt=0; print; next}
    {
      if(inopt && $0 ~ /^[[:space:]]*Server[[:space:]]*=/){
        print "#" $0
      } else {
        print
      }
    }
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
  sudo mv "$conf.tmp.$$" "$conf"

  # 3) Ensure core/extra sections exist (rare fresh installs can be minimal)
  if ! grep -q '^\[core\]' "$conf";  then echo -e "\n[core]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null; fi
  if ! grep -q '^\[extra\]' "$conf"; then echo -e "\n[extra]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null; fi
}

ensure_multilib_enabled() {
  # already visible?
  pacman -Sl multilib &>/dev/null && return 0
  [[ "$(uname -m)" == "x86_64" ]] || return 0

  local conf="/etc/pacman.conf"
  local ts; ts="$(date +%Y%m%d_%H%M%S)"
  sudo cp -a "$conf" "$conf.bak.$ts"

  # Only touch the [multilib] block; do NOT alter anything else.
  # If the block exists but is commented, uncomment it and its Include line.
  if grep -n '^\[multilib\]' "$conf" >/dev/null 2>&1; then
    :
  else
    # Append a correct block if missing
    printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' | sudo tee -a "$conf" >/dev/null
  fi

  # Uncomment the block header and include line if they were commented
  sudo sed -i -E \
    -e 's/^[#[:space:]]*\[multilib\]/[multilib]/' \
    -e '0,/\[multilib\]/{/\[multilib\]/{n; s|^[#[:space:]]*Include[[:space:]]*=[[:space:]]*/etc/pacman\.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|}}' \
    "$conf"

  # Hard refresh
  sudo pacman -Syyu --noconfirm
}

ensure_chaotic_repo_block() {
  # Just ensure the block exists; mirrorlist/keyring are handled elsewhere
  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
}

# ------------------- one-time seed (optional) -------------------
# If you ever want to seed /etc/pacman.conf from assets only when missing:
# if [[ ! -f /etc/pacman.conf && -f "$ASSET_DIR/pacman.conf" ]]; then
#   log_status "Seeding /etc/pacman.conf from assets"
#   sudo install -m 0644 "$ASSET_DIR/pacman.conf" /etc/pacman.conf
# fi

# ------------------ sanitize + multilib ------------------
sanitize_pacman_conf
ensure_multilib_enabled || true

# ------------------ detect GPU + packages ----------------
GPU_VENDOR="generic"
if   lspci | grep -iE ' vga|3d|display' | grep -qi nvidia; then GPU_VENDOR="nvidia"
elif lspci | grep -iE ' vga|3d|display' | grep -qi amd;    then GPU_VENDOR="amd"
elif lspci | grep -iE ' vga|3d|display' | grep -qi intel;  then GPU_VENDOR="intel"; fi
log_status "Detected GPU vendor: $GPU_VENDOR"

case "$GPU_VENDOR" in
  amd)    GFX_PKGS=(mesa vulkan-radeon libva-mesa-driver);     LIB32_GFX=(lib32-mesa lib32-vulkan-radeon) ;;
  intel)  GFX_PKGS=(mesa vulkan-intel  libva-intel-driver);    LIB32_GFX=(lib32-mesa lib32-vulkan-intel)  ;;
  nvidia) GFX_PKGS=(nvidia nvidia-utils);                      LIB32_GFX=(lib32-nvidia-utils)             ;;
  *)      GFX_PKGS=(mesa);                                     LIB32_GFX=(lib32-mesa)                     ;;
esac

AVAILABLE_LIB32=()
for p in "${LIB32_GFX[@]}"; do repo_has "$p" && AVAILABLE_LIB32+=("$p"); done

BASE_PKGS=(hyprland xdg-desktop-portal xdg-desktop-portal-hyprland waybar rofi-wayland wl-clipboard grim slurp brightnessctl polkit networkmanager pipewire pipewire-pulse wireplumber gvfs gvfs-mtp noto-fonts ttf-dejavu)
OPT_TERMS=(ghostty kitty alacritty)
OPT_EXTRAS=(wlogout swaybg hyprpaper hyprlock)

# ---------------------- install ----------------------
log_status "Refreshing package databases"
sudo pacman -Syu --noconfirm

log_status "Installing core packages"
ensure_pkg "${BASE_PKGS[@]}"

log_status "Installing GPU packages"
ensure_pkg "${GFX_PKGS[@]}"
if ((${#AVAILABLE_LIB32[@]})); then
  log_status "Installing 32-bit GPU packages (multilib)"
  ensure_pkg "${AVAILABLE_LIB32[@]}"
else
  log_status "Skipping 32-bit GPU packages (multilib unavailable)"
fi

log_status "Installing optional terminals"
ensure_pkg "${OPT_TERMS[@]}"

log_status "Installing optional extras"
ensure_pkg "${OPT_EXTRAS[@]}"

# ---------------------- services ----------------------
log_status "Enabling services"
sudo systemctl enable --now NetworkManager.service
sudo systemctl enable --now pipewire.service wireplumber.service pipewire-pulse.service 2>/dev/null || true
pkg_installed sddm && sudo systemctl enable --now sddm.service || true

# Ensure chaotic-aur block exists (does nothing if already present)
ensure_chaotic_repo_block || true

# ------------------- optional assets -------------------
PREFLIGHT_DIR="$ASSET_DIR/preflight"
if [[ -d "$PREFLIGHT_DIR" ]]; then
  log_status "Applying preflight assets from $PREFLIGHT_DIR"
  [[ -d "$PREFLIGHT_DIR/etc"       ]] && sudo rsync -a "$PREFLIGHT_DIR/etc/."       /etc/
  [[ -d "$PREFLIGHT_DIR/usr_share" ]] && sudo rsync -a "$PREFLIGHT_DIR/usr_share/." /usr/share/
  if [[ -d "$PREFLIGHT_DIR/systemd" ]]; then
    sudo rsync -a "$PREFLIGHT_DIR/systemd/." /etc/systemd/system/
    sudo systemctl daemon-reload
  fi
  if [[ -f "$PREFLIGHT_DIR/env" ]]; then
    while IFS= read -r line; do
      [[ -z "$line" || "$line" =~ ^# ]] && continue
      key="${line%%=*}"
      if grep -qE "^${key}=" /etc/environment 2>/dev/null; then
        sudo sed -i 's|^'"$key"'=.*$|'"$line"'|' /etc/environment
      else
        echo "$line" | sudo tee -a /etc/environment >/dev/null
      fi
    done < "$PREFLIGHT_DIR/env"
  fi
fi

mark_completed "Preflight"
log_success "Preflight check completed."
