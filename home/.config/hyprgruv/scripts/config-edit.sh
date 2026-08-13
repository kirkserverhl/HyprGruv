#!/usr/bin/env bash
# config-edit — rofi picker for rice + XDG config files.
# Same chrome as waybar-layout-switcher. Bound to Super+Alt+E.
#
#   config-edit           interactive picker
#   config-edit --list    print menu entries (no rofi)
#   config-edit --help
set -uo pipefail

CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
SCRIPTS="${CFG}/hyprgruv/scripts"
IGNORE_DEFAULT="${CFG}/hyprgruv/config-edit.ignore"
IGNORE_USER="${CFG}/.configignore"
ROFI_CONF="${CFG}/rofi/config-configs.rasi"
[[ -f "$ROFI_CONF" ]] || ROFI_CONF="${CFG}/rofi/config-compact.rasi"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
LOG="${STATE_DIR}/config-edit.log"
NOTIFY="${NOTIFY:-notify-send}"

LIST_ONLY=0
case "${1:-}" in
  -h|--help)
    cat <<'EOF'
config-edit — rofi picker for rice + XDG config files.
Same chrome as waybar-layout-switcher. Bound to Super+Alt+E.

  config-edit           interactive picker
  config-edit --list    print menu entries (no rofi)
  config-edit --help

Ignore file: ~/.config/hyprgruv/config-edit.ignore
User extras: ~/.config/.configignore
EOF
    exit 0
    ;;
  --list|-l)
    LIST_ONLY=1
    ;;
esac

mkdir -p "$STATE_DIR"

notify() {
  [[ "$NOTIFY" == ":" ]] && return 0
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send "$@" 2>/dev/null || true
}

fail() {
  echo "config-edit: $*" >&2
  echo "$(date -Iseconds) FAIL: $*" >>"$LOG" 2>/dev/null || true
  notify "Edit Config" "$*" -u critical -t 4000
  exit 1
}

log() {
  echo "$(date -Iseconds) $*" >>"$LOG" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# gitignore-style matcher (Python stdlib). Prints names that should be ignored.
# ---------------------------------------------------------------------------
IGNORE_PY="${SCRIPTS}/config-edit-ignore.py"

filter_ignored() {
  local root="$1"
  [[ -f "$IGNORE_PY" ]] || return 0
  python3 "$IGNORE_PY" "$root" "$IGNORE_DEFAULT" "$IGNORE_USER"
  return 0
}

# ---------------------------------------------------------------------------
# Pinned rice configs (label, primary, extras…)
# ---------------------------------------------------------------------------
LABELS=()
PRIMARY=()
EXTRAS=()   # pipe-separated extra paths
KINDS=()    # pinned | scanned | action

pin() {
  local label="$1" primary="$2"
  shift 2
  [[ -e "$primary" || -L "$primary" ]] || return 0
  local extras="" e
  for e in "$@"; do
    [[ -e "$e" || -L "$e" ]] || continue
    extras+="${extras:+|}$e"
  done
  LABELS+=("$label")
  PRIMARY+=("$primary")
  EXTRAS+=("$extras")
  KINDS+=("pinned")
}

build_pinned() {
  # Sample script apps first — real paths for this rice (EndeavourOS / HyprGruv)
  pin "Hyprland" "$CFG/hypr/hyprland.lua" \
    "$CFG/hypr/conf/keybinds.lua" \
    "$CFG/hypr/conf/windowrules.lua" \
    "$CFG/hypr/conf/monitors.lua" \
    "$CFG/hypr/conf/decorations.lua" \
    "$CFG/hypr/conf/animations.lua" \
    "$CFG/hypr/conf/input.lua" \
    "$CFG/hypr/conf/autostart.lua" \
    "$CFG/hypr/conf/env.lua" \
    "$CFG/hypr/conf/general.lua" \
    "$CFG/hypr/conf/layerrules.lua" \
    "$CFG/hypr/conf/workspaces.lua"

  pin "Kitty" "$CFG/kitty/kitty.conf" \
    "$CFG/kitty/kitty-dropdown.conf" \
    "$CFG/kitty/kitty-lap.conf" \
    "$CFG/kitty/startup.conf"

  pin "Waybar" "$CFG/waybar/config.jsonc" \
    "$CFG/waybar/style.css"

  pin "SwayNC" "$CFG/swaync/config.json" \
    "$CFG/swaync/style.css"

  pin "Hypridle" "$CFG/hypr/hypridle.conf"
  pin "Hyprlock" "$CFG/hypr/hyprlock/hyprlock.conf"
  pin "Hyprshot" "$CFG/hypr/hyprshot.conf"

  pin "Neovim" "$CFG/nvim/init.lua" \
    "$CFG/nvim/lua/config/options.lua" \
    "$CFG/nvim/lua/config/keymaps.lua" \
    "$CFG/nvim/lua/config/lazy.lua" \
    "$CFG/nvim/lua/config/autocmds.lua" \
    "$CFG/nvim/lua/plugins"

  pin "Fish" "$CFG/fish/config.fish" \
    "$CFG/fish/aliases.fish"

  pin "Starship" "$CFG/starship.toml" \
    "$CFG/starship/theme.sh"

  pin "Tmux" "$CFG/tmux/tmux.conf" \
    "$CFG/tmux/tmux.conf.local"

  pin "Alacritty" "$CFG/alacritty/alacritty.toml"
  pin "Fastfetch" "$CFG/fastfetch/config.jsonc"

  pin "Rofi" "$CFG/rofi/config-launcher.rasi" \
    "$CFG/rofi/config-compact.rasi" \
    "$CFG/rofi/config-configs.rasi" \
    "$CFG/rofi/config-themes.rasi" \
    "$CFG/rofi/config-settings.rasi" \
    "$CFG/rofi/config-cliphist.rasi"

  pin "Yazi" "$CFG/yazi/yazi.toml" \
    "$CFG/yazi/keymap.toml" \
    "$CFG/yazi/theme.toml" \
    "$CFG/yazi/init.lua"

  pin "wlogout" "$CFG/wlogout/layout" \
    "$CFG/wlogout/style.css"

  pin "nwg-drawer" "$CFG/nwg-drawer/drawer.css"
  pin "nwg-look" "$CFG/nwg-look/config"
  pin "Thunar" "$CFG/Thunar/uca.xml" \
    "$CFG/Thunar/accels.scm"
  pin "Obsidian" "$CFG/obsidian/obsidian.json"
  pin "Waypaper engine" "$CFG/waypaper-engine/config.toml"
  pin "Autostart" "$CFG/autostart"

  pin "Matugen" "$CFG/matugen/config.toml"
  pin "Colorschemes" "$CFG/colorschemes/themes.registry.json" \
    "$CFG/colorschemes/apply-theme.sh"
  pin "quickshell" "$CFG/quickshell/Colors.qml"
  pin "KDE Material You" "$CFG/kde-material-you-colors/config.conf"

  pin "Waypaper" "$CFG/waypaper/config.ini"
  pin "GTK 3" "$CFG/gtk-3.0/settings.ini" \
    "$CFG/gtk-3.0/gtk.css"
  pin "GTK 4" "$CFG/gtk-4.0/settings.ini" \
    "$CFG/gtk-4.0/gtk.css"
  pin "Qt6ct" "$CFG/qt6ct/qt6ct.conf"
  pin "Qt5ct" "$CFG/qt5ct/qt5ct.conf"
  pin "Kvantum" "$CFG/Kvantum/kvantum.kvconfig"
  pin "Fontconfig" "$CFG/fontconfig/fonts.conf"
  pin "xsettingsd" "$CFG/xsettingsd/xsettingsd.conf"

  pin "HyprGruv settings" "$CFG/settings/fonts.sh" \
    "$CFG/settings/editor.sh" \
    "$CFG/settings/terminal.sh" \
    "$CFG/settings/browser.sh" \
    "$CFG/settings/filemanager.sh"

  pin "MPV" "$CFG/mpv/mpv.conf" \
    "$CFG/mpv/input.conf"
  pin "btop" "$CFG/btop/btop.conf"
  pin "bpytop" "$CFG/bpytop/bpytop.conf"
  pin "htop" "$CFG/htop/htoprc"
  pin "cava" "$CFG/cava/config"
  pin "bat" "$CFG/bat/bat.conf"
  pin "Atuin" "$CFG/atuin/config.toml"
  pin "Pacseek" "$CFG/pacseek/config.json"
  pin "hypremoji" "$CFG/hypremoji/config.json" \
    "$CFG/hypremoji/hypremoji.conf"
  pin "Vesktop" "$CFG/vesktop/settings.json"
  pin "VSCodium" "$CFG/VSCodium/User/settings.json"
  pin "Handlr" "$CFG/handlr/handlr.toml"
  pin "Portals" "$CFG/xdg-desktop-portal/hyprland-portals.conf" \
    "$CFG/xdg-desktop-portal-termfilechooser/config"
  pin "Environment" "$CFG/environment.d/hyprgruv-dark.conf"
  pin "MIME apps" "$CFG/mimeapps.list"

  pin "Chrome flags" "$CFG/chrome-flags.conf"
  pin "Brave flags" "$CFG/brave-flags.conf"
  pin "Electron flags" "$CFG/electron-flags.conf"
  pin "Chrome theme CSS" "$CFG/chrome/matugen-theme.user.css"
  pin "Brave theme CSS" "$CFG/brave/matugen-theme.user.css"

  pin "Grok" "$HOME/.grok/config.toml"
  pin "Git" "$HOME/.gitconfig"
  pin "Bash" "$HOME/.bashrc"
  pin "Zsh" "$HOME/.zshrc"

  pin "This picker" "$SCRIPTS/config-edit.sh" \
    "$IGNORE_DEFAULT" \
    "$CFG/rofi/config-configs.rasi"
}

# Top-level ~/.config names already covered by pinned entries (skip in sweep)
pinned_basenames() {
  local i p base
  local -a paths extra_paths
  for i in "${!PRIMARY[@]}"; do
    [[ "${KINDS[$i]}" == pinned ]] || continue
    paths=("${PRIMARY[$i]}")
    if [[ -n "${EXTRAS[$i]}" ]]; then
      IFS='|' read -ra extra_paths <<< "${EXTRAS[$i]}"
      paths+=("${extra_paths[@]}")
    fi
    for p in "${paths[@]}"; do
      [[ "$p" == "$CFG"/* ]] || continue
      base="${p#"$CFG"/}"
      printf '%s\n' "${base%%/*}"
    done
  done | sort -u
}

looks_like_config() {
  local f="$1" b
  b="$(basename "$f")"
  case "$b" in
    config|config.*|*.conf|*.toml|*.json|*.jsonc|*.ini|*.rasi|*.lua|*.css|*.yml|*.yaml|settings.*|init.lua)
      return 0
      ;;
  esac
  return 1
}

find_primary() {
  local dir="$1"
  local base name f
  base="$(basename "$dir")"
  for name in \
    "$base.conf" "$base.toml" "$base.json" "$base.jsonc" "$base.ini" \
    config config.json config.jsonc config.toml config.ini config.conf \
    init.lua hyprland.lua kitty.conf settings.json settings.ini settings.toml \
    style.css
  do
    f="$dir/$name"
    if [[ -f "$f" || -L "$f" ]]; then
      printf '%s' "$f"
      return 0
    fi
  done
  # first reasonably-named file at depth 1
  while IFS= read -r f; do
    looks_like_config "$f" || continue
    printf '%s' "$f"
    return 0
  done < <(find "$dir" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -printf '%p\n' 2>/dev/null | sort)
  printf '%s' "$dir"
}

gather_dir_configs() {
  local dir="$1"
  find "$dir" -mindepth 1 -maxdepth 2 \( -type f -o -type l \) -printf '%p\n' 2>/dev/null \
    | sort \
    | while IFS= read -r f; do
        looks_like_config "$f" || continue
        printf '%s\n' "$f"
      done
}

sweep_config() {
  [[ -d "$CFG" ]] || return 0
  local taken ignored_list entry name path primary extras files f
  taken="$(pinned_basenames)"
  ignored_list="$(
    find "$CFG" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort | filter_ignored "$CFG"
  )"

  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    printf '%s\n' "$taken" | grep -Fxq "$name" && continue
    printf '%s\n' "$ignored_list" | grep -Fxq "$name" && continue

    path="$CFG/$name"
    if [[ -f "$path" || -L "$path" && ! -d "$path" ]]; then
      pin "$name" "$path"
      KINDS[-1]="scanned"
      continue
    fi
    [[ -d "$path" ]] || continue

    primary="$(find_primary "$path")"
    extras=""
    while IFS= read -r f; do
      [[ -n "$f" && "$f" != "$primary" ]] || continue
      extras+="${extras:+|}$f"
    done < <(gather_dir_configs "$path")

    LABELS+=("$name")
    PRIMARY+=("$primary")
    EXTRAS+=("$extras")
    KINDS+=("scanned")
  done < <(find "$CFG" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort)
}

pretty_file() {
  local f="$1"
  local rel="$f"
  [[ "$f" == "$CFG"/* ]] && rel="${f#"$CFG"/}"
  [[ "$f" == "$HOME"/* ]] && rel="~/${f#"$HOME"/}"
  printf '%s' "$rel"
}

# ---------------------------------------------------------------------------
# Editor launch (floating kitty, same class as hyprgruv-settings)
# ---------------------------------------------------------------------------
resolve_editor() {
  if [[ -x "$SCRIPTS/editor.sh" ]]; then
    "$SCRIPTS/editor.sh" --print
    return
  fi
  for c in nvim vim nano vi; do
    command -v "$c" >/dev/null 2>&1 && { printf '%s' "$c"; return; }
  done
  printf '%s' vi
}

resolve_terminal() {
  if [[ -x "$SCRIPTS/terminal.sh" ]]; then
    "$SCRIPTS/terminal.sh" --print
    return
  fi
  for c in kitty alacritty foot wezterm; do
    command -v "$c" >/dev/null 2>&1 && { printf '%s' "$c"; return; }
  done
  printf '%s' xterm
}

open_path() {
  local path="$1" title="${2:-Config}"
  local editor term
  editor="$(resolve_editor)"
  term="$(resolve_terminal)"

  if [[ ! -e "$path" && ! -L "$path" ]]; then
    fail "Path gone: $path"
  fi

  log "open title=$title path=$path editor=$editor"
  notify "Edit Config" "$title" -t 1500

  # Scrub noisy GTK debug env the same way other hyprgruv launchers do.
  local -a clean=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)

  case "$(basename "$term")" in
    kitty)
      exec "${clean[@]}" "$term" --class dotfiles-floating \
        --title "Edit Config — $title" \
        --override initial_window_width=120c \
        --override initial_window_height=40c \
        -e "$editor" "$path"
      ;;
    alacritty)
      exec "${clean[@]}" "$term" --class dotfiles-floating \
        -T "Edit Config — $title" -e "$editor" "$path"
      ;;
    *)
      exec "${clean[@]}" "$term" -e "$editor" "$path"
      ;;
  esac
}

open_yazi() {
  local dir="$1"
  if [[ -x "$SCRIPTS/yazi.sh" ]]; then
    # yazi.sh does not take a start dir; launch kitty yazi there ourselves
    :
  fi
  if command -v kitty >/dev/null 2>&1 && command -v yazi >/dev/null 2>&1; then
    exec env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE= \
      kitty --class yazi --title "Configs — $(basename "$dir")" -e yazi "$dir"
  fi
  open_path "$dir" "$(basename "$dir")"
}

# ---------------------------------------------------------------------------
# Rofi
# ---------------------------------------------------------------------------
rofi_pick() {
  local prompt="$1"
  shift
  if (( LIST_ONLY )); then
    printf '%s\n' "$@"
    return 0
  fi
  command -v rofi >/dev/null 2>&1 || fail "rofi not found in PATH"
  printf '%s\n' "$@" | rofi -dmenu -i -p "$prompt" -config "$ROFI_CONF" || true
}

submenu_labels() {
  local primary="$1" extras="$2"
  pretty_file "$primary"
  if [[ -n "$extras" ]]; then
    local e
    local -a extra_paths
    IFS='|' read -ra extra_paths <<< "$extras"
    for e in "${extra_paths[@]}"; do
      pretty_file "$e"
    done
  fi
  printf '%s\n' "Open folder"
  printf '%s\n' "Browse with yazi"
}

resolve_submenu() {
  local choice="$1" primary="$2" extras="$3"
  case "$choice" in
    "Open folder")
      local dir="$primary"
      [[ -f "$primary" || -L "$primary" ]] && dir="$(dirname "$primary")"
      printf '%s' "$dir"
      return
      ;;
    "Browse with yazi")
      printf '%s' "__yazi__"
      return
      ;;
  esac
  local p
  p="$(pretty_file "$primary")"
  if [[ "$choice" == "$p" ]]; then
    printf '%s' "$primary"
    return
  fi
  if [[ -n "$extras" ]]; then
    local e
    local -a extra_paths
    IFS='|' read -ra extra_paths <<< "$extras"
    for e in "${extra_paths[@]}"; do
      if [[ "$choice" == "$(pretty_file "$e")" ]]; then
        printf '%s' "$e"
        return
      fi
    done
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
build_pinned
sweep_config

ACTIONS=("Browse ~/.config" "Edit ignore list")

if (( LIST_ONLY )); then
  local_i=0
  for local_i in "${!LABELS[@]}"; do
    printf '%s | %s | %s\n' "${KINDS[$local_i]}" "${LABELS[$local_i]}" "${PRIMARY[$local_i]}"
  done
  printf '%s | %s\n' "action" "Browse ~/.config"
  printf '%s | %s\n' "action" "Edit ignore list"
  exit 0
fi

log "start pid=$$ entries=${#LABELS[@]}"

menu_lines=()
for i in "${!LABELS[@]}"; do
  if [[ "${KINDS[$i]}" == scanned ]]; then
    menu_lines+=("· ${LABELS[$i]}")
  else
    menu_lines+=("${LABELS[$i]}")
  fi
done
menu_lines+=("${ACTIONS[@]}")

chosen="$(rofi_pick "Edit Config" "${menu_lines[@]}")"
chosen="${chosen//$'\r'/}"
chosen="${chosen//$'\n'/}"

if [[ -z "${chosen:-}" ]]; then
  log "cancelled"
  exit 0
fi

# Strip scan prefix
display="$chosen"
[[ "$display" == "· "* ]] && display="${display#· }"

case "$display" in
  "Browse ~/.config")
    open_yazi "$CFG"
    ;;
  "Edit ignore list")
    extra=()
    [[ -f "$IGNORE_USER" ]] || extra=()
    if [[ -f "$IGNORE_USER" ]]; then
      open_path "$IGNORE_USER" "User ignore"
    else
      open_path "$IGNORE_DEFAULT" "Ignore list"
    fi
    ;;
esac

idx=""
for i in "${!LABELS[@]}"; do
  if [[ "${LABELS[$i]}" == "$display" ]]; then
    idx="$i"
    break
  fi
done
[[ -n "$idx" ]] || fail "Unknown entry: $display"

label="${LABELS[$idx]}"
primary="${PRIMARY[$idx]}"
extras="${EXTRAS[$idx]}"

target="$primary"
if [[ -n "$extras" || -d "$primary" ]]; then
  mapfile -t sub < <(submenu_labels "$primary" "$extras")
  sub_choice="$(rofi_pick "$label" "${sub[@]}")"
  sub_choice="${sub_choice//$'\r'/}"
  sub_choice="${sub_choice//$'\n'/}"
  [[ -n "${sub_choice:-}" ]] || exit 0
  resolved="$(resolve_submenu "$sub_choice" "$primary" "$extras")"
  if [[ "$resolved" == "__yazi__" ]]; then
    dir="$primary"
    [[ -f "$primary" || -L "$primary" ]] && dir="$(dirname "$primary")"
    open_yazi "$dir"
  fi
  target="$resolved"
fi

open_path "$target" "$label"
