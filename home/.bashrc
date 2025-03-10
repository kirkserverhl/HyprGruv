###-----------------------------------------------------###
### INIT
###-----------------------------------------------------###
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/scripts:$PATH"
export PYWAL='~/.cache/wal/colors.sh'

### ----------------------------------------------------- ###
### ALIASES
### ---------------------------------------------------- ###
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
alias ln='ln -i'
alias mkdir='mkdir -pv'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../../..'
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'

# Productivity
alias c='clear && $SHELL'
alias ts='~/scripts/snapshot.sh'
alias cleanup='~/scripts/cleanup.sh'
alias update='~/scripts/system_cleanup_and_update.sh'
alias monitor='~/scripts/monitor.sh'
alias zsh='nvim ~/.zshrc'
alias zz='~/scripts/yazi.sh'

# Color
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias ls='eza --long --color = always -- icons= --no-user'
alias woah='| lsd-print'

# System Commands
alias shutdown='systemctl poweroff'

# Miscellaneous
alias ff='fastfetch'

# Source Pywal Colors
source "$HOME/.cache/wal/colors-tty.sh"

###-----------------------------------------------------
### Starship
### -----------------------------------------------------
eval "$(starship init bash)"

## -----------------------------------------------------
## Terminal Customization
## -----------------------------------------------------
clear
ff && fortune | lsd-print
