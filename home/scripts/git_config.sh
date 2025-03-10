#!/bin/bash

# Constants
EMAIL="kirkserverhl@gmail.com"
USERNAME="kirkserverhl"
REPO_URL="https://github.com/kirkserverhl/gruvbox.git"
CLONE_DIR="$HOME/.hyprgruv"

# Step 1: Install Git
if ! command -v git &>/dev/null; then
	echo "Git not found. Installing..." | lsd-print
	sudo pacman -S git --noconfirm
else
	echo "Git is already installed." | lsd-print
fi

# Step 2: Clone the Dotfiles Repository
if [ ! -d "$CLONE_DIR" ]; then
	echo "Cloning repository..." | lsd-print
	git clone "$REPO_URL" "$CLONE_DIR"
else
	echo "Repository already cloned." | lsd-print
fi

# Step 3: Create Symbolic Links
cd "$CLONE_DIR" || {
	echo "Failed to navigate to repository directory."
	exit 1
}
if command -v stow &>/dev/null; then
	echo "Creating symbolic links using stow..." | lsd-print
	stow .
else
	echo "GNU Stow not found. Creating symbolic links manually..." | lsd-print
	ln -sf "$CLONE_DIR/.config/somefile" "$HOME/.config/somefile"
fi

# Step 4: Generate SSH Key Pair
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
	echo "Generating SSH key..." | lsd-print
	ssh-keygen -t ed25519 -C "$EMAIL" -f "$SSH_KEY" -N ""
else
	echo "SSH key already exists." | lsd-print
fi

# Step 5: Add SSH Key to SSH Agent
eval "$(ssh-agent -s)"
ssh-add "$SSH_KEY"

# Step 6: Add SSH Key to GitHub
echo "Your SSH public key is:" | lsd-print
cat "$SSH_KEY.pub"
echo "Copy the above key and add it to GitHub at: https://github.com/settings/keys" | lsd-print
read -p "Press Enter after adding the key to GitHub."

# Step 7: Change Git Remote to SSH
GIT_SSH_REMOTE="git@github.com:$USERNAME/gruvbox.git"
echo "Setting git remote to SSH..." | lsd-print
git remote set-url origin "$GIT_SSH_REMOTE"

# Step 8: Test SSH Connection
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
	echo "SSH connection successful." | lsd-print
else
	echo "Error: SSH connection failed. Ensure the key is added to GitHub and try again." | lsd-print
	exit 1
fi

# Step 9: Set Up a .gitignore File
echo "Setting up .gitignore..." | lsd-print
cat <<EOL >.gitignore
# Ignore system-specific files
.DS_Store
Thumbs.db

# Ignore logs
*.log

# Ignore sensitive files
secrets.env
private_key.pem
EOL

git add .gitignore
git commit -m "Add .gitignore file"

echo ".gitignore setup complete."

# Step 10: Push Changes
git add .
git commit -m "Initial configuration setup"
git push

echo "Setup complete!" | lsd-print
