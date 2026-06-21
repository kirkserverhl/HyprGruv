# Abbreviations (mirrors ~/.zshrc)

# Hyprgruv deployment (desktop → git → laptop)
abbr --add hgpkg 'bash ~/.hyprgruv/sync-packages.sh'
abbr --add hgadd 'bash ~/.hyprgruv/sync-packages.sh add'
abbr --add hgdeploy 'bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh --full'
abbr --add hgupdates 'bash ~/.hyprgruv/lib/scripts/repo-update-check.sh --prompt'

# bat / pager (BAT_THEME lives in 10-environment.fish)
if command -v bat >/dev/null
    abbr --add cat 'bat -pp'
    abbr --add less 'bat'
else
    abbr --add less 'less -R'
end

# Directory navigation
abbr --add .. 'cd ..; and ls'
abbr --add ... 'cd ../..; and ls'
abbr --add .... 'cd ../../..; and ls'
abbr --add ..... 'cd ../../../../..; and ls'
abbr --add bd 'cd $oldpwd'

# General
abbr --add rmd '/bin/rm -rfv'
abbr --add hypr '$EDITOR ~/.config/hypr/'
abbr --add hyprstow '$HOME/bin/migrate-config-to-stow'
abbr --add c 'clear; exec fish'
abbr --add ff 'fastfetch'
abbr --add tm 'tmux'

abbr --add gs 'git status'
abbr --add ga 'git add'
abbr --add gc 'git commit -m'
abbr --add gp 'git push'
abbr --add gpl 'git pull'
abbr --add gsp 'git stash; and git pull'
abbr --add ping 'ping -c 5'
abbr --add fastping 'ping -c 100 -i .2'
abbr --add keybinds 'nvim ~/.config/hypr/conf/keybinds.lua'
abbr --add reload 'hyprctl reload'
abbr --add hyprscripts '$EDITOR ~/.config/hyprgruv/scripts'

# YAY
abbr --add i 'yay -S'
abbr --add r 'yay -Rns'
abbr --add u 'yay -Syu'
abbr --add s 'yay -Ss'
abbr --add q 'yay -Q'

# eza (must be defined — OMZ overrides ls in zsh; fish has no such conflict)
if command -v eza >/dev/null
    abbr --add ls 'eza -a --icons'
    abbr --add ll 'eza -al --icons'
    abbr --add la 'eza -Alh --icons'
    abbr --add lls 'eza -l --icons'
    abbr --add ldir "eza -l --icons | egrep '^d'"
else
    abbr --add ls 'ls --color=auto -A'
    abbr --add ll 'ls --color=auto -al'
end

# Matugen palette output
abbr --add palette '~/.config/hyprgruv/scripts/palette.sh'

# Errors
abbr --add hyprerror 'hyprctl configerrors'

# Unlock faillock
abbr --add unlock '~/.config/hyprgruv/scripts/unlockroot.sh'
abbr --add fail 'faillock --reset'
abbr --add cleanup '~/.hyprgruv/lib/scripts/cleanup.sh'
abbr --add doom '~/.config/hyprgruv/scripts/unused/home-scripts/doom.sh'
abbr --add updates '~/.config/hyprgruv/scripts/installupdates.sh'

abbr --add whatismyip 'whatsmyip'

# Zoxide shortcuts (init runs in 40-interactive.fish)
if command -v zoxide >/dev/null
    abbr --add za 'zoxide add'
    abbr --add zr 'zoxide remove'
    abbr --add zl 'zoxide query -l'
    abbr --add zi 'zoxide query -i'
end

# User-defined abbreviations (via `ali` command)
if test -f ~/.config/fish/aliases.fish
    source ~/.config/fish/aliases.fish
end