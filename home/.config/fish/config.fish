# Hyprgruv fish config — mirrors ~/.zshrc for a fair zsh vs fish comparison.
# Switch shells:  exec fish   (after system install)  or  exec ~/.local/bin/fish
# Restore zsh:    exec zsh    (default shell unchanged until you chsh)

set -g fish_greeting

if not contains -- $HOME/.grok/bin $PATH
    fish_add_path $HOME/.grok/bin
end

if test -f ~/.config/fish/aliases.fish
    source ~/.config/fish/aliases.fish
end

# Quick notes: functions/note.fish (na) and functions/nf.fish (nf)
abbr --add na note
abbr --add nf nf


