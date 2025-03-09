#!/bin/bash

# Set gum theme based on colors.css variables
export GUM_CONFIRM_PROMPT="? Would you like to perform a system cleanup? "
export GUM_CONFIRM_SELECTED_BACKGROUND="#458588"   # Using --color5 (teal)
export GUM_CONFIRM_SELECTED_FOREGROUND="#0f1010"   # Using --background
export GUM_CONFIRM_UNSELECTED_BACKGROUND="#0f1010" # Using --background
export GUM_CONFIRM_UNSELECTED_FOREGROUND="#c3c3c3" # Using --foreground

# Set other gum colors for consistency
export GUM_INPUT_CURSOR_FOREGROUND="#c3c3c3" # Using --cursor
export GUM_INPUT_PROMPT_FOREGROUND="#8FC17B" # Using --color3 (green)
export GUM_SPIN_SPINNER_FOREGROUND="#749D91" # Using --color6 (cyan)

# Function to display headers
display_header() {
  figlet -f ~/.fonts/Graffiti.flf "$1" | lsd-print
}
display_header "SHELL"
echo ""
echo "Please select your preferred shell" | lsd-print
echo ""
shell=$(gum choose "bash" "zsh" "CANCEL")

# -----------------------------------------------------
# Activate bash
# -----------------------------------------------------
if [[ $shell == "bash" ]]; then

  # Change shell to bash
  while ! chsh -s $(which bash); do
    echo "ERROR - Authentication failed. Please enter the correct password."
    sleep 1
  done
  echo "Shell is now bash."  | lsd-print

  gum spin --spinner dot --title "Please reboot your system." -- sleep 3
  _selectCategory

# -----------------------------------------------------
# Activate zsh
# -----------------------------------------------------
elif [[ $shell == "zsh" ]]; then

  # Change shell to shh
  while ! chsh -s $(which zsh); do
    echo "ERROR - Authentication failed. Please enter the correct password."
    sleep 1
  done
  echo "Shell is now zsh."  | lsd-print

  # Installing zsh-autosuggestions
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
    echo "Installing zsh-autosuggestions"  | lsd-print
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  else
    echo "zsh-autosuggestions already installed"  | lsd-print
  fi

  # Installing zsh-syntax-highlighting
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
    echo "Installing zsh-syntax-highlighting"  | lsd-print
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  else
    echo "zsh-syntax-highlighting already installed"  | lsd-print
  fi

  # Installing fast-syntax-highlighting
  if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/fast-syntax-highlighting" ]; then
    _writeMessage "Installing fast-syntax-highlighting"
    git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
  else
    echo "fast-syntax-highlighting already installed"  | lsd-print
  fi

  gum spin --spinner dot --title "Please reboot your system." -- sleep 3
  # _selectCategory
# -----------------------------------------------------
# Cencel
# -----------------------------------------------------
else
  echo "Changing shell canceled"  | lsd-print
  exit
fi
