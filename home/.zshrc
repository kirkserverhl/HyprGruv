###-----------------------------------------------------###
### INIT
###-----------------------------------------------------###
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/scripts:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export QT_QPA_PLATFORMTHEME=qt5ct
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
alias fig='~/scripts/figlet.sh'
alias wifi='nmtui'
alias monitor='~/scripts/monitor.sh'
alias zsh='nvim ~/.zshrc'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'
alias rg='ranger'

# Color
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias ls='eza --long --color = always -- icons= --no-user'

# Git
alias gs="git status"
alias ga="git add"
alias add="cd ~/.dotfiles && git add ."
alias gc="git commit -m"
alias commit="cd ~/.dotfiles && git commit -m"
alias gp="git push"
alias gpl="git pull"
alias pull="git pull"
alias thinpull="git stash --include-untracked && git pull && git stash pop"
alias gst="git stash"
alias stash="git stash"
alias gsp="git stash; git pull"
alias gcheck="git checkout"
alias gall="git add -A"
alias gl="git log"
alias gll="git log --oneline"
alias push='git push origin main --force'

# System Commands
alias shutdown='systemctl poweroff'
alias update-grub='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias dusage='du -sh * 2>/dev/null'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'

# Miscellaneous
alias ff='fastfetch'
alias pf='pfetch'
alias tm='tmux -2'
alias ps='pacseek'
alias lp='lsd-print'
alias doom='~/scripts/doom.sh'

###-----------------------------------------------------
### Plugins and Features
###-----------------------------------------------------
plugins=( aliases archlinux bun cake coffee colored-man-pages colorize emoji emoji-clock eza fast-syntax-highlighting fig fzf git history history-substring-search kate kitty lol man nvm pip poetry pylint python ruby rust safe-paste shell-proxy ssh ssh-agent sudo supervisor thefuck themes tig tldr tmux vi-mode vim-interaction web-search zoxide zsh-autosuggestions zsh-navigation-tools zsh-syntax-highlighting
)
###-----------------------------------------------------
### Starship
### -----------------------------------------------------
eval "$(starship init zsh)"

### Load oh-my-zsh ###
{ source $ZSH/oh-my-zsh.sh
     zstyle ':omz:update' mode disabled
     ENABLE_CORRECTION="true"
     COMPLETION_WAITING_DOTS="%F{cyan}waiting...%f"
     DISABLE_UNTRACKED_FILES_DIRTY="true"
     zstyle ':completion:*' menu select
     ZSH_THEME=ultima
}

# FZF Integration
source <(fzf --zsh)

# ZSH History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# Dolphin 'Open With' fix
~/scripts/dolphin_fix.sh

# BAT Theme
export BAT_THEME="gruvbox-dark"

# Bun Completion
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# -----------------------------------------------------
# ZNT and Zharma
# -----------------------------------------------------

fpath=( "$fpath[@]" "$HOME/.config/znt/zsh-navigation-tools" )
autoload n-aliases n-cd n-env n-functions n-history n-kill n-list n-list-draw n-list-input n-options n-panelize n-help
autoload znt-usetty-wrapper znt-history-widget znt-cd-widget znt-kill-widget
alias naliases=n-aliases ncd=n-cd nenv=n-env nfunctions=n-functions nhistory=n-history
alias nkill=n-kill noptions=n-options npanelize=n-panelize nhelp=n-help
zle -N znt-history-widget
bindkey '^R' znt-history-widget
setopt AUTO_PUSHD HIST_IGNORE_DUPS PUSHD_IGNORE_DUPS
zstyle ':completion::complete:n-kill::bits' matcher 'r:|=** l:|=*'

#zmodload zsh/zpty
pty() {
	zpty pty-${UID} ${1+$@}
	if [[ ! -t 1 ]];then
		setopt local_traps
		trap '' INT
	fi
	zpty -r pty-${UID}
	zpty -d pty-${UID}
}

ptyless() {
	pty $@ | less
}

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} Te clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

### Load a few important annexes, without Turbo 
   zinit light-mode for\
      zdharma-continuum/zinit-annex-as-monitor \
      zdharma-continuum/zinit-annex-bin-gem-node \
      zdharma-continuum/zinit-annex-patch-dl \
      zdharma-continuum/zinit-annex-rust

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} Te clone has failed.%f%b"
fi

# Source Pywal Colors
  source "$HOME/.cache/wal/colors-tty.sh"
# KDE Neon
  alias update="yay -Syu && cleanup"

# -----------------------------------------------------
# ZNT and Zharma
# -----------------------------------------------------
 { fpath=( "$fpath[@]" "$HOME/.config/znt/zsh-navigation-tools" )
    autoload n-aliases n-cd n-env n-functions n-history n-kill n-list n-list-draw n-list-input n-options n-panelize n-help
    autoload znt-usetty-wrapper znt-history-widget znt-cd-widget znt-kill-widget
    alias naliases=n-aliases ncd=n-cd nenv=n-env nfunctions=n-functions nhistory=n-history
    alias nkill=n-kill noptions=n-options npanelize=n-panelize nhelp=n-help
    zle -N znt-history-widget
    bindkey '^R' znt-history-widget
    setopt AUTO_PUSHD HIST_IGNORE_DUPS PUSHD_IGNORE_DUPS
    zstyle ':completion::complete:n-kill::bits' matcher 'r:|=** l:|=*'
 }
#zmodload zsh/zpty
pty() {
	zpty pty-${UID} ${1+$@}
	if [[ ! -t 1 ]];then
		setopt local_traps
		trap '' INT
	fi
	zpty -r pty-${UID}
	zpty -d pty-${UID}
    }
ptyless() {
	pty $@ | less
    }
### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} Te clone has failed.%f%b"
 fi
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

## Load a few important annexes, without Turbo (this is currently required for annexes)  
{zinit light-mode for\
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
}
## -----------------------------------------------------
## Terminal Customization
## -----------------------------------------------------
if [[ $TERM == "kitty" ]]; then
      clear ff && fortune | lsd-print
else
      clear
 fi
export FZF_DEFAULT_COMMAND='fdfind --type f'
export FZF_DEFAULT_OPTS=" --layout=reverse --inline-info --height=80%"


# ----------------------------------------------------------
# End of .zshrc
# ----------------------------------------------------------

# alias vim='vim'
# alias jel1="sudo mount.cifs //192.168.0.105/jel1 /mnt/jel1 -o username=kirk,password=123456"
# alias jel2="sudo mount.cifs //192.168.0.105/jel2 /mnt/jel2 -o username=kirk,password=123456"
# alias jel3="sudo mount.cifs //192.168.0.105/jel3 /mnt/jel3 -o username=kirk,password=123456"
# alias jel="~/scripts/mount_jel.sh"
# alias newkey='sudo rm -fr /etc/pacman.d/gnupg  && pacman-key --init && pacman-key --populate archlinux'
# alias fgg="figlet -f ~/.fonts/Graffiti.flf"
# COMPLETION_WAITING_DOTS="true"
