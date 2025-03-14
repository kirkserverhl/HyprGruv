#!/bin/bash


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
sleep .5
echo""
echo "Select a Starship theme:"
SELECTED_THEME=$(gum choose --height 15 $(ls "$THEMES_DIR"))
echo ""
sleep .5

if [ -n "$SELECTED_THEME" ]; then
    # Make sure the starship config directory exists
    mkdir -p "$(dirname "$STARSHIP_CONFIG")"

    # Remove existing symlink or file
    if [ -e "$STARSHIP_CONFIG" ]; then
        rm "$STARSHIP_CONFIG"
    fi

    # Create symlink to selected theme
    ln -s "$THEMES_DIR/$SELECTED_THEME" "$STARSHIP_CONFIG"
    sleep .5

    echo "Switched to theme: $SELECTED_THEME"
    echo "Restart your shell or source your shell config to apply changes"
else
    echo "No theme selected"
fi
