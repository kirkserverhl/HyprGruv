# Interactive tools: fzf, zoxide, starship, thefuck, atuin, fastfetch, keybinds

# FZF key bindings (Arch ships these with the fzf package)
set -l _fzf_bindings /usr/share/fish/vendor_functions.d/fzf_key_bindings.fish
if not test -f $_fzf_bindings
    set _fzf_bindings "$HOME/.local/fish-root/usr/share/fish/vendor_functions.d/fzf_key_bindings.fish"
end
if test -f $_fzf_bindings
    source $_fzf_bindings
    fzf_key_bindings
end

if command -v zoxide >/dev/null
    zoxide init fish | source
end

if not set -q STARSHIP_CONFIG; or test -z "$STARSHIP_CONFIG"
    set -gx STARSHIP_CONFIG "$HOME/.config/starship/matugen-rainbow.toml"
end
if command -v starship >/dev/null
    starship init fish | source
end

if command -v thefuck >/dev/null
    thefuck --alias | source
end

if command -v atuin >/dev/null
    atuin init fish | source
end

# Control + Backspace → backward-kill-word (mirrors zsh bindkey '^H')
bind \cH backward-kill-word

# Fastfetch intro (plain kitty only — not tmux)
if test "$TERM" = kitty
    and isatty stdout
    and not set -q TMUX
    clear
    command -v fastfetch >/dev/null; and fastfetch
end