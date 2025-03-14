#!/bin/bash
# Set gum theme based on colors.css variables
#export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
#export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"   # Using --color5 (teal)
#export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"   # Using --background
#export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010" # Using --background
#export GUM_CONFIRM_UNSELECTED_FOREGROUND="#282828" # Using --foreground

# Set other gum colors for consistency
#export GUM_INPUT_CURSOR_FOREGROUND="#282828" # Using --cursor
#export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B" # Using --color3 (green)
#export GUM_SPIN_SPINNER_FOREGROUND="#749D91" # Using --color6 (cyan)

# Directory containing your theme files
THEMES_DIR="$HOME/.config/starship"

# Default Starship config location
STARSHIP_CONFIG="$HOME/.config/starship.toml"

# Create themes directory if it doesn't exist
mkdir -p "$THEMES_DIR"

# If no themes exist yet, create a backup of current config
if [ ! "$(ls -A "$THEMES_DIR" 2>/dev/null)" ]; then
	if [ -f "$STARSHIP_CONFIG" ]; then
		cp "$STARSHIP_CONFIG" "$THEMES_DIR/default.toml"
		echo "Backed up current config as 'default.toml'"
	fi
fi

# Use gum to select a theme
echo "Select a Starship theme:"
SELECTED_THEME=$(gum choose --height 15 $(ls "$THEMES_DIR"))

if [ -n "$SELECTED_THEME" ]; then
	# Make sure the starship config directory exists
	mkdir -p "$(dirname "$STARSHIP_CONFIG")"

	# Remove existing symlink or file
	if [ -e "$STARSHIP_CONFIG" ]; then
		rm "$STARSHIP_CONFIG"
	fi

	# Create symlink to selected theme
	ln -s "$THEMES_DIR/$SELECTED_THEME" "$STARSHIP_CONFIG"

	echo "Switched to theme: $SELECTED_THEME"
	echo "Restart your shell or source your shell config to apply changes"
else
	echo "No theme selected"
fi
