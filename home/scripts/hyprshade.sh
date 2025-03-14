#!/bin/bash

# Define the available themes
themes=("blue-light-filter-25" "blue-light-filter-50" "blue-light-filter-75")

# Get the current theme from hyprshade
current_theme=$(hyprshade current)

# Find the index of the current theme in the themes array
current_index=-1
for i in "${!themes[@]}"; do
    if [[ "${themes[$i]}" == "$current_theme" ]]; then
        current_index=$i
        break
    fi
done

# If the current theme is the last one, turn off the filter
if [[ $current_index -eq 2 ]]; then
    hyprshade off
    dunstify -u normal "Hyprshade" "Blue light filter turned off"
else
    # Set the next theme in the array
    next_index=$((current_index + 1))
    hyprshade on "${themes[$next_index]}"
    dunstify -u normal "Hyprshade" "Blue light filter set to ${themes[$next_index]}"
fi

