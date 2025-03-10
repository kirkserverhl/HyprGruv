#!/bin/bash



# Get the image directory (modify as needed)

image_dir="$HOME/Pictures"



# List images

image_list=$(ls "$image_dir"/*.jpg)



# Display list with Rofi

selected_image=$(echo "$image_list" | rofi -dmenu -i)



# Open selected image with your image viewer

if [ -n "$selected_image" ]; then

    xdg-open "$selected_image"

fi
