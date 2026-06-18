#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if Zig is installed
if ! command_exists zig; then
    echo "Zig is not installed. Installing Zig..."
    
    # Install Zig on Arch Linux (adjust this for your specific setup if needed)
    if command_exists pacman; then
        sudo pacman -Syu --noconfirm zig
    else
        echo "Pacman package manager not found. Please install Zig manually."
        exit 1
    fi
else
    echo "Zig is already installed."
fi

# Clone Terminal Doom repository
echo "Cloning the Terminal Doom repository..."
git clone https://github.com/cryptocode/terminal-doom.git ~/terminal-doom

# Change directory to terminal-doom
cd ~/terminal-doom

# Build Terminal Doom using Zig
echo "Building Terminal Doom..."
zig build

# Check if the build was successful
if [ $? -eq 0 ]; then
    echo "Terminal Doom built successfully!"
else
    echo "Build failed. Please check the build logs."
    exit 1
fi

# Create an alias in the .zshrc file to launch Doom
echo "Creating an alias for Terminal Doom in ~/.zshrc..."
echo 'alias doom="~/terminal-doom/terminal-doom"' >> ~/.zshrc

# Inform the user to source the .zshrc file
echo "Alias 'doom' added. Please run 'source ~/.zshrc' to enable the alias."

# Optional: Provide instructions to reload the terminal or source the .zshrc file
echo "Done! You can now run 'doom' in the terminal to start Terminal Doom."

