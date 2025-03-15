# Directory containing your theme files
MONITOR_DIR="$HOME/.config/hypr/conf/monitors/"

# Default Monitor config location
MONITOR_CONFIG="$HOME/.config/hypr/conf/monitor.conf"

# Create monitor directory if it doesn't exist
mkdir -p "$MONITOR_DIR"

# If no themes exist yet, create a backup of current config
if [ ! "$(ls -A "$MONITOR_DIR" 2>/dev/null)" ]; then
	if [ -f "$MONITOR_CONFIG" ]; then
		cp "$MONITOR_CONFIG" "$MONITOR_DIR/default.toml"
		echo "Backed up current config as 'default.toml'"
	fi
fi

# Use gum to select a theme
echo "Select a Monitor Configuraiton:"
SELECTED_THEME=$(gum choose --height 5 $(ls "$MONITOR_DIR"))

if [ -n "$SELECTED_MONITOR" ]; then
	# Make sure the monitor config directory exists
	mkdir -p "$(dirname "$MONITOR_CONFIG")"

	# Remove existing symlink or file
	if [ -e "$MONITOR_CONFIG" ]; then
		rm "$MONITOR_CONFIG"
	fi

	# Create symlink to selected theme
	ln -s "$MONITOR_DIR/$SELECTED_MONITOR" "$MONITOR_CONFIG"

	echo "Switched to theme: $SELECTED_MONITOR"
	echo "Restart your shell or source your shell config to apply changes"
else
	echo "No theme selected"
fi
