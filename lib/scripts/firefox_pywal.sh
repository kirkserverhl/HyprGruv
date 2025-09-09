#!/usr/bin/env bash
# firefox_pywal_setup.sh — guide user through Firefox + Pywal integration with gum
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------
# Resolve repo root from modules/ and load helpers (optional)
# ------------------------------------------------------------
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -f "$HYPR_DIR/lib/common.sh" ]] && source "$HYPR_DIR/lib/common.sh" || {
  # Fallback log helpers
  log_status(){ printf "\e[38;2;215;153;33m[INFO]\e[0m %s\n" "$*"; }
  log_success(){ printf "\e[38;2;142;192;124m[SUCCESS]\e[0m %s\n" "$*"; }
  log_error(){ printf "\e[38;2;204;36;29m[ERROR]\e[0m %s\n" "$*"; }
}
[[ -f "$HYPR_DIR/lib/state.sh"  ]] && source "$HYPR_DIR/lib/state.sh"  || true

# ------------------------------------------------------------
# Gum theming (compatible with your shell.sh)
# ------------------------------------------------------------
export GUM_CONFIRM_PROMPT="${GUM_CONFIRM_PROMPT:-? Continue? }"
export GUM_CONFIRM_SELECTED_BACKGROUND="${GUM_CONFIRM_SELECTED_BACKGROUND:-#458588}"
export GUM_CONFIRM_SELECTED_FOREGROUND="${GUM_CONFIRM_SELECTED_FOREGROUND:-#0f1010}"
export GUM_CONFIRM_UNSELECTED_BACKGROUND="${GUM_CONFIRM_UNSELECTED_BACKGROUND:-#0f1010}"
export GUM_CONFIRM_UNSELECTED_FOREGROUND="${GUM_CONFIRM_UNSELECTED_FOREGROUND:-#282828}"
export GUM_INPUT_CURSOR_FOREGROUND="${GUM_INPUT_CURSOR_FOREGROUND:-#282828}"
export GUM_INPUT_PROMPT_FOREGROUND="${GUM_INPUT_PROMPT_FOREGROUND:-#8FC17B}"
export GUM_SPIN_SPINNER_FOREGROUND="${GUM_SPIN_SPINNER_FOREGROUND:-#749D91}"

#display_header() { command -v figlet >/dev/null && figlet -f ~/.local/share/fonts/Graffiti.flf "$1" || echo "=== $1 ==="; }

ensure_cmd() {
  local c="$1" install_msg="$2" pkg="$3"
  if ! command -v "$c" >/dev/null 2>&1; then
    log_status "$install_msg"
    if command -v yay >/dev-null 2>&1; then
      yay -S --needed --noconfirm "$pkg"
    else
      sudo pacman -S --needed --noconfirm "$pkg"
    fi
  fi
}

# ------------------------------------------------------------
# Prereqs
# ------------------------------------------------------------
ensure_cmd gum "Installing gum…" gum
ensure_cmd firefox "Installing Firefox…" firefox

display_header "FIREFOX + PYWAL"

# ------------------------------------------------------------
# Pick Firefox profile (parse profiles.ini)
# ------------------------------------------------------------
choose_firefox_profile() {
  local ini="$HOME/.mozilla/firefox/profiles.ini"
  [[ -f "$ini" ]] || { log_error "Firefox profile not found (run Firefox once to create a profile)."; exit 1; }

  # Read all Path= lines under [Profile*]
  mapfile -t paths < <(awk '
    /^\[Profile/ {inprof=1; p=""; def="0"}
    /^Path=/ && inprof { p=substr($0,6) }
    /^Default=/ && inprof { def=substr($0,9) }
    /^\[/ && $0!~"^\\[Profile" { inprof=0 }
    inprof && p!="" { print p "|" def; p=""; def="0" }
  ' "$ini" | sort -u)

  local defaults=()
  local candidates=()
  for line in "${paths[@]}"; do
    IFS='|' read -r p d <<<"$line"
    local abs="$HOME/.mozilla/firefox/$p"
    [[ -d "$abs" ]] || continue
    if [[ "$d" == "1" ]]; then
      defaults+=("$abs")
    fi
    candidates+=("$abs")
  done

  local chosen=""
  if [[ ${#defaults[@]} -eq 1 ]]; then
    chosen="${defaults[0]}"
  elif [[ ${#defaults[@]} -gt 1 ]]; then
    chosen="$(printf "%s\n" "${defaults[@]}" | gum choose --limit=1 --header="Multiple default profiles found:")"
  else
    chosen="$(printf "%s\n" "${candidates[@]}" | gum choose --limit=1 --header="Choose your Firefox profile:")"
  fi

  [[ -n "$chosen" ]] || { log_error "No profile selected."; exit 1; }
  echo "$chosen"
}

PROFILE_DIR="$(choose_firefox_profile)"
CHROME_DIR="$PROFILE_DIR/chrome"
mkdir -p "$CHROME_DIR"

# ------------------------------------------------------------
# Symlink userContent.css
# ------------------------------------------------------------
WAL_CSS="$HOME/.cache/wal/userContent.css"
[[ -f "$WAL_CSS" ]] || { log_status "Creating empty $WAL_CSS"; mkdir -p "$(dirname "$WAL_CSS")"; : > "$WAL_CSS"; }
TARGET_CSS="$CHROME_DIR/userContent.css"

ln -sf "$WAL_CSS" "$TARGET_CSS"
log_success "Linked $TARGET_CSS → $WAL_CSS"

# Helper to show a 3-option step
step_menu() {
  local title="$1" open_cmd="$2"
  while true; do
    echo -e "\n$title"
    local choice
    choice="$(gum choose "Open in Firefox" "Next" "Skip" --limit=1)"
    case "$choice" in
      "Open in Firefox")
        eval "$open_cmd" >/dev/null 2>&1 &
        gum spin --spinner dot --title "Launching…" -- sleep 1
        ;;
      "Next")
        return 0
        ;;
      "Skip")
        log_status "Skipped: $title"
        return 0
        ;;
    esac
  done
}

# ------------------------------------------------------------
# STEP 1: Enable user CSS (about:config toggle)
# ------------------------------------------------------------
step_menu \
  "Set about:config → toolkit.legacyUserProfileCustomizations.stylesheets = true" \
  'firefox "about:config"'

# ------------------------------------------------------------
# STEP 2: Install PyWalFox extension (AMO)
# ------------------------------------------------------------
step_menu \
  "Install PyWalFox for Firefox (opens AMO page)" \
  'firefox "https://addons.mozilla.org/en-US/firefox/addon/pywalfox/"'

# ------------------------------------------------------------
# STEP 3: Install Dark Reader Pywal XPI from repo
# ------------------------------------------------------------
XPI_PATH="${HYPR_DIR}/home/opt/darkreader-pywal/darkreader.xpi"
if [[ -f "$XPI_PATH" ]]; then
  step_menu \
    "Install Dark Reader Pywal (local XPI)" \
    "firefox \"$XPI_PATH\""
else
  log_status "Dark Reader XPI not found at: $XPI_PATH (skipping)"
fi

# ------------------------------------------------------------
# STEP 4: Guide through Dark Reader settings
# ------------------------------------------------------------
step_menu \
  "Open Add-ons Manager to finish Dark Reader tweaks:
  - Open Dark Reader → Dev Tools → \"Preview new design\"
  - Open Dark Reader → Settings → Advanced → enable \"Synchronize site fixes\"" \
  'firefox "about:addons"'

# ------------------------------------------------------------
# STEP 5: Restart Firefox to apply theme
# ------------------------------------------------------------
echo ""
if gum confirm "Close Firefox (if running) and then continue?"; then
  log_success "Firefox theme steps completed."
else
  log_status "You can re-run this module anytime."
fi

# Optional short pause / clean end
gum spin --spinner dot --title "All set!" -- sleep 1
