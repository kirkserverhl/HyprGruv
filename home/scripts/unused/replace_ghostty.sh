#!/bin/bash

# Find lines with ghostty
matches=$(grep -r --exclude-dir={defaults,.git} "ghostty" . | fzf --multi --preview 'echo {}')

# For each selected, replace
for match in "$matches"; do
  file=$(echo "$match" | cut -d: -f1)
  sed -i 's/ghostty/$(defaults\/terminal.sh)/g' "$file"
done

echo "Replacements done."
