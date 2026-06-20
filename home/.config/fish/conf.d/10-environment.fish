# Core environment (mirrors ~/.zshrc "Core Environment" + ~/.zshenv)

fish_add_path $HOME/bin $HOME/scripts $HOME/.local/bin

set -gx QT_QPA_PLATFORMTHEME qt6ct
set -gx COLORTERM truecolor

function _hyprgruv_read_setting -a name fallback
    set -l file "$HOME/.config/settings/$name.sh"
    if test -f $file
        set -l value (string trim (cat $file))
        if test -n "$value"
            echo $value
            return
        end
    end
    echo $fallback
end

set -gx TERMINAL (_hyprgruv_read_setting terminal kitty)
set -gx BROWSER (_hyprgruv_read_setting browser firefox)
set -gx EDITOR (_hyprgruv_read_setting editor nvim)
set -gx SUDO_EDITOR $EDITOR

if command -v bat >/dev/null
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    set -gx BAT_THEME Matugen
end

# GPG / SSH agent
set -gx GPG_TTY (tty)
set -gx SSH_AUTH_SOCK (gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent >/dev/null 2>&1

# History (mirrors zsh HISTSIZE / hist_ignore_space)
set -g fish_history_max 200000

if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
else if test -f "$HOME/.cargo/env"
    set -l cargo_home "$HOME/.cargo"
    if not contains -- $cargo_home/bin $PATH
        fish_add_path $cargo_home/bin
    end
end

if test -f "$HOME/.atuin/bin/env.fish"
    source "$HOME/.atuin/bin/env.fish"
else if test -d "$HOME/.atuin/bin"
    fish_add_path "$HOME/.atuin/bin"
end