#!/bin/bash

SCRIPTS_DIR="$HOME/.hyprgruv/home/scripts"
HYPR_DIR="$HOME/.hyprgruv"
OUTPUT_FILE="$HOME/unused_scripts.txt"

# List all scripts in SCRIPTS_DIR (assuming .sh files)
scripts=$(find "$SCRIPTS_DIR" -type f -name "*.sh" -exec basename {} \;)

# Clear output file
> "$OUTPUT_FILE"

# For each script, check if referenced in HYPR_DIR
for script in $scripts; do
  if ! grep -qr "$script" "$HYPR_DIR"; then
    echo "$script" >> "$OUTPUT_FILE"
  fi
done

echo "Unused scripts listed in $OUTPUT_FILE"
