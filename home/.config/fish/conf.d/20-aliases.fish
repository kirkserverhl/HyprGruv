# Aliases (mirrors ~/.zshrc)

# Hyprgruv deployment (desktop → git → laptop)
alias hgpkg='bash ~/.hyprgruv/sync-packages.sh'
alias hgadd='bash ~/.hyprgruv/sync-packages.sh add'
alias hgdeploy='bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh --full'
alias hgupdates='bash ~/.hyprgruv/lib/scripts/repo-update-check.sh --prompt'

# bat / pager (BAT_THEME lives in 10-environment.fish)
if command -v bat >/dev/null
    alias cat='bat -pp'
    alias less='bat'
else
    alias less='less -R'
end

# Directory navigation
alias ..='cd ..; and ls'
alias ...='cd ../..; and ls'
alias ....='cd ../../..; and ls'
alias .....='cd ../../../../..; and ls'
alias bd='cd $oldpwd'

# General
alias rmd='/bin/rm -rfv'
alias hypr='$EDITOR ~/.config/hypr/'
alias hyprstow='$HOME/bin/migrate-config-to-stow'
alias c='clear; exec fish'
alias ff='fastfetch'
alias tm='tmux'

alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gsp='git stash; and git pull'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'
alias keybinds='nvim ~/.config/hypr/conf/keybinds.lua'
alias reload='hyprctl reload'
alias hyprscripts='$EDITOR ~/.config/hyprgruv/scripts'

# YAY
alias i='yay -S'
alias r='yay -Rns'
alias u='yay -Syu'
alias s='yay -Ss'
alias q='yay -Q'

# eza (must be defined — OMZ overrides ls in zsh; fish has no such conflict)
if command -v eza >/dev/null
    alias ls='eza -a --icons'
    alias ll='eza -al --icons'
    alias la='eza -Alh --icons'
    alias lls='eza -l --icons'
    alias ldir="eza -l --icons | egrep '^d'"
else
    alias ls='ls --color=auto -A'
    alias ll='ls --color=auto -al'
end

# Matugen palette output
alias palette='~/.config/hyprgruv/scripts/palette.sh'

# Errors
alias hyprerror='hyprctl configerrors'

# Unlock faillock
alias unlock='~/.config/hyprgruv/scripts/unlockroot.sh'
alias fail='faillock --reset'
alias cleanup='~/.hyprgruv/lib/scripts/cleanup.sh'
alias doom='~/.config/hyprgruv/scripts/unused/home-scripts/doom.sh'
alias updates='~/.config/hyprgruv/scripts/installupdates.sh'

alias whatismyip='whatsmyip'

# Zoxide shortcuts (init runs in 40-interactive.fish)
if command -v zoxide >/dev/null
    alias za='zoxide add'
    alias zr='zoxide remove'
    alias zl='zoxide query -l'
    alias zi='zoxide query -i'
end