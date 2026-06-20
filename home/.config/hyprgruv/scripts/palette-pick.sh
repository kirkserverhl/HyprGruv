#!/usr/bin/env bash
# palette-pick.sh — walk through base16 slot-by-slot, pick hex per color
#
# Suggestions come from pywal + matugen + literal wallpaper pixels.
# Pick via dropdown, rofi swatch panel, hyprpicker, paste hex, or clipboard.
# Live base16 grid + starship rainbow preview as you go.
#
# Usage: palette-pick.sh [/path/to/wallpaper.png]

set -uo pipefail

CLASS="dotfiles-floating"
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)
SCRIPTS="$HOME/.config/hyprgruv/scripts"
BUILDER="$SCRIPTS/palette-build-import.py"
SPECTRUM="$SCRIPTS/spectrum.py"
ROLES_FILE="$HOME/.config/matugen/roles.json"
USER_PALETTE="$HOME/.config/matugen/user-palette.json"
COLOR_MODE_FILE="$HOME/.cache/matugen/color-mode"
APPLY="$SCRIPTS/apply-matugen-auto.sh"
ROFI_THEME="$HOME/.config/rofi/base16-grid.rasi"
EXTRACTOR="$SCRIPTS/extract-good-source-colors.sh"

SLOTS=(
    base00 base01 base02 base03 base04 base05 base06 base07
    base08 base09 base0a base0b base0c base0d base0e base0f
)

if [[ -z "${PALETTE_PICK_INSIDE:-}" ]]; then
    export PALETTE_PICK_INSIDE=1
    exec "${CLEAN_ENV[@]}" kitty \
        --class "$CLASS" \
        --title "Base16 Picker" \
        --override initial_window_width=92c \
        --override initial_window_height=36c \
        -e "$0" "$@"
fi

source "$SCRIPTS/header.sh" 2>/dev/null || true
printf '\e]2;Base16 Picker\a' 2>/dev/null || true

command -v gum >/dev/null 2>&1 || { echo "gum is required"; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "jq is required"; exit 1; }
[[ -x "$BUILDER" ]] || chmod +x "$BUILDER"

WALLPAPER="${1:-}"
if [[ -z "$WALLPAPER" ]]; then
    for f in "$HOME/.config/last_wallpaper.txt" "$HOME/.config/settings/default"; do
        [[ -f "$f" ]] && WALLPAPER=$(tr -d '\n' <"$f") && break
    done
fi
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    gum style --foreground 1 "No wallpaper found."
    exit 1
fi

ACTIVE_THEME=""
[[ -f "$HOME/.config/colorschemes/.current-theme" ]] && \
    ACTIVE_THEME=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme")

color_swatch() {
    local hex=${1#\#}
    [[ ${#hex} -ne 6 ]] && return
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\e[48;2;%d;%d;%dm  \e[0m' "$r" "$g" "$b"
}

normalize_hex() {
    local raw="${1,,}"
    raw="${raw#\#}"
    [[ ${#raw} -eq 6 && "$raw" =~ ^[0-9a-f]{6}$ ]] || return 1
    printf '#%s\n' "$raw"
}

clipboard_hex() {
    local clip=""
    if command -v wl-paste >/dev/null 2>&1; then
        clip=$(wl-paste -n 2>/dev/null || true)
    elif command -v xclip >/dev/null 2>&1; then
        clip=$(xclip -selection clipboard -o 2>/dev/null || true)
    fi
    normalize_hex "$clip"
}

render_previews() {
    local highlight="${1:-}"
    python3 - "$SPECTRUM" "$ACTIVE_THEME" "$highlight" <<'PY'
import importlib.util
import json
import os
import sys

spectrum_path, theme, highlight = sys.argv[1:4]
spec = importlib.util.spec_from_file_location("spectrum", spectrum_path)
spectrum = importlib.util.module_from_spec(spec)
assert spec.loader is not None
spec.loader.exec_module(spectrum)

base16 = {}
for slot in [
    "base00","base01","base02","base03","base04","base05","base06","base07",
    "base08","base09","base0a","base0b","base0c","base0d","base0e","base0f",
]:
    val = os.environ.get(f"SLOT_{slot.upper()}") or os.environ.get(f"SLOT_{slot}")
    if isinstance(val, str) and val.startswith("#"):
        base16[slot] = val.lower()

def bg(hexv: str, slot_name: str) -> str:
    hx = hexv.lstrip("#")
    r, g, b = int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16)
    mark = "▌" if highlight and slot_name == highlight else " "
    return f"\033[48;2;{r};{g};{b}m{mark}\033[0m"

print("Base16 grid")
rows = [
    ("base00", "base01", "base02", "base03"),
    ("base04", "base05", "base06", "base07"),
    ("base08", "base09", "base0a", "base0b"),
    ("base0c", "base0d", "base0e", "base0f"),
]
for row in rows:
    labels = "  ".join(f"{s[4:].upper():>2}" for s in row)
    swatches = "  ".join(bg(base16.get(s, "#333333"), s) for s in row)
    hexes = "  ".join(f"{base16.get(s, '------')[1:]}" for s in row)
    print(f"  {labels}")
    print(f"  {swatches}")
    print(f"  {hexes}")
    print()

resolved = spectrum.resolve_spectrum(base16, theme or None)
order = [
    ("orange", "color_orange"),
    ("yellow", "color_yellow"),
    ("aqua", "color_aqua"),
    ("blue", "color_blue"),
    ("grey", "color_bg3"),
    ("dark", "color_bg1"),
]
print("Starship rainbow")
parts = []
for label, key in order:
    hx = resolved.get(key, "#444444")
    h = hx.lstrip("#")
    r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
    parts.append(f"\033[48;2;{r};{g};{b}m {label[:3]:>3} \033[0m")
print("  " + "".join(parts))
PY
}

pick_from_rofi() {
    local -n _pool_ref=$1
    local header="$2"
    [[ ${#_pool_ref[@]} -eq 0 ]] && return 1
    command -v rofi >/dev/null 2>&1 || return 1
    command -v magick >/dev/null 2>&1 || return 1

    local swatch_dir input chosen hx swatch label
    swatch_dir=$(mktemp -d /tmp/palette-pick-rofi-XXXXXX)
    input=""
    for hx in "${_pool_ref[@]}"; do
        swatch="${swatch_dir}/$(echo "$hx" | tr -d '#').png"
        magick -size 48x48 "xc:${hx}" -bordercolor "#2a2a2a" -border 2 -alpha off png32:"$swatch" 2>/dev/null || continue
        label=$(printf '%s' "$hx")
        input+="${label}\0icon\x1f${swatch}\n"
    done

    chosen=$(printf '%b' "$input" | rofi -dmenu -i -show-icons \
        -p "$header" -theme "$ROFI_THEME" -no-custom 2>/dev/null || true)
    rm -rf "$swatch_dir"
    [[ -z "$chosen" ]] && return 1
    normalize_hex "$chosen"
}

declare -A SLOT_HEX=()
declare -A SLOT_HINT=()

while IFS='|' read -r slot label hint; do
    SLOT_HINT[$slot]="$label — $hint"
done < <(jq -r '.roles[] | "\(.slot)|\(.label)|\(.hint)"' "$ROLES_FILE" 2>/dev/null || true)

preview_json=$("$BUILDER" preview "$WALLPAPER" 2>/dev/null) || {
    gum style --foreground 1 "Could not extract palettes from wallpaper."
    exit 1
}

mapfile -t COLOR_POOL < <(python3 - "$WALLPAPER" "$preview_json" "$EXTRACTOR" <<'PY'
import json
import subprocess
import sys
from pathlib import Path

wallpaper, preview_json, extractor = sys.argv[1:4]
data = json.loads(preview_json)
seen = []

def add(hx, tag=""):
    if not isinstance(hx, str) or not hx.startswith("#"):
        return
    key = hx.lower()
    if key not in seen:
        seen.append(key)

for group in ("wal", "matugen"):
    b = data.get(group, {}).get("base16", {})
    for slot in sorted(b):
        val = b[slot]
        if isinstance(val, str):
            add(val, group)

if Path(extractor).is_file():
    try:
        proc = subprocess.run([extractor, wallpaper, "12"], capture_output=True, text=True, check=False)
        for line in proc.stdout.splitlines():
            add(line.strip(), "extract")
    except Exception:
        pass

try:
    proc = subprocess.run(
        ["magick", wallpaper, "-resize", "320x320>", "-colors", "24", "+dither", "-unique-colors", "txt:-"],
        capture_output=True, text=True, check=False,
    )
    for line in proc.stdout.splitlines():
        if line.startswith("#"):
            hx = line.split()[1] if len(line.split()) > 1 else ""
            add(hx, "pixel")
except Exception:
    pass

for hx in seen:
    print(hx)
PY
)

clear
print_header "Base16 Picker" 2>/dev/null || true
gum style --bold "Wallpaper: $(basename "$WALLPAPER")"
[[ -n "$ACTIVE_THEME" ]] && gum style --faint "Theme: $ACTIVE_THEME"
echo

starter=$(gum choose \
    "Start from Pywal" \
    "Start from Matugen" \
    "Start from active theme palette" \
    "Start from saved custom palette" \
    "Start blank (#333333)" \
    "Cancel" \
    --header "Starting point for all 16 slots")

[[ "$starter" == "Cancel" || -z "$starter" ]] && exit 0

_load_slots() {
    local src="$1"
    while IFS= read -r line; do
        slot=${line%%:*}
        hex=${line#*: }
        SLOT_HEX[$slot]=$(normalize_hex "$hex" 2>/dev/null || echo "#333333")
    done < <(echo "$src")
}

case "$starter" in
    "Start from Pywal")
        _load_slots "$(echo "$preview_json" | jq -r '.wal.base16 | to_entries[] | "\(.key): \(.value)"')"
        ;;
    "Start from Matugen")
        _load_slots "$(echo "$preview_json" | jq -r '.matugen.base16 | to_entries[] | select(.key|startswith("_")|not) | "\(.key): \(.value)"')"
        ;;
    "Start from active theme palette")
        if [[ -n "$ACTIVE_THEME" && -f "$HOME/.config/colorschemes/$ACTIVE_THEME/palette.json" ]]; then
            _load_slots "$(jq -r '.base16 | to_entries[] | "\(.key): \(.value)"' "$HOME/.config/colorschemes/$ACTIVE_THEME/palette.json")"
        else
            gum style --foreground 3 "No theme palette — using Pywal."
            _load_slots "$(echo "$preview_json" | jq -r '.wal.base16 | to_entries[] | "\(.key): \(.value)"')"
        fi
        ;;
    "Start from saved custom palette")
        if [[ -f "$USER_PALETTE" ]]; then
            _load_slots "$(jq -r '.base16 | to_entries[] | "\(.key): \(.value)"' "$USER_PALETTE")"
        else
            gum style --foreground 3 "No saved palette — using Pywal."
            _load_slots "$(echo "$preview_json" | jq -r '.wal.base16 | to_entries[] | "\(.key): \(.value)"')"
        fi
        ;;
    "Start blank (#333333)")
        for slot in "${SLOTS[@]}"; do
            SLOT_HEX[$slot]="#333333"
        done
        ;;
esac

slot_index=0
while [[ $slot_index -lt ${#SLOTS[@]} ]]; do
    slot="${SLOTS[$slot_index]}"
    current="${SLOT_HEX[$slot]:-#333333}"
    hint="${SLOT_HINT[$slot]:-$slot}"

    for s in "${SLOTS[@]}"; do
        export "SLOT_${s^^}=${SLOT_HEX[$s]:-#333333}"
    done

    clear
    print_header "Base16 Picker" 2>/dev/null || true
    gum style --bold "Slot $((slot_index + 1))/${#SLOTS[@]} — ${slot^^}"
    gum style --faint "$hint"
    gum style "Current: $(color_swatch "$current")  $current"
    echo
    render_previews "$slot"
    echo

    clip_default=""
    clip_default=$(clipboard_hex 2>/dev/null || true)

    actions=(
        "Keep current ($current)"
        "Color panel (rofi swatches)"
        "Suggestions dropdown"
        "Paste hex"
        "Pick from screen (hyprpicker)"
    )
    [[ -n "$clip_default" ]] && actions+=("Use clipboard ($clip_default)")
    [[ $slot_index -gt 0 ]] && actions+=("← Back")
    actions+=("Skip rest (keep remaining defaults)")

    action=$(gum choose "${actions[@]}" --header "Choose color for ${slot^^}")

    [[ -z "$action" ]] && { slot_index=$((slot_index + 1)); continue; }

    new_hex=""
    case "$action" in
        "Keep current"*)
            new_hex="$current"
            ;;
        "Color panel"*)
            picked=$(pick_from_rofi COLOR_POOL "Pick a color for ${slot^^}") || new_hex="$current"
            [[ -n "$picked" ]] && new_hex="$picked"
            ;;
        "Suggestions dropdown")
            pywal_hex=$(echo "$preview_json" | jq -r --arg s "$slot" '.wal.base16[$s] // empty')
            matugen_hex=$(echo "$preview_json" | jq -r --arg s "$slot" '.matugen.base16[$s] // empty' 2>/dev/null)
            options=()
            [[ -n "$pywal_hex" ]] && options+=("$(color_swatch "$pywal_hex")  pywal $slot  $pywal_hex")
            [[ -n "$matugen_hex" && "$matugen_hex" != "null" ]] && options+=("$(color_swatch "$matugen_hex")  matugen $slot  $matugen_hex")
            for hx in "${COLOR_POOL[@]}"; do
                options+=("$(color_swatch "$hx")  wallpaper  $hx")
            done
            pick=$(gum choose "${options[@]}" --header "Suggestions for ${slot^^}" 2>/dev/null || true)
            if [[ -n "$pick" ]]; then
                new_hex=$(sed -n 's/.*  \(\#[0-9A-Fa-f]\{6\}\)$/\1/p' <<<"$pick")
            fi
            [[ -z "$new_hex" ]] && new_hex="$current"
            ;;
        "Paste hex")
            typed=$(gum input --value "$current" --placeholder "#rrggbb" --header "Hex for ${slot^^}") || typed=""
            new_hex=$(normalize_hex "$typed" 2>/dev/null || echo "$current")
            ;;
        "Pick from screen"*)
            gum style --foreground 3 "Move this window aside, then click a color on screen."
            if command -v hyprpicker >/dev/null 2>&1; then
                hyprpicker -a -f hex -l -q 2>/dev/null || true
                picked=$(clipboard_hex 2>/dev/null || true)
                [[ -n "$picked" ]] && new_hex="$picked" || new_hex="$current"
            else
                gum style --foreground 1 "hyprpicker not found."
                new_hex="$current"
            fi
            ;;
        "Use clipboard"*)
            new_hex="$clip_default"
            ;;
        "← Back")
            slot_index=$((slot_index - 1))
            continue
            ;;
        "Skip rest"*)
            break
            ;;
    esac

    SLOT_HEX[$slot]="$new_hex"
    slot_index=$((slot_index + 1))
done

clear
gum style --bold "Final palette"
for slot in "${SLOTS[@]}"; do
    hx="${SLOT_HEX[$slot]:-#333333}"
    printf "  %s  %s  %s  %s\n" "$slot" "$(color_swatch "$hx")" "$hx" "${SLOT_HINT[$slot]:-}"
done
echo

for s in "${SLOTS[@]}"; do
    export "SLOT_${s^^}=${SLOT_HEX[$s]:-#333333}"
done
render_previews ""
echo

save_target=$(gum choose \
    "Save as named configuration + apply" \
    "Apply now (session only)" \
    "Save to active theme slot + apply" \
    "Cancel without saving" \
    --header "Save and apply this palette?")
[[ "$save_target" == "Cancel without saving" || -z "$save_target" ]] && exit 0

CONFIG_NAME=""
CONFIG_LABEL=""
if [[ "$save_target" == "Save as named configuration + apply" ]]; then
    CONFIG_NAME=$(gum input --placeholder "e.g. noir-warm" --header "Configuration name") || CONFIG_NAME=""
    [[ -z "$CONFIG_NAME" ]] && exit 0
    CONFIG_LABEL=$(gum input --value "$CONFIG_NAME" --header "Display label (optional)") || CONFIG_LABEL="$CONFIG_NAME"
fi

python3 - "$WALLPAPER" "$USER_PALETTE" <<'PY'
import json, os, sys
from datetime import datetime, timezone

wallpaper, out_path = sys.argv[1:3]
base16 = {}
for slot in [
    "base00","base01","base02","base03","base04","base05","base06","base07",
    "base08","base09","base0a","base0b","base0c","base0d","base0e","base0f",
]:
    val = os.environ.get(f"SLOT_{slot.upper()}") or os.environ.get(f"SLOT_{slot}")
    if isinstance(val, str) and val.startswith("#"):
        base16[slot] = val.lower()

payload = {
    "version": 1,
    "wallpaper": wallpaper,
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "source": "palette-pick",
    "base16": base16,
}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

if [[ "$save_target" == "Save as named configuration + apply" ]]; then
    bash "$HOME/.config/colorschemes/colors-config.sh" save "$CONFIG_NAME" --label "$CONFIG_LABEL" --from session
    bash "$HOME/.config/colorschemes/colors-config.sh" load "$CONFIG_NAME" --no-wallpaper
    gum style --bold --foreground 2 "Saved and applied: $CONFIG_LABEL"
    exit 0
fi

if [[ "$save_target" == "Save to active theme slot + apply" ]]; then
    if [[ -z "$ACTIVE_THEME" ]]; then
        gum style --foreground 3 "No active theme — session only."
        mkdir -p "$(dirname "$COLOR_MODE_FILE")"
        echo saved >"$COLOR_MODE_FILE"
    else
        bash "$HOME/.config/colorschemes/save-theme-palette.sh" "$ACTIVE_THEME" "$USER_PALETTE"
        rm -f "$COLOR_MODE_FILE" 2>/dev/null || true
        touch "$HOME/.config/colorschemes/.use-preset-colors"
        echo "$ACTIVE_THEME" >"$HOME/.config/colorschemes/.current-theme"
        gum spin --spinner dot --title "Applying $ACTIVE_THEME…" -- \
            bash "$HOME/.config/colorschemes/apply-theme.sh" "$ACTIVE_THEME" "$WALLPAPER"
        gum style --bold --foreground 2 "Saved to theme: $ACTIVE_THEME"
        exit 0
    fi
else
    mkdir -p "$(dirname "$COLOR_MODE_FILE")"
    echo saved >"$COLOR_MODE_FILE"
fi

if [[ -n "$ACTIVE_THEME" ]]; then
    gum spin --spinner dot --title "Applying palette…" -- \
        bash "$HOME/.config/colorschemes/colors-config.sh" apply-static "$ACTIVE_THEME" "$USER_PALETTE" "$WALLPAPER" ""
else
    gum spin --spinner dot --title "Applying palette…" -- \
        env MATUGEN_FORCE=1 MATUGEN_COLOR_MODE=custom MATUGEN_NONINTERACTIVE=1 "$APPLY" "$WALLPAPER"
fi

gum style --bold --foreground 2 "Done — palette saved to $USER_PALETTE"