#!/bin/bash

# --- Load your existing helpers for consistent look ---
source "$HOME/.config/hypr/scripts/header.sh" 2>/dev/null || true
source "$HOME/.config/hypr/scripts/colors.sh" 2>/dev/null || true

# Fallback display_header only if header sourcing did not provide it (e.g. header.sh missing)
if ! declare -f display_header >/dev/null 2>&1 && ! declare -f print_header >/dev/null 2>&1; then
    display_header() {
        clear
        figlet -f ~/.fonts/Graffiti.flf "$1" 2>/dev/null || figlet "$1"
    }
fi

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
if [[ -n "$GRAFFITI_FONT" ]]; then
    figlet -f "$GRAFFITI_FONT" "$mytext" >"$output_file"
else
    figlet -f ~/.fonts/Graffiti.flf "$mytext" 2>/dev/null || figlet "$mytext" >"$output_file"
fi

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
