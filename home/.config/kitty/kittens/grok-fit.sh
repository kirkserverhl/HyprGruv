#!/usr/bin/env bash
# Collapse kitty window padding/margin while Grok's TUI owns the window.
# Padding sits outside the cell grid, so Grok cannot paint it.
set -euo pipefail

usage() {
  echo "usage: $0 on|off" >&2
  exit 2
}

is_kitty() {
  [[ -n "${KITTY_PID:-}" || "${TERM:-}" == *kitty* || "${TERMINAL:-}" == kitty ]]
}

kitty_cmd() {
  if [[ -n "${KITTY_LISTEN_ON:-}" ]]; then
    kitten @ --to "$KITTY_LISTEN_ON" "$@"
  else
    kitten @ "$@"
  fi
}

fit_on() {
  is_kitty || return 0
  local -a match=()
  [[ -n "${KITTY_WINDOW_ID:-}" ]] && match=(--match "id:${KITTY_WINDOW_ID}")
  kitty_cmd set-spacing "${match[@]}" padding=0 margin=0 >/dev/null
}

fit_off() {
  is_kitty || return 0
  local -a match=()
  [[ -n "${KITTY_WINDOW_ID:-}" ]] && match=(--match "id:${KITTY_WINDOW_ID}")
  kitty_cmd set-spacing "${match[@]}" padding=default margin=default >/dev/null
}

case "${1:-}" in
  on) fit_on ;;
  off) fit_off ;;
  *) usage ;;
esac
