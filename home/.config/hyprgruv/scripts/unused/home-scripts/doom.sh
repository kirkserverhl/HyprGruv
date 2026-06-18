#!/bin/bash

# Define the repository URL and target directory
REPO_URL="https://github.com/cryptocode/terminal-doom.git"
TARGET_DIR="$HOME/terminal-doom"

# Check if zig is installed
if ! command -v zig &> /dev/null; then
    echo "Zig is not installed. Installing Zig..."
    sudo pacman -Sy --noconfirm zig || {
        echo "Failed to install Zig. Please install it manually.";
        exit 1;
    }
fi

# Check if the terminal-doom repository exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning terminal-doom repository..."
    git clone "$REPO_URL" "$TARGET_DIR" || {
        echo "Failed to clone the repository. Please check your internet connection and try again.";
        exit 1;
    }
    
    echo "Repository cloned successfully."
fi

# Navigate to the terminal-doom directory
cd "$TARGET_DIR" || {
    echo "Failed to access the terminal-doom directory.";
    exit 1;
}

# Build the project
if [ ! -f "zig-out/bin/terminal-doom" ]; then
    echo "Building terminal-doom..."
    zig build -Doptimize=ReleaseFast || {
        echo "Build failed. Please check the error messages above and fix them.";
        exit 1;
    }
    echo "Build completed successfully."
fi

# Run the application
echo "Running terminal-doom..."
./zig-out/bin/terminal-doom

