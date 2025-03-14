#!/bin/bash

# Source directory
SOURCE_DIR="$HOME/.dotfiles/assets/setup_script"

# Target directory where scripts will be symlinked
TARGET_DIR="$HOME/scripts"

# Ensure the target directory exists
mkdir -p "$TARGET_DIR"

# Symlink all files from source to target
for file in "$SOURCE_DIR"/*; do
    if [[ -f "$file" || -x "$file" ]]; then
        ln -sf "$file" "$TARGET_DIR/$(basename "$file")"
    fi
done

echo "Symlinked setup scripts to $TARGET_DIR."

