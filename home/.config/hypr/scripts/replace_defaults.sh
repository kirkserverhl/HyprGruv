#!/bin/bash

# Run in ~ or adjust paths
DIR="$HOME/.hyprgruv"
DEFAULTS_DIR="$HOME/defaults" # Adjust if defaults elsewhere

# Find matches for ghostty or firefox
matches=$(grep -rE "(kitty|firefox)" "$DIR" | fzf --multi --preview 'echo {}')

# Replace in selected
while IFS= read -r match; do
    file=$(echo "$match" | cut -d: -f1)
    sed -i 's/ghostty/$($DEFAULTS_DIR\/terminal.sh)/g' "$file"
    sed -i 's/firefox/$($DEFAULTS_DIR\/browser.sh)/g' "$file"
done <<<"$matches"

echo "Replacements done in $DIR."
