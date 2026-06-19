#!/usr/bin/env bash
# palette-customize.sh — preview pywal vs matugen, assign base16 roles, save + apply
#
# Saves ~/.config/matugen/user-palette.json (single source of truth for all templates).
# Usage: palette-customize.sh [/path/to/wallpaper.png]
#   palette          — if linked/aliased
#   Ctrl+Shift+P     — bind in hyprland if desired

set -uo pipefail

CLASS="dotfiles-floating"
CLEAN_ENV=(env -u GDK_DEBUG -u GDK_DISABLE GDK_DEBUG= GDK_DISABLE=)
SCRIPTS="$HOME/.config/hyprgruv/scripts"
BUILDER="$SCRIPTS/palette-build-import.py"
ROLES_FILE="$HOME/.config/matugen/roles.json"
USER_PALETTE="$HOME/.config/matugen/user-palette.json"
COLOR_MODE_FILE="$HOME/.cache/matugen/color-mode"
APPLY="$SCRIPTS/apply-matugen-auto.sh"

if [[ -z "${PALETTE_CUSTOM_INSIDE:-}" ]]; then
    export PALETTE_CUSTOM_INSIDE=1
    exec "${CLEAN_ENV[@]}" kitty \
        --class "$CLASS" \
        --title "Palette Customizer" \
        --override initial_window_width=88c \
        --override initial_window_height=32c \
        -e "$0" "$@"
fi

source "$HOME/.config/hyprgruv/scripts/header.sh" 2>/dev/null || true
printf '\e]2;Palette Customizer\a' 2>/dev/null || true

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

color_swatch() {
    local hex=${1#\#}
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    printf '\e[48;2;%d;%d;%dm  \e[0m' "$r" "$g" "$b"
}

unique_pool() {
    python3 - "$1" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
seen = []
for group in ("wal", "matugen"):
    b = data.get(group, {}).get("base16", {})
    for slot in sorted(b):
        hx = b[slot]
        if isinstance(hx, str) and hx.startswith("#") and hx.lower() not in seen:
            seen.append(hx.lower())
            print(hx)
PY
}

preview_json=$("$BUILDER" preview "$WALLPAPER" 2>/dev/null) || {
    gum style --foreground 1 "Could not extract palettes from wallpaper."
    exit 1
}

clear
print_header "Palette Customizer" 2>/dev/null || true
gum style --bold "Wallpaper: $(basename "$WALLPAPER")"
echo

gum style --bold --foreground 6 "Pywal (literal image colors)"
python3 - "$preview_json" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
b = data["wal"]["base16"]
for slot in sorted(b):
    print(f"  {slot}: {b[slot]}")
PY

echo
gum style --bold --foreground 5 "Matugen default (Material You base16)"
python3 - "$preview_json" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
b = data.get("matugen", {}).get("base16", {})
if "_error" in b:
    print(f"  (unavailable: {b['_error']})")
else:
    for slot in sorted(b):
        if not slot.startswith("_"):
            print(f"  {slot}: {b[slot]}")
PY

echo
starter=$(gum choose \
    "Start from Pywal (recommended)" \
    "Start from Matugen default" \
    "Load saved custom palette (if any)" \
    "Cancel" \
    --header "Choose starting palette")

[[ "$starter" == "Cancel" || -z "$starter" ]] && exit 0

declare -A SLOT_HEX=()
if [[ "$starter" == "Load saved custom palette (if any)" ]]; then
    if [[ ! -f "$USER_PALETTE" ]]; then
        gum style --foreground 3 "No saved palette yet — starting from Pywal."
        starter="Start from Pywal (recommended)"
    else
        while IFS= read -r line; do
            slot=${line%%:*}
            hex=${line#*: }
            SLOT_HEX[$slot]=$hex
        done < <(jq -r '.base16 | to_entries[] | "\(.key): \(.value)"' "$USER_PALETTE")
    fi
fi

if [[ "$starter" == "Start from Pywal (recommended)" ]]; then
    while IFS= read -r line; do
        slot=${line%%:*}
        hex=${line#*: }
        SLOT_HEX[$slot]=$hex
    done < <(echo "$preview_json" | jq -r '.wal.base16 | to_entries[] | "\(.key): \(.value)"')
elif [[ "$starter" == "Start from Matugen default" ]]; then
    while IFS= read -r line; do
        slot=${line%%:*}
        hex=${line#*: }
        SLOT_HEX[$slot]=$hex
    done < <(echo "$preview_json" | jq -r '.matugen.base16 | to_entries[] | select(.key|startswith("_")|not) | "\(.key): \(.value)"')
fi

mapfile -t POOL < <(unique_pool "$preview_json")
if [[ ${#POOL[@]} -eq 0 ]]; then
    gum style --foreground 1 "No colors in pool."
    exit 1
fi

pool_options=()
for hx in "${POOL[@]}"; do
    swatch=$(color_swatch "$hx")
    pool_options+=("${swatch}  ${hx}")
done

mapfile -t ROLE_LINES < <(jq -r '.roles[] | "\(.slot)|\(.label)|\(.hint)"' "$ROLES_FILE")

gum style --bold "Assign roles — pick a real wallpaper color for each slot"
echo "(These map to base16. All templates source the same slots.)"
echo

for entry in "${ROLE_LINES[@]}"; do
    IFS='|' read -r slot label hint <<<"$entry"
    current="${SLOT_HEX[$slot]:-#888888}"
    swatch=$(color_swatch "$current")
    gum style --foreground 8 "${label} (${slot})"
    gum style --faint "  ${hint}"
    gum style "  Current: ${swatch}  ${current}"

    options=("${pool_options[@]}")
    options+=("Keep current (${current})")

    pick=$(gum choose "${options[@]}" --header "Color for: ${label}" 2>/dev/null || echo "Keep current (${current})")
    if [[ "$pick" != Keep\ current* ]]; then
        chosen=$(sed -n 's/.*  \(\#[0-9A-Fa-f]\{6\}\)$/\1/p' <<<"$pick")
        [[ -n "$chosen" ]] && SLOT_HEX[$slot]=$chosen
    fi
    echo
done

gum style --bold "Preview — key slots"
for slot in base00 base02 base0d base05 base08; do
    hx="${SLOT_HEX[$slot]:-#888888}"
    printf "  %s  %s  %s\n" "$slot" "$(color_swatch "$hx")" "$hx"
done
echo

save_target=$(gum choose \
    "Save as named configuration + apply" \
    "Apply now (session only)" \
    "Save to active theme slot + apply" \
    "Cancel" \
    --header "Where should this palette live?")
[[ "$save_target" == "Cancel" || -z "$save_target" ]] && { echo "Cancelled."; exit 0; }

CONFIG_NAME=""
CONFIG_LABEL=""
if [[ "$save_target" == "Save as named configuration + apply" ]]; then
    CONFIG_NAME=$(gum input --placeholder "e.g. coast-warm-evening" --header "Configuration name") || CONFIG_NAME=""
    if [[ -z "$CONFIG_NAME" ]]; then
        gum style --foreground 3 "No name — cancelled."
        exit 0
    fi
    CONFIG_LABEL=$(gum input --value "$CONFIG_NAME" --header "Display label (optional)") || CONFIG_LABEL="$CONFIG_NAME"
fi

for slot in "${!SLOT_HEX[@]}"; do
    export "SLOT_${slot^^}=${SLOT_HEX[$slot]}"
done

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
    if val and val.startswith("#"):
        base16[slot] = val

payload = {
    "version": 1,
    "wallpaper": wallpaper,
    "saved_at": datetime.now(timezone.utc).isoformat(),
    "source": "custom",
    "base16": base16,
}
with open(out_path, "w", encoding="utf-8") as f:
    json.dump(payload, f, indent=2)
    f.write("\n")
PY

if [[ "$save_target" == "Save as named configuration + apply" ]]; then
    bash "$HOME/.config/colorschemes/colors-config.sh" save "$CONFIG_NAME" --label "$CONFIG_LABEL" --from session
    bash "$HOME/.config/colorschemes/colors-config.sh" load "$CONFIG_NAME" --no-wallpaper
    gum style --bold --foreground 2 "Saved and loaded configuration: $CONFIG_LABEL"
    exit 0
fi

if [[ "$save_target" == "Save to active theme slot + apply" ]]; then
    ACTIVE_THEME=""
    [[ -f "$HOME/.config/colorschemes/.current-theme" ]] && ACTIVE_THEME=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme")
    if [[ -z "$ACTIVE_THEME" ]]; then
        gum style --foreground 3 "No active theme — saved session palette only."
        mkdir -p "$(dirname "$COLOR_MODE_FILE")"
        echo saved >"$COLOR_MODE_FILE"
    else
        bash "$HOME/.config/colorschemes/save-theme-palette.sh" "$ACTIVE_THEME" "$USER_PALETTE"
        rm -f "$COLOR_MODE_FILE" 2>/dev/null || true
        touch "$HOME/.config/colorschemes/.use-preset-colors"
        echo "$ACTIVE_THEME" >"$HOME/.config/colorschemes/.current-theme"
        gum style --foreground 2 "Saved to theme: $ACTIVE_THEME"
        gum spin --spinner dot --title "Applying theme palette…" -- \
            bash "$HOME/.config/colorschemes/apply-theme.sh" "$ACTIVE_THEME" "$WALLPAPER"
        exit 0
    fi
else
    mkdir -p "$(dirname "$COLOR_MODE_FILE")"
    echo saved >"$COLOR_MODE_FILE"
fi

gum style --foreground 2 "Saved → $USER_PALETTE"
ACTIVE_THEME=""
[[ -f "$HOME/.config/colorschemes/.current-theme" ]] && ACTIVE_THEME=$(tr -d '[:space:]' <"$HOME/.config/colorschemes/.current-theme")
if [[ -n "$ACTIVE_THEME" ]]; then
    gum spin --spinner dot --title "Applying static palette…" -- \
        bash "$HOME/.config/colorschemes/colors-config.sh" apply-static "$ACTIVE_THEME" "$USER_PALETTE" "$WALLPAPER" ""
else
    gum spin --spinner dot --title "Applying palette…" -- \
        env MATUGEN_FORCE=1 MATUGEN_COLOR_MODE=custom MATUGEN_NONINTERACTIVE=1 "$APPLY" "$WALLPAPER"
fi

gum style --bold --foreground 2 "Done. Colors saved — no re-extract on wallpaper change."