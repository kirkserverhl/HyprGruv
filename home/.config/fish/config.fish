# Hyprgruv fish config — mirrors ~/.zshrc for a fair zsh vs fish comparison.
# Switch shells:  exec fish   (after system install)  or  exec ~/.local/bin/fish
# Restore zsh:    exec zsh    (default shell unchanged until you chsh)

if not contains -- $HOME/.grok/bin $PATH
    fish_add_path $HOME/.grok/bin
end