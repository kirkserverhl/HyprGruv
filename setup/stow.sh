#!/bin/bash
{
  #!/bin/bash

  REPO_DIR="$HOME/.hyprgruv"
  USER_HOME="$HOME"

  # Clone repository if it doesn't exist
  # if [ ! -d "$REPO_DIR" ]; then
  #     git clone https://github.com/kirkserverhl/hyorgruv "$REPO_DIR"
  # fi

  cd "$REPO_DIR" || exit

  # Backup existing files
  for file in $(ls -A "$REPO_DIR/home"); do
    if [ -e "$USER_HOME/$file" ]; then
      mv "$USER_HOME/$file" "$USER_HOME/${file}.bak"
    fi
  done

  # Stow home directory configs
  stow -t "$USER_HOME" home --adopt

}
