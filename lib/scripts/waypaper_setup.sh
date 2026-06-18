#!/usr/bin/env bash
# waypaper_setup.sh — install waypaper stack, optional wallpaper repo, initial matugen theme
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
WALLPAPERS_REPO="https://github.com/kirkserverhl/Wallpapers.git"
WALLPAPER_PKGS=(awww waypaper waypaper-engine)

# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/common.sh" ]] || { echo "[ERROR] Missing $HYPR_DIR/lib/common.sh"; exit 1; }
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
[[ -f "$HYPR_DIR/lib/state.sh" ]] && source "$HYPR_DIR/lib/state.sh"

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hyprgruv/scripts/colors.sh" 2>/dev/null || true

if [[ "${FORCE:-0}" != "1" && "${RE_RUN:-0}" != "1" ]] && declare -F is_completed >/dev/null 2>&1 && is_completed "Wallpaper setup"; then
  log_status "Wallpaper setup already completed (FORCE=1 to re-run)"
  exit 0
fi

display_header "Wallpaper & Theming"

install_wallpaper_packages() {
  local missing=()
  for pkg in "${WALLPAPER_PKGS[@]}"; do
    pacman -Qq "$pkg" &>/dev/null || missing+=("$pkg")
  done
  ((${#missing[@]})) || { log_success "waypaper stack already installed"; return 0; }

  local official=() aur=()
  for pkg in "${missing[@]}"; do
    if pacman -Si "$pkg" &>/dev/null 2>&1; then
      official+=("$pkg")
    else
      aur+=("$pkg")
    fi
  done

  if ((${#official[@]})); then
    log_status "Installing official packages: ${official[*]}"
    sudo pacman -S --needed --noconfirm "${official[@]}"
  fi

  if ((${#aur[@]})); then
    command -v yay >/dev/null 2>&1 || {
      log_error "yay is required for AUR packages: ${aur[*]}"
      return 1
    }
    log_status "Installing AUR packages: ${aur[*]}"
    yay -S --needed --noconfirm "${aur[@]}"
  fi

  log_success "waypaper, waypaper-engine, and awww installed"
}

ensure_wallpaper_dir() {
  mkdir -p "$WALLPAPER_DIR"
  local stowed_default="$HYPR_DIR/home/Pictures/Wallpapers/default.png"
  if [[ ! -f "$WALLPAPER_DIR/default.png" && -f "$stowed_default" ]]; then
    cp -a "$stowed_default" "$WALLPAPER_DIR/default.png"
    log_status "Seeded default wallpaper into $WALLPAPER_DIR"
  fi
}

download_wallpaper_repo() {
  command -v git >/dev/null 2>&1 || { log_error "git not found"; return 1; }

  local tmp
  tmp="$(mktemp -d)"
  log_status "Cloning HyprGruv Wallpapers from $WALLPAPERS_REPO …"

  if ! git clone --depth 1 "$WALLPAPERS_REPO" "$tmp/wallpapers"; then
    rm -rf "$tmp"
    log_warning "Could not clone wallpaper repo (empty repo or network issue?)"
    log_warning "You can add images manually to $WALLPAPER_DIR"
    return 1
  fi

  local count=0
  while IFS= read -r -d '' img; do
    local base
    base="$(basename "$img")"
    if [[ ! -f "$WALLPAPER_DIR/$base" ]]; then
      cp -a "$img" "$WALLPAPER_DIR/$base"
      ((count++)) || true
    fi
  done < <(find "$tmp/wallpapers" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) -print0)

  rm -rf "$tmp"

  if ((count > 0)); then
    log_success "Added $count wallpaper(s) to $WALLPAPER_DIR"
  else
    log_warning "Repo cloned but no new image files were copied (repo may still be empty)"
  fi
  return 0
}

ensure_wallpaper_daemon() {
  if pgrep -f "waypaper-engine.*daemon" >/dev/null 2>&1; then
    return 0
  fi
  if command -v waypaper-engine >/dev/null 2>&1; then
    log_status "Starting waypaper-engine daemon…"
    waypaper-engine daemon &>/dev/null &
    sleep 1.5
  fi
}

apply_initial_wallpaper() {
  local default_wp="$WALLPAPER_DIR/default.png"
  if [[ ! -f "$default_wp" ]]; then
    default_wp="$(find "$WALLPAPER_DIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | head -1)"
  fi
  [[ -n "${default_wp:-}" && -f "$default_wp" ]] || {
    log_warning "No wallpaper found in $WALLPAPER_DIR — skip initial matugen/theming"
    return 0
  }

  ensure_wallpaper_daemon

  if [[ -f "$HYPR_DIR/lib/scripts/default_wp.sh" ]]; then
    log_status "Applying initial wallpaper and generating matugen theme…"
    SKIP_WALLPAPER=0 bash "$HYPR_DIR/lib/scripts/default_wp.sh" || log_warning "default_wp.sh finished with warnings"
    return 0
  fi

  log_status "Applying wallpaper: $(basename "$default_wp")"
  if command -v matugen >/dev/null 2>&1; then
    matugen image "$default_wp" || log_warning "matugen exited non-zero"
  fi
  if command -v waypaper >/dev/null 2>&1; then
    waypaper --wallpaper "$default_wp" --apply >/dev/null 2>&1 \
      || waypaper --wallpaper "$default_wp" >/dev/null 2>&1 \
      || log_warning "waypaper could not apply wallpaper"
  fi
}

# --- Main ---
install_wallpaper_packages || exit 1
ensure_wallpaper_dir

echo ""
echo "The Waypaper Engine uses directory ~/Pictures/Wallpapers."
echo "You can add your own Wallpapers or download the HyprGruv Wallpaper Repo."
echo ""
read -rp "Press Enter to download Wallpapers, or q to quit wallpaper setup: " choice

if [[ "${choice,,}" == "q" ]]; then
  log_status "Wallpaper setup skipped (packages remain installed)."
  declare -F mark_completed >/dev/null 2>&1 && mark_completed "Wallpaper setup"
  declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_repo_downloaded" "skipped"
  exit 0
fi

download_wallpaper_repo || true
apply_initial_wallpaper

declare -F mark_completed >/dev/null 2>&1 && mark_completed "Wallpaper setup"
declare -F save_choice >/dev/null 2>&1 && save_choice "wallpaper_repo_downloaded" "yes"
log_success "Wallpaper setup complete"
sleep 0.5