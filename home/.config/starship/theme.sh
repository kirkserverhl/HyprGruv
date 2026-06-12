#!/usr/bin/env bash
# theme.sh — Rofi picker for Starship themes with live prompt previews.
# Places the chosen .toml as the active Starship config via symlink.
# Default / pre-selected: matugen (matugen-rainbow.toml)
#
# Usage:
#   ~/.config/starship/theme.sh
#
# After switching, start a fresh shell (or exec $SHELL) to see the new prompt.

set -euo pipefail

STARSHIP_DIR="${STARSHIP_DIR:-$HOME/.config/starship}"
STARSHIP_LINK="$HOME/.config/starship.toml"

# Collect all theme files
mapfile -t TOMLS < <(find "$STARSHIP_DIR" -maxdepth 1 -type f -name '*.toml' -print 2>/dev/null | sort)

if [[ ${#TOMLS[@]} -eq 0 ]]; then
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Starship" "No .toml files found in $STARSHIP_DIR"
    else
        echo "No .toml files found in $STARSHIP_DIR" >&2
    fi
    exit 1
fi

# Robustly strip ANSI + zsh prompt length markers (%{...%}) for clean rofi display
sanitize() {
    sed -E '
        s/%\{[^%]*%\}//g;
        s/\x1b\[[0-9;]*m//g;
        s/\x1b\][0-9;]*\x07//g;
        s/\x1b\][^\x07]*\x07//g;
    ' | tr -d '\r' | tr '\n' ' ' | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//'
}

get_preview() {
    local cfg="$1"
    local preview
    # Force a good TERM so starship doesn't think it's dumb and disable modules.
    # Use controlled context for consistent, comparable previews across themes.
    preview=$(TERM=xterm-256color STARSHIP_CONFIG="$cfg" \
        starship prompt \
        -s 0 \
        -w 95 \
        -p "$HOME" \
        -d 1250 \
        -j 0 \
        2>/dev/null | sanitize || true)

    if [[ -z "${preview:-}" ]]; then
        preview="  user    ~/dir   main  ❯"
    fi

    # Trim very long previews for the menu
    if ((${#preview} > 92)); then
        preview="${preview:0:89}…"
    fi

    echo "$preview"
}

# Build display lines + lookup map:  "name   │   preview"
declare -A display_to_path
menu_lines=()

for t in "${TOMLS[@]}"; do
    name="$(basename "$t" .toml)"
    preview="$(get_preview "$t")"
    # Use a clear separator that looks good in rofi lists
    line="${name}   │   ${preview}"
    display_to_path["$line"]="$t"
    menu_lines+=("$line")
done

# Pick a reasonable rofi config (themes/compact/short all work for lists)
rofi_cfg=""
for cand in \
    "$HOME/.config/rofi/config-themes.rasi" \
    "$HOME/.config/rofi/config-compact.rasi" \
    "$HOME/.config/rofi/config-short.rasi" \
    "$HOME/.config/rofi/config.rasi"
do
    [[ -f "$cand" ]] && { rofi_cfg="$cand"; break; }
done

# Extra styling: wider window so the prompt previews are readable.
# listview lines tuned for ~25 themes.
extra_theme='
    window { width: 860px; border-radius: 12px; }
    listview { lines: 14; spacing: 2px; }
    element { padding: 7px 12px; }
    element-text { font: "JetBrainsMono Nerd Font 11"; }
'

# Launch rofi.
# -select "matugen" ensures the matugen-* entry is pre-selected by default.
chosen_display=$(printf '%s\n' "${menu_lines[@]}" | \
    rofi -dmenu -i \
        -p "Starship Theme" \
        ${rofi_cfg:+-config "$rofi_cfg"} \
        -theme-str "$extra_theme" \
        -no-show-icons \
        -no-custom \
        -select "matugen" \
        2>/dev/null || true)

[[ -z "$chosen_display" ]] && exit 0

chosen_path="${display_to_path[$chosen_display]:-}"

# Fallback recovery if the map lookup somehow misses (whitespace etc.)
if [[ -z "$chosen_path" || ! -f "$chosen_path" ]]; then
    name_guess="${chosen_display%%   │*}"
    candidate="$STARSHIP_DIR/${name_guess}.toml"
    if [[ -f "$candidate" ]]; then
        chosen_path="$candidate"
    else
        if command -v notify-send >/dev/null 2>&1; then
            notify-send "Starship" "Could not resolve selected theme"
        fi
        exit 1
    fi
fi

# Install as the active config via symlink (matches the rest of the rice)
mkdir -p "$(dirname "$STARSHIP_LINK")"
[[ -e "$STARSHIP_LINK" || -L "$STARSHIP_LINK" ]] && rm -f "$STARSHIP_LINK"
ln -sfn "$chosen_path" "$STARSHIP_LINK"

chosen_name="$(basename "$chosen_path")"
msg="Starship prompt → ${chosen_name}"

if command -v notify-send >/dev/null 2>&1; then
    notify-send "Starship" "$msg"
else
    echo "$msg"
fi

echo "$msg"
echo "Active config: $STARSHIP_LINK -> $chosen_path"
echo "Tip: exec \$SHELL   (or open a new terminal) to load the new prompt."
