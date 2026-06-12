#!/usr/bin/env bash
# 01-packages.sh — install base/desktop packages for Hyprgruv
#
# Uses a curated "necessary only" list (lean Hyprland + terminal workflow + Thunar).
# Pure Arch (no EndeavourOS/KDE/Plasma remnants).
# See the package sets section below for the full rationale and grouping.
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from inside modules/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/common.sh"
# shellcheck source=/dev/null
source "$HYPR_DIR/lib/state.sh"

say() { echo -e "$*"; }

# -------------------- guards & repairs --------------------
sanitize_pacman_conf() {
    local conf="/etc/pacman.conf"
    [[ -f "$conf" ]] || return 0

    # Normalize CRLF → LF
    sudo sed -i 's/\r$//' "$conf"

    # Comment any stray `Server =` lines that appear while in [options]
    sudo awk '
    BEGIN{inopt=0}
    /^\[options\]/{inopt=1; print; next}
    /^\[/{inopt=0; print; next}
    { if(inopt && $0 ~ /^[[:space:]]*Server[[:space:]]*=/){print "#" $0}else{print}}
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
    sudo mv "$conf.tmp.$$" "$conf"

    # Ensure core/extra exist (defensive on fresh images)
    grep -q '^\[core\]' "$conf" || echo -e "\n[core]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null
    grep -q '^\[extra\]' "$conf" || echo -e "\n[extra]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a "$conf" >/dev/null
}

ensure_pacman_keyring() {
    # If listing keys fails (or perms wrong), reinit the keyring from scratch
    if ! sudo pacman-key --list-keys >/dev/null 2>&1; then
        log_status "Reinitializing pacman keyring"
        sudo rm -rf /etc/pacman.d/gnupg
        sudo pacman-key --init
        sudo pacman-key --populate archlinux
    fi
}

ensure_yay() {
    if command -v yay >/dev/null 2>&1; then return 0; fi
    log_status "Installing yay (AUR helper)…"
    sudo pacman -Syu --needed --noconfirm git base-devel
    tmpdir="$(mktemp -d)"
    pushd "$tmpdir" >/dev/null
    git clone https://aur.archlinux.org/yay.git
    pushd yay >/dev/null
    makepkg -si --noconfirm
    popd >/dev/null
    popd >/dev/null
    rm -rf "$tmpdir"
    log_success "yay installed."
}

# Comment out duplicate repo sections in /etc/pacman.conf, keeping the first.
dedupe_pacman_repos() {
    local conf="/etc/pacman.conf"
    [[ -f "$conf" ]] || return 0

    log_status "De-duplicating repository sections in $conf"
    sudo awk '
    function ltrim(s){ sub(/^[ \t\r\n]+/, "", s); return s }
    function rtrim(s){ sub(/[ \t\r\n]+$/, "", s); return s }
    function trim(s){ return rtrim(ltrim(s)) }

    BEGIN{ insec=0; secname=""; }
    # match [repo-name]
    /^\[[^]]+\][ \t]*$/{
      line=$0
      name=$0; sub(/^\[/, "", name); sub(/\][ \t]*$/, "", name)
      name=trim(name)
      if(seen[name] == 1){
        insec=2;    # duplicate section: comment until next section
        print "# hyprgruv-dup: " line
        next
      } else {
        seen[name]=1
        insec=1
        print line
        next
      }
    }
    # any new section header ends duplicate commenting
    /^\[/{
      insec=1
      print
      next
    }
    {
      if(insec==2){
        # we are inside a duplicate section: comment the line (preserve content)
        if($0 ~ /^# hyprgruv-dup: /){ print $0 } else { print "# hyprgruv-dup: " $0 }
      } else {
        print
      }
    }
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
    sudo mv "$conf.tmp.$$" "$conf"
}

# Temporarily disable [chaotic-aur] if its mirrorlist isn’t present yet.
disable_chaotic_if_unready() {
    local conf="/etc/pacman.conf"
    local ml="/etc/pacman.d/chaotic-mirrorlist"

    grep -q '^\[chaotic-aur\]' "$conf" 2>/dev/null || return 0
    [[ -f "$ml" ]] && return 0

    log_status "Chaotic repo referenced but not ready — disabling it until chaotic.sh runs"
    sudo awk '
    BEGIN{insec=0}
    /^\[chaotic-aur\]/{insec=1; if($0 !~ /^#/) print "# hyprgruv: " $0; else print; next}
    /^\[/ && insec==1 {insec=0; print; next}
    {
      if(insec==1) {
        if($0 !~ /^#/) print "# hyprgruv: " $0; else print
      } else {
        print
      }
    }
  ' "$conf" | sudo tee "$conf.tmp.$$" >/dev/null
    sudo mv "$conf.tmp.$$" "$conf"
}

ensure_chaotic_ready() {
    local conf="/etc/pacman.conf"
    local ml="/etc/pacman.d/chaotic-mirrorlist"

    # only act if pacman.conf references chaotic-aur
    grep -q '^\[chaotic-aur\]' "$conf" 2>/dev/null || return 0

    if [[ -f "$ml" ]]; then
        # de-prefer known flaky mirrors
        sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true
        return 0
    fi

    log_status "Chaotic listed in pacman.conf; preparing keyring + mirrorlist"
    # keys
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || true
    sudo pacman-key --lsign-key 3056513887B78AEB || true

    # packages (keyring + mirrorlist)
    sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    # sanitize mirrorlist if it now exists
    [[ -f "$ml" ]] && sudo sed -i -E 's|^[[:space:]]*Server[[:space:]]*=.*warp\.dev.*|# &|' "$ml" || true

    # clear stale DB
    sudo rm -f /var/lib/pacman/sync/chaotic-aur.db* || true
}

# -------------------- package sets --------------------
#
# Curated "necessary" packages only.
#
# Rules followed here:
#   - Lean core: terminal workflow (zsh + lf + neovim + starship) + Hyprland (no KDE/Plasma)
#   - Thunar as primary file manager (no Dolphin/KDE file integration)
#   - No full Plasma bloat, no EndeavourOS-specific packages
#   - Browsers: brave (primary), google-chrome, firefox (fallback)
#   - Terminals: kitty (main), ghostty (secondary)
#   - Screenshots: hyprshot
#   - Authentication: gnome-keyring + polkit-gnome
#   - Greeter: sddm (no KDE)
#   - Other: fuzzel (launcher), libreoffice, timeshift (with separate partition)
#   - Still using pywalfox for theming
#   - Prefer pacman when possible (especially after Chaotic-AUR is enabled)
#   - Keep AUR list small — move packages to OFFICIAL_PKGS once they are available via Chaotic
#
# This list was refined from actual usage + the dots repo curation.
# Reference: ~/.dots/packages/install.sh (or the dots git repo)

OFFICIAL_PKGS=(
    # --- Bootstrap / essentials ---
    base-devel
    git
    reflector
    networkmanager

    # --- Shell & core terminal workflow ---
    zsh
    eza
    fzf
    zoxide
    bat
    trash-cli
    stow
    lf
    neovim
    lazygit
    starship

    # lf file preview support
    chafa
    mupdf-tools
    tesseract
    tesseract-data-eng
    ffmpeg
    ffmpegthumbnailer

    # --- Hyprland (lean, no full desktop, no KDE/Plasma) ---
    hyprland
    hyprpicker
    grim
    slurp
    wl-clipboard
    brightnessctl
    xdg-desktop-portal-hyprland
    xdg-desktop-portal

    # Authentication (gnome instead of hyprpolkitagent / KDE polkit)
    polkit-gnome
    gnome-keyring

    # PipeWire audio
    pipewire
    wireplumber
    pipewire-pulse
    pipewire-alsa

    # --- Theming foundation ---
    uv
    qt6ct
    papirus-icon-theme
    adw-gtk-theme
    ttf-material-symbols-variable

    # --- Daily utilities + launchers ---
    jq
    curl
    fastfetch
    btop
    duf
    dust
    ncdu
    man-db
    man-pages
    pavucontrol
    gum
    fuzzel

    # --- Terminals ---
    kitty

    # --- File manager (Thunar, no Dolphin/KDE) ---
    thunar
    thunar-volman
    thunar-archive-plugin
    thunar-media-tags-plugin
    tumbler
    gvfs

    # --- Browser (brave primary, with fallbacks) ---
    firefox

    # --- Office ---
    libreoffice-fresh

    # --- Backup (timeshift with separate partition) ---
    timeshift

    # --- Hyprgruv / personal additions ---
    # Move packages here (from AUR_PKGS) once Chaotic-AUR is enabled for faster installs.
    # yazi

    # --- Additional tools (user requested) ---
    7zip
    blueberry
    atuin
    bpytop
    cava
    clang
    cliphist
    cmatrix
    discount
    ffmpegthumbs
    htop
    imagemagick
    media-player-info
    nm-connection-editor
    pacutils
    obs-studio
    ttf-nerd-fonts-symbols
    udiskie
    zram-generator
)

AUR_PKGS=(
    # === Theming (critical for this dots/hyprgruv setup) ===
    matugen-git
    python-pywalfox          # still using pywalfox
    bibata-cursor-theme-bin

    # === Terminals ===
    ghostty-bin

    # === Browsers ===
    brave-bin
    google-chrome

    # === Screenshots ===
    hyprshot

    # === Tools declared in dots manifests ===
    opencode-bin

    # === Additional tools (user requested, AUR) ===
    displaylink
    masterpdfeditor
    otf-apple-sf-pro
    timeshift-autosnap
    udiskie-dmenu-git
    vscodium-bin
    wl-clip-persist
    wl-clipboard-history-git
    wlogout

    # === Personal / usually still AUR or preferred -git versions ===
    # Move anything below to OFFICIAL_PKGS as soon as Chaotic provides it.
    # yazi
    # zsh-thefuck-git
    # etc.
)

# -------------------- run --------------------
say "   📦️  Installing essential packages…"
sleep 0.15

disable_chaotic_if_unready

log_status "Sanitizing pacman.conf"
sanitize_pacman_conf

log_status "Ensuring pacman keyring is usable"
ensure_pacman_keyring

log_status "Preparing Chaotic-aur (if referenced)"
ensure_chaotic_ready

log_status "Refreshing system packages (pacman -Syyu)…"
sudo pacman -Syyu --noconfirm

ensure_yay

log_status "Installing official repo packages…"
sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"

dedupe_pacman_repos

log_status "Installing AUR packages…"
yay -S --needed --noconfirm "${AUR_PKGS[@]}"

ESSENTIAL_CHECK=(brave-bin ghostty-bin hyprshot python-pywalfox qt5-declarative wlogout xsettingsd displaylink masterpdfeditor otf-apple-sf-pro timeshift-autosnap udiskie-dmenu-git vscodium-bin wl-clip-persist wl-clipboard-history-git wlogout)
MISSING=()
for pkg in "${ESSENTIAL_CHECK[@]}"; do pacman -Qq "$pkg" &>/dev/null || MISSING+=("$pkg"); done
if ((${#MISSING[@]})); then
    log_status "Installing missing essentials: ${MISSING[*]}"
    yay -S --needed --noconfirm "${MISSING[@]}"
else
    say "All essential packages are already installed."
fi

sleep 0.2
mark_completed "Install packages"
