#!/usr/bin/env bash
# zoho-notify-quiet.sh — mute Zoho SwayNC toasts on a weekly Eastern window
#
# Default window (America/New_York): Sunday 17:00 → Wednesday 11:00
#
#   --apply         Set SwayNC visibility from the clock (idempotent)
#   --status        Print window + current mute state
#   --on-receive    Called by SwayNC; close this notification if quiet
#   --force-on      Mute now (until next --apply)
#   --force-off     Unmute now (until next --apply)
#   --test          Send a sample Zoho-shaped notification
#
# Matchers cover Zoho desktop apps and Chrome web notifications
# (app-name / desktop-entry / summary / body). Tune in:
#   ~/.config/zoho-notify-quiet/config
set -euo pipefail
IFS=$'\n\t'

HYPR_DIR="${HYPRGRUV_DIR:-$HOME/.hyprgruv}"
APP_NAME="Zoho quiet"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zoho-notify-quiet"
CONFIG_FILE="${CONFIG_DIR}/config"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv"
STATE_FILE="${STATE_DIR}/zoho-notify-quiet.state"
LOG_FILE="${STATE_DIR}/zoho-notify-quiet.log"
SWAYNC_TEMPLATE="${HYPR_DIR}/home/.config/swaync/config.json"
# ~/.config/swaync is a stow directory symlink into the repo — never write it.
SWAYNC_RUNTIME_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/hyprgruv/swaync-xdg"
SWAYNC_LIVE="${SWAYNC_RUNTIME_ROOT}/swaync/config.json"

# Defaults (overridden by config)
QUIET_TZ=America/New_York
QUIET_START_DOW=7 # Sunday (date +%u)
QUIET_START_HOUR=17
QUIET_START_MIN=0
QUIET_END_DOW=3 # Wednesday
QUIET_END_HOUR=11
QUIET_END_MIN=0
# ignored = never show; muted = no popup, still in control center
QUIET_STATE=ignored

# GLib regex (SwayNC) may not honor (?i). Match any capitalization of "zoho".
REGEX_APP='.*[Zz][Oo][Hh][Oo].*'
REGEX_DESKTOP='.*[Zz][Oo][Hh][Oo].*'
REGEX_SUMMARY='.*[Zz][Oo][Hh][Oo].*'
REGEX_BODY='.*[Zz][Oo][Hh][Oo].*'

mkdir -p "$STATE_DIR" "$CONFIG_DIR"

log() {
  local ts
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '%s %s\n' "$ts" "$*" >>"$LOG_FILE"
}

load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
  fi
}

dow_name() {
  case "$1" in
  1) echo Monday ;;
  2) echo Tuesday ;;
  3) echo Wednesday ;;
  4) echo Thursday ;;
  5) echo Friday ;;
  6) echo Saturday ;;
  7) echo Sunday ;;
  *) echo "dow-$1" ;;
  esac
}

hm_of() {
  local hour="$1" min="$2"
  printf '%d' $((10#$hour * 100 + 10#$min))
}

now_parts() {
  # Sets NOW_DOW (1=Mon..7=Sun), NOW_HM (HHMM), NOW_LABEL
  # IFS in this file is newline/tab-only, so don't parse a space-separated line.
  local hour min
  NOW_DOW="$(TZ="$QUIET_TZ" date +%u)"
  hour="$(TZ="$QUIET_TZ" date +%H)"
  min="$(TZ="$QUIET_TZ" date +%M)"
  NOW_HM="$(hm_of "$hour" "$min")"
  NOW_LABEL="$(TZ="$QUIET_TZ" date '+%Y-%m-%d %H:%M %Z')"
}

in_quiet_window() {
  local dow="$1" hm="$2"
  local start_hm end_hm
  start_hm="$(hm_of "$QUIET_START_HOUR" "$QUIET_START_MIN")"
  end_hm="$(hm_of "$QUIET_END_HOUR" "$QUIET_END_MIN")"

  if ((dow == QUIET_START_DOW && dow == QUIET_END_DOW)); then
    ((hm >= start_hm && hm < end_hm))
    return
  fi
  if ((QUIET_START_DOW < QUIET_END_DOW)); then
    if ((dow > QUIET_START_DOW && dow < QUIET_END_DOW)); then
      return 0
    fi
    if ((dow == QUIET_START_DOW)); then
      ((hm >= start_hm))
      return
    fi
    if ((dow == QUIET_END_DOW)); then
      ((hm < end_hm))
      return
    fi
    return 1
  fi
  # Window wraps the week (e.g. Fri → Mon). Not the default, but keep it correct.
  if ((dow > QUIET_START_DOW || dow < QUIET_END_DOW)); then
    return 0
  fi
  if ((dow == QUIET_START_DOW)); then
    ((hm >= start_hm))
    return
  fi
  if ((dow == QUIET_END_DOW)); then
    ((hm < end_hm))
    return
  fi
  return 1
}

looks_like_zoho() {
  local app="${1:-}" desktop="${2:-}" summary="${3:-}" body="${4:-}"
  local blob
  blob="$(printf '%s\n%s\n%s\n%s' "$app" "$desktop" "$summary" "$body")"
  grep -Eiq 'zoho(\.(com|eu|in))?|zoho mail|zoho cliq|zoho crm' <<<"$blob"
}

prepare_runtime() {
  local src="${HYPR_DIR}/home/.config/swaync"
  local dest="${SWAYNC_RUNTIME_ROOT}/swaync"
  local item
  mkdir -p "$dest"
  for item in style.css colors components icons matugen; do
    if [[ -e "$src/$item" ]]; then
      ln -sfn "$src/$item" "$dest/$item"
    fi
  done
}

swaync_client() {
  if command -v swaync-client >/dev/null 2>&1; then
    command -v swaync-client
    return 0
  fi
  if [[ -x "$HOME/.local/swaync-root/usr/bin/swaync-client" ]]; then
    echo "$HOME/.local/swaync-root/usr/bin/swaync-client"
    return 0
  fi
  return 1
}

reload_swaync() {
  local client
  client="$(swaync_client || true)"
  [[ -n "$client" ]] || return 0
  "$client" -R -sw 2>/dev/null || "$client" --reload-config -sw 2>/dev/null || true
}

close_notification_id() {
  local id="${1:-}"
  [[ -n "$id" && "$id" != "0" ]] || return 0
  gdbus call --session \
    --dest org.freedesktop.Notifications \
    --object-path /org/freedesktop/Notifications \
    --method org.freedesktop.Notifications.CloseNotification \
    "uint32 $id" &>/dev/null || true
}

current_live_state() {
  [[ -f "$SWAYNC_LIVE" ]] || {
    echo ""
    return 0
  }
  jq -r '.["notification-visibility"]["zoho-quiet-app"].state // empty' "$SWAYNC_LIVE" 2>/dev/null || true
}

patch_visibility() {
  local state="$1"
  local src="$SWAYNC_TEMPLATE"
  [[ -f "$src" ]] || {
    echo "SwayNC template not found: $src" >&2
    return 1
  }
  command -v jq >/dev/null 2>&1 || {
    echo "jq is required" >&2
    return 1
  }

  prepare_runtime
  local tmp
  tmp="$(mktemp)"
  jq \
    --arg state "$state" \
    --arg app "$REGEX_APP" \
    --arg desktop "$REGEX_DESKTOP" \
    --arg summary "$REGEX_SUMMARY" \
    --arg body "$REGEX_BODY" \
    --arg exec "bash -c 'exec \"\$HOME/.hyprgruv/lib/scripts/zoho-notify-quiet.sh\" --on-receive'" \
    '
      .scripts = (.scripts // {}) |
      .scripts["zoho-quiet-app"] = {"exec": $exec, "app-name": $app, "run-on": "receive"} |
      .scripts["zoho-quiet-summary"] = {"exec": $exec, "summary": $summary, "run-on": "receive"} |
      .scripts["zoho-quiet-body"] = {"exec": $exec, "body": $body, "run-on": "receive"} |
      .["notification-visibility"] = (.["notification-visibility"] // {}) |
      .["notification-visibility"]["zoho-quiet-app"] = {"state": $state, "app-name": $app} |
      .["notification-visibility"]["zoho-quiet-desktop"] = {"state": $state, "desktop-entry": $desktop} |
      .["notification-visibility"]["zoho-quiet-summary"] = {"state": $state, "summary": $summary} |
      .["notification-visibility"]["zoho-quiet-body"] = {"state": $state, "body": $body}
    ' "$src" >"$tmp"
  mv -f "$tmp" "$SWAYNC_LIVE"
}

desired_state() {
  if in_quiet_window "$NOW_DOW" "$NOW_HM"; then
    printf '%s' "$QUIET_STATE"
  else
    printf '%s' "enabled"
  fi
}

write_state_file() {
  printf '%s\n' "$1" >"$STATE_FILE"
}

cmd_apply() {
  local force="${1:-0}"
  now_parts
  local want current first=0
  want="$(desired_state)"
  current="$(current_live_state)"
  [[ -f "$STATE_FILE" ]] || first=1

  if [[ "$force" != "1" && "$current" == "$want" && "$first" != "1" ]]; then
    log "apply: already $want ($NOW_LABEL)"
    return 0
  fi

  if [[ "$current" != "$want" || "$first" == "1" || "$force" == "1" ]]; then
    if [[ "$current" != "$want" || "$force" == "1" || -z "$current" ]]; then
      patch_visibility "$want"
    fi
    reload_swaync
  fi
  write_state_file "$want"
  log "apply: ${current:-unset} -> $want ($NOW_LABEL)"
  echo "Zoho SwayNC: ${want}  (${NOW_LABEL})"
}

cmd_on_receive() {
  now_parts
  if ! in_quiet_window "$NOW_DOW" "$NOW_HM"; then
    return 0
  fi
  if ! looks_like_zoho \
    "${SWAYNC_APP_NAME:-}" \
    "${SWAYNC_DESKTOP_ENTRY:-}" \
    "${SWAYNC_SUMMARY:-}" \
    "${SWAYNC_BODY:-}"; then
    return 0
  fi
  log "on-receive: drop id=${SWAYNC_ID:-?} app=${SWAYNC_APP_NAME:-} summary=${SWAYNC_SUMMARY:-}"
  close_notification_id "${SWAYNC_ID:-}"
}

cmd_status() {
  now_parts
  local want current quiet="no"
  want="$(desired_state)"
  current="$(current_live_state)"
  in_quiet_window "$NOW_DOW" "$NOW_HM" && quiet="yes"

  echo "Now:          $NOW_LABEL"
  echo "Window:       $(dow_name "$QUIET_START_DOW") $(printf '%02d:%02d' "$QUIET_START_HOUR" "$QUIET_START_MIN") → $(dow_name "$QUIET_END_DOW") $(printf '%02d:%02d' "$QUIET_END_HOUR" "$QUIET_END_MIN") ($QUIET_TZ)"
  echo "In window:    $quiet"
  echo "Wanted state: $want"
  echo "Live state:   ${current:-unset}"
  echo "Config:       $CONFIG_FILE"
  echo "Template:     $SWAYNC_TEMPLATE"
  echo "Runtime:      $SWAYNC_LIVE"
}

cmd_test() {
  load_config
  notify-send -a "Zoho Mail" -i mail-unread \
    "Zoho Mail (test)" \
    "mail.zoho.com"$'\n'"If quiet hours are active this should not appear (or should vanish immediately)."
  echo "Sent a Zoho-shaped test notification."
}

usage() {
  cat <<'EOF'
Usage: zoho-notify-quiet [--apply|--status|--on-receive|--force-on|--force-off|--test]

Mute Zoho notifications in SwayNC from Sunday 5pm to Wednesday 11am Eastern.

  --apply       Match SwayNC visibility to the clock (install / timer / login)
  --status      Show window and current mute state
  --on-receive  SwayNC hook: close this notification if we are in the window
  --force-on    Mute now
  --force-off   Unmute now
  --test        Send a sample Zoho Mail notification

Config: ~/.config/zoho-notify-quiet/config
Logs:   ~/.local/state/hyprgruv/zoho-notify-quiet.log
EOF
}

main() {
  load_config
  local cmd="${1:-apply}"
  case "$cmd" in
  --apply | apply) cmd_apply 0 ;;
  --force-on | force-on)
    now_parts
    patch_visibility "$QUIET_STATE"
    reload_swaync
    write_state_file "$QUIET_STATE"
    log "force-on ($NOW_LABEL)"
    echo "Zoho SwayNC: ${QUIET_STATE} (forced)"
    ;;
  --force-off | force-off)
    now_parts
    patch_visibility enabled
    reload_swaync
    write_state_file enabled
    log "force-off ($NOW_LABEL)"
    echo "Zoho SwayNC: enabled (forced)"
    ;;
  --on-receive | on-receive) cmd_on_receive ;;
  --status | status) cmd_status ;;
  --test | test) cmd_test ;;
  -h | --help | help) usage ;;
  *)
    echo "Unknown command: $cmd" >&2
    usage
    exit 1
    ;;
  esac
}

main "$@"
