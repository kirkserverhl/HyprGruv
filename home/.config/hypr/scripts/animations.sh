#!/bin/bash

# Path to the animation configuration file
ANIMATION_CONF=~/.config/hypr/conf/animation.conf

# List of animation files to cycle through
ANIMATION_OPTIONS=(
  "animations-classic.conf"
  "animations-dynamic.conf"
  "animations-fast.conf"
  "animations-high.conf"
  "animations-moving.conf"
  "default.conf"
  "disabled.conf"
  "standard.conf"
)

# Extract the current source file from the animation.conf
CURRENT_FILE=$(grep "source" "$ANIMATION_CONF" | awk -F= '{print $2}' | xargs)

# Get the index of the current file in the options array
CURRENT_INDEX=-1
for i in "${!ANIMATION_OPTIONS[@]}"; do
  if [[ "~/.config/hypr/conf/animations/${ANIMATION_OPTIONS[$i]}" == "$CURRENT_FILE" ]]; then
    CURRENT_INDEX=$i
    break
  fi
done

# Calculate the index of the next file
NEXT_INDEX=$(( (CURRENT_INDEX + 1) % ${#ANIMATION_OPTIONS[@]} ))

# Update the animation.conf file
echo "source = ~/.config/hypr/conf/animations/${ANIMATION_OPTIONS[$NEXT_INDEX]}" > "$ANIMATION_CONF"

# Extract the animation title (remove ".conf" and replace "-" with " ")
ANIMATION_TITLE=$(echo "${ANIMATION_OPTIONS[$NEXT_INDEX]%.conf}" | sed 's/-/ /g')

# Send a dunst notification
dunstify -u normal "Animations Changed To" "$ANIMATION_TITLE"

echo "Animation source updated to ${ANIMATION_OPTIONS[$NEXT_INDEX]}"

