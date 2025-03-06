#!/bin/bash

# Define asset paths
ASSET_DIR="$HOME/.hyprgruv/assets/sddm"
SDDM_BG_JPG="$ASSET_DIR/sddm.jpg"
THEME_CONF="$ASSET_DIR/theme.conf"
SDDM_CONF_DIR="$ASSET_DIR"

# Function to move and overwrite files
move_file() {
  local src=$1
  local dest=$2
  echo "Moving $src to $dest..."
  sudo cp -f "$src" "$dest"
}

# Function to move and overwrite directories
move_dir() {
  local src=$1
  local dest=$2
  echo "Removing existing directory $dest if present..."
  sudo rm -rf "$dest"
  echo ""
  echo "Moving $src to $dest..."
  echo ""
  sudo cp -rf "$src" "$dest"
}

# Function to attempt package installation
install_package() {
  local package=$1
  echo "Attempting to install $package..."
  if yay -S --noconfirm "$package"; then
    echo "$package installed successfully."
    return 0
  else
    echo "Failed to install $package."
    return 1
  fi
}

# Check if packages are installed, attempt to install if not
if ! pacman -Q sddm-sugar-candy-git >/dev/null 2>&1 && ! pacman -Q sddm-theme-sugar-candy-git >/dev/null 2>&1; then
  echo "Neither sddm-sugar-candy-git nor sddm-theme-sugar-candy-git is installed."
  if install_package "sddm-sugar-candy-git"; then
    PACKAGE="sddm-sugar-candy-git"
  elif install_package "sddm-theme-sugar-candy-git"; then
    PACKAGE="sddm-theme-sugar-candy-git"
  else
    echo "Failed to install either package. Exiting."
    exit 1
  fi
else
  if pacman -Q sddm-sugar-candy-git >/dev/null 2>&1; then
    PACKAGE="sddm-sugar-candy-git"
  else
    PACKAGE="sddm-theme-sugar-candy-git"
  fi
fi

# Proceed based on the installed package
if [ "$PACKAGE" == "sddm-sugar-candy-git" ]; then
  echo "Detected sddm-sugar-candy-git installed."

  # Move sddm.jpg
  move_file "$SDDM_BG_JPG" "/usr/share/sddm/themes/sugar-candy/Backgrounds/sddm.jpg"

  # Move theme.conf
  move_file "$THEME_CONF" "/usr/share/sddm/themes/sugar-candy/theme.conf"

  # Move sddm.conf.d
  move_dir "$SDDM_CONF_DIR/sddm.conf.d" "/usr/lib/sddm/sddm.conf.d"

elif [ "$PACKAGE" == "sddm-theme-sugar-candy-git" ]; then
  echo "Detected sddm-theme-sugar-candy-git installed."

  # Move sddm.jpg
  move_file "$SDDM_BG_JPG" "/usr/share/sddm/themes/Sugar-Candy/Backgrounds/sddm.jpg"

  # Move theme.conf
  move_file "$THEME_CONF" "/usr/share/sddm/themes/Sugar-Candy/theme.conf"

  # Move sddm.conf.d.theme and rename to sddm.conf.d
  move_dir "$SDDM_CONF_DIR/sddm.conf.d.theme" "/usr/lib/sddm/sddm.conf.d"
fi

# Completion message
echo "SDDM theme installation complete."
echo "You can test the theme using the command: sudo sddm --test-mode"
echo "To exit the test, press Ctrl+C."

exit 0
