#!/bin/bash

# Function to display the header using figlet
# Clears the screen and displays the header
function display_header() {
	clear
	figlet -f ~/.fonts/Graffiti.flf "$1"
}

# Main script logic
echo
# ------------------------------------------------
# Script to create ASCII font-based header on user input
# and copy the result to the clipboard
# -----------------------------------------------------

# Prompt the user for input
read -p "Enter the text for ASCII encoding: " mytext

# Display the header
if [ -n "$mytext" ]; then
	display_header "$mytext"
else
	echo "No text entered. Exiting."
	exit 1
fi

# Save the output to a file
output_file=~/figlet.txt
echo "Saving output to $output_file..."
figlet -f ~/.fonts/Graffiti.flf "$mytext" >"$output_file"

echo "Contents of the file:"
cat "$output_file"

# Copy the output to the clipboard
if command -v wl-copy &>/dev/null; then
	wl-copy <"$output_file"
	echo "Text copied to clipboard (wl-copy)."
elif command -v xclip &>/dev/null; then
	xclip -sel clip <"$output_file"
	echo "Text copied to clipboard (xclip)."
else
	echo "Clipboard tool not found. Please install 'wl-copy' or 'xclip'."
fi
