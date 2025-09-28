#!/usr/bin/env bash
# starship_theme.sh — choose a starship theme and symlink it to ~/.config/starship.toml
set -euo pipefail
IFS=$'\n\t'

# Resolve repo root from lib/scripts/
HYPR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPO_THEMES_DIR="$HYPR_DIR/home/.config/starship"
USER_THEMES_DIR="$HOME/.config/starship"
STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Pick the source directory for themes: repo first, then user dir
if [[ -d "$REPO_THEMES_DIR" ]]; then
  THEMES_DIR="$REPO_THEMES_DIR"
elif [[ -d "$USER_THEMES_DIR" ]]; then
  THEMES_DIR="$USER_THEMES_DIR"
else
  mkdir -p "$USER_THEMES_DIR"
  THEMES_DIR="$USER_THEMES_DIR"
fi

# Ensure ~/.config exists
mkdir -p "$(dirname "$STARSHIP_CONFIG")"

# If no themes exist in THEMES_DIR yet, back up current config as default
if [[ -z "$(find "$THEMES_DIR" -maxdepth 1 -type f -name '*.toml' -print -quit 2>/dev/null)" ]]; then
  if [[ -f "$STARSHIP_CONFIG" ]]; then
    cp -a "$STARSHIP_CONFIG" "$THEMES_DIR/default.toml"
    echo "Backed up current config to: $THEMES_DIR/default.toml"
  fi
fi

# Build a list of theme files (*.toml)
mapfile -d '' THEMES < <(find "$THEMES_DIR" -maxdepth 1 -type f -name '*.toml' -print0 | sort -z)
if (( ${#THEMES[@]} == 0 )); then
  echo "No *.toml themes found in: $THEMES_DIR"
  exit 1
fi

# Pretty names for chooser
names=()
for t in "${THEMES[@]}"; do
  names+=("$(basename "$t")")
done

# Choose a theme: gum > fzf > numbered prompt
choose_with_gum() {
  command -v gum >/dev/null 2>&1 || return 1
  gum choose --height 20 "${names[@]}"
}
choose_with_fzf() {
  command -v fzf >/dev/null 2>&1 || return 1
  printf '%s\n' "${names[@]}" | fzf --prompt="Starship theme > " --height=20
}
choose_with_prompt() {
  echo "Select a Starship theme:"
  local i=1
  for n in "${names[@]}"; do
    printf '  %2d) %s\n' "$i" "$n"
    ((i++))
  done
  printf 'Enter number: '
  local sel
  read -r sel
  if [[ "$sel" =~ ^[0-9]+$ ]] && (( sel>=1 && sel<=${#names[@]} )); then
    echo "${names[$((sel-1))]}"
  else
    return 1
  fi
}

SELECTED="$(choose_with_gum || choose_with_fzf || choose_with_prompt || true)"
if [[ -z "${SELECTED:-}" ]]; then
  echo "No theme selected."
  exit 0
fi

# Create/replace the symlink at ~/.config/starship.toml
SRC="$THEMES_DIR/$SELECTED"
if [[ -e "$STARSHIP_CONFIG" || -L "$STARSHIP_CONFIG" ]]; then
  rm -f "$STARSHIP_CONFIG"
fi
ln -s "$SRC" "$STARSHIP_CONFIG"

echo "Switched Starship theme → $SELECTED"
echo "STARSHIP_CONFIG → $STARSHIP_CONFIG (symlink to $SRC)"
echo "Restart your shell or run:  exec \$SHELL"
