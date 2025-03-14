#!/bin/bash

# Path to the decoration config file
DECORATION_CONF=~/.config/hypr/conf/decorations.conf

# List of decoration files to cycle through
DECORATION_OPTION=(
  "default.conf"
  "no-rounding.conf"
  "no-rounding-more-blur.conf"
  "rounding.conf"
  "rounding-all-blur.conf"
  "rounding-all-blur-no-shadows.conf"
  "rounding-more-blur.conf"
)

# Extract the current source file from the decoration.conf
CURRENT_FILE=$(grep "source" "$DECORATION_CONF" | awk -F= '{print $2}' | xargs)

# Get the index of the current file in the options array
CURRENT_INDEX=-1
for i in "${!DECORATION_OPTION[@]}"; do
  if [[ "$CURRENT_FILE" == "~/.config/hypr/conf/decorations/${DECORATION_OPTION[$i]}" ]]; then
    CURRENT_INDEX=$i
    break
  fi
done

# Calculate the index of the next file
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#DECORATION_OPTION[@]} ))

# Update the decoration.conf file
echo "source = ~/.config/hypr/conf/decorations/${DECORATION_OPTION[$NEXT_INDEX]}" > "$DECORATION_CONF"

# Extract the decoration title (remove ".conf" and replace "-" with " ")
DECORATION_TITLE=$(echo "${DECORATION_OPTION[$NEXT_INDEX]%.conf}" | sed 's/-/ /g')

# Send a dunst notification
dunstify -u normal "Decorations Changed To" "$DECORATION_TITLE"

echo "Decoration source updated to ${DECORATION_OPTION[$NEXT_INDEX]}"

