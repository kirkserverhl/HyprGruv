#!/usr/bin/env bash
# terminal.sh — launch the user's preferred terminal (Super+Return, scratchpad, etc.)
set -euo pipefail

SETTINGS_FILE="${HOME}/.config/settings/terminal.sh"
DEFAULTS_FILE="${HYPRGRUV_DIR:-${HOME}/.hyprgruv}/defaults/terminal.sh"

resolve_terminal() {
  local term=""

  if [[ -f "$SETTINGS_FILE" ]]; then
    term="$(tr -d '[:space:]' < "$SETTINGS_FILE")"
  fi

  if [[ -z "$term" && -x "$DEFAULTS_FILE" ]]; then
    term="$("$DEFAULTS_FILE" 2>/dev/null || true)"
  fi

  [[ -n "$term" ]] || term="kitty"

  for candidate in "$term" ghostty alacritty foot wezterm; do
    if command -v "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done

  echo "xterm"
}

TERM_CMD="$(resolve_terminal)"

if [[ "${1:-}" == "--print" ]]; then
  echo "$TERM_CMD"
  exit 0
fi

exec "$TERM_CMD" "$@"