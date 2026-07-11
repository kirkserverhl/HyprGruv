#!/usr/bin/env bash
# Soundsbored — multi-category rofi soundboard
# Categories: Openings → In-Call → Closers/Misc  (Left/Right arrows)
# Persistent hotkeys after Police Siren always listed at the bottom.
set -euo pipefail

ROOT="${HOME}/.local/share/soundsbored"
CLIPS="${ROOT}/clips"
INDEX="${CLIPS}/index.tsv"
STATE="${ROOT}/state"
TOGGLE_FILE="${STATE}/wooo_awww"
THEME="${HOME}/.config/rofi/config-soundsbored.rasi"
DOWNLOADER="${ROOT}/download-clips.sh"

mkdir -p "$STATE" "$CLIPS"

# 0 = Wooo next, 1 = Awww next
[[ -f "$TOGGLE_FILE" ]] || echo 0 >"$TOGGLE_FILE"

need_index() {
  [[ ! -f "$INDEX" ]] || ! grep -qvE '^#|^$' "$INDEX" 2>/dev/null
}

if need_index; then
  if [[ -x "$DOWNLOADER" ]]; then
    notify-send -a soundsbored "Soundsbored" "Downloading clips (first run)…" 2>/dev/null || true
    bash "$DOWNLOADER"
  else
    notify-send -a soundsbored "Soundsbored" "No clips yet. Run: $DOWNLOADER" 2>/dev/null || true
    echo "Missing index. Run: $DOWNLOADER" >&2
    exit 1
  fi
fi

# --- index helpers (TSV: category role name slug path url) ---
index_rows() {
  grep -vE '^#|^$' "$INDEX" || true
}

# Print display lines for a category (normal role only), sorted as in index
category_items() {
  local cat="$1"
  index_rows | awk -F'\t' -v c="$cat" '$1==c && $2=="normal" { print $3 "\t" $5 }'
}

hotkey_paths() {
  # name -> path lines for single-file hotkeys
  index_rows | awk -F'\t' '$1=="hotkeys" && $2=="hotkey" { print $3 "\t" $5 }'
}

toggle_path() {
  local role="$1" # toggle_a | toggle_b
  index_rows | awk -F'\t' -v r="$role" '$1=="hotkeys" && $2==r { print $5; exit }'
}

random_paths() {
  index_rows | awk -F'\t' '$1=="hotkeys" && $2=="random" { print $5 }'
}

play_file() {
  local f="$1"
  if [[ -z "$f" || ! -f "$f" ]]; then
    notify-send -a soundsbored "Soundsbored" "Missing clip: ${f:-?}" 2>/dev/null || true
    return 1
  fi
  # Overlapping playback (classic soundboard). Quiet, no video.
  mpv --no-video --really-quiet --volume=100 --force-window=no "$f" &
  disown
}

play_by_name() {
  local want="$1"
  local path
  path="$(index_rows | awk -F'\t' -v n="$want" 'tolower($3)==tolower(n) { print $5; exit }')"
  play_file "$path"
}

play_toggle_wooo_awww() {
  local state next role path label
  state="$(cat "$TOGGLE_FILE" 2>/dev/null || echo 0)"
  if [[ "$state" == "0" ]]; then
    role="toggle_a"
    next=1
    label="Wooo"
  else
    role="toggle_b"
    next=0
    label="Awww"
  fi
  path="$(toggle_path "$role")"
  echo "$next" >"$TOGGLE_FILE"
  play_file "$path"
  notify-send -a soundsbored -t 1200 "Soundsbored" "▶ $label  (next: $([[ $next -eq 0 ]] && echo Wooo || echo Awww))" 2>/dev/null || true
}

play_random_laugh() {
  mapfile -t laughs < <(random_paths)
  if ((${#laughs[@]} == 0)); then
    notify-send -a soundsbored "Soundsbored" "No laugh tracks found" 2>/dev/null || true
    return 1
  fi
  local pick="${laughs[RANDOM % ${#laughs[@]}]}"
  play_file "$pick"
}

# --- categories ---
# id | prompt label | mesg hint
CATEGORIES=(openings in-call closers)
declare -A CAT_TITLE=(
  [openings]="Openings"
  [in-call]="In-Call"
  [closers]="Closers / Misc"
)
declare -A CAT_HINT=(
  [openings]="→  In-Call"
  [in-call]="←  Openings    |    Closers / Misc  →"
  [closers]="←  In-Call"
)

cat_index_of() {
  local c="$1" i
  for i in "${!CATEGORIES[@]}"; do
    [[ "${CATEGORIES[$i]}" == "$c" ]] && { echo "$i"; return; }
  done
  echo 0
}

# Separator + persistent hotkey strip (always after category items)
# Uses rofi urgent/active markup via -u / -a row indices
build_menu() {
  local cat="$1"
  local -a lines=()
  local -a meta=() # parallel: path|action
  local name path

  while IFS=$'\t' read -r name path; do
    [[ -z "${name:-}" ]] && continue
    lines+=("  ${name}")
    meta+=("play:${path}")
  done < <(category_items "$cat")

  # spacer
  lines+=("────────────────────────────")
  meta+=("noop:")

  # Persistent hotkeys (fixed order)
  # Prefer friendly labels over raw index names
  local sad damn
  sad="$(index_rows | awk -F'\t' '$1=="hotkeys" && $2=="hotkey" && tolower($3) ~ /sad/ { print $5; exit }')"
  damn="$(index_rows | awk -F'\t' '$1=="hotkeys" && $2=="hotkey" && tolower($3) ~ /damn/ { print $5; exit }')"

  local tstate tlabel
  tstate="$(cat "$TOGGLE_FILE" 2>/dev/null || echo 0)"
  if [[ "$tstate" == "0" ]]; then
    tlabel="Wooo / Awww  · next: Wooo"
  else
    tlabel="Wooo / Awww  · next: Awww"
  fi

  lines+=("  ♪  Sad Trombone")
  meta+=("play:${sad}")
  lines+=("  ♪  Damn Son")
  meta+=("play:${damn}")
  lines+=("  ♪  ${tlabel}")
  meta+=("action:toggle")
  lines+=("  ♪  Laugh Track (random)")
  meta+=("action:laugh")

  # Export via globals for selection handling
  MENU_LINES=("${lines[@]}")
  MENU_META=("${meta[@]}")
}

run_rofi() {
  local cat="$1"
  local title hint
  title="${CAT_TITLE[$cat]}"
  hint="${CAT_HINT[$cat]}"

  build_menu "$cat"

  # Mark separator as urgent, hotkeys as active for theming
  local sep_idx hot_start
  sep_idx=$((${#MENU_LINES[@]} - 5))
  hot_start=$((sep_idx + 1))
  local u_arg a_arg
  u_arg="$sep_idx"
  a_arg="${hot_start}-$((${#MENU_LINES[@]} - 1))"

  local selected
  set +e
  selected="$(
    printf '%s\n' "${MENU_LINES[@]}" | rofi -dmenu -i \
      -config "$THEME" \
      -p "${title}" \
      -mesg "  ${hint}     ·     hotkeys stay pinned below" \
      -format s \
      -selected-row 0 \
      -u "$u_arg" \
      -a "$a_arg" \
      -kb-custom-1 "Right" \
      -kb-custom-2 "Left" \
      -kb-custom-3 "Alt+1" \
      -kb-custom-4 "Alt+2" \
      -kb-custom-5 "Alt+3" \
      -kb-custom-6 "Alt+4"
  )"
  local rc=$?
  set -e

  case $rc in
    1|130)
      return 1 # cancel
      ;;
    10)
      # Right → next category
      local idx next
      idx="$(cat_index_of "$cat")"
      next=$((idx + 1))
      if ((next < ${#CATEGORIES[@]})); then
        CURRENT="${CATEGORIES[$next]}"
      fi
      return 2 # continue loop
      ;;
    11)
      # Left → previous category
      local idx prev
      idx="$(cat_index_of "$cat")"
      prev=$((idx - 1))
      if ((prev >= 0)); then
        CURRENT="${CATEGORIES[$prev]}"
      fi
      return 2
      ;;
    12)
      play_file "$(index_rows | awk -F'\t' '$1=="hotkeys" && $2=="hotkey" && tolower($3) ~ /sad/ { print $5; exit }')"
      return 2
      ;;
    13)
      play_file "$(index_rows | awk -F'\t' '$1=="hotkeys" && $2=="hotkey" && tolower($3) ~ /damn/ { print $5; exit }')"
      return 2
      ;;
    14)
      play_toggle_wooo_awww
      return 2
      ;;
    15)
      play_random_laugh
      return 2
      ;;
    0)
      if [[ -z "${selected:-}" ]]; then
        return 1
      fi
      # Match by display text so filtering still resolves the right clip
      local i meta action rest
      meta=""
      for i in "${!MENU_LINES[@]}"; do
        if [[ "${MENU_LINES[$i]}" == "$selected" ]]; then
          meta="${MENU_META[$i]}"
          break
        fi
      done
      [[ -z "$meta" ]] && return 2
      action="${meta%%:*}"
      rest="${meta#*:}"
      case "$action" in
        play)
          play_file "$rest"
          return 2 # keep menu open for rapid fire
          ;;
        action)
          case "$rest" in
            toggle) play_toggle_wooo_awww ;;
            laugh)  play_random_laugh ;;
          esac
          return 2
          ;;
        noop)
          return 2
          ;;
        *)
          return 2
          ;;
      esac
      ;;
    *)
      return 1
      ;;
  esac
}

# Optional: re-download
if [[ "${1:-}" == "--download" || "${1:-}" == "download" ]]; then
  exec bash "$DOWNLOADER"
fi

# Optional: start category
CURRENT="${1:-openings}"
case "$CURRENT" in
  openings|intros|intro|open) CURRENT="openings" ;;
  in-call|incall|call|in)     CURRENT="in-call" ;;
  closers|closer|misc|close)  CURRENT="closers" ;;
  *)                          CURRENT="openings" ;;
esac

pkill -x rofi 2>/dev/null || true

while true; do
  rc=0
  run_rofi "$CURRENT" || rc=$?
  case $rc in
    0) continue ;; # shouldn't hit
    2) continue ;; # replay menu
    *) break ;;
  esac
done
