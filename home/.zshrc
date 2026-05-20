# =====================================================
# Core Environment
# =====================================================
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/.config/hyprgruv/scripts:$PATH"
export PATH=Z"HOME/scripts:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
export TERMINAL=kitty

# Test Path
export PATH="/home/$USER/.local/bin:$PATH"


if command -v bat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# GPG / SSH agent (quiet)
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent >/dev/null 2>&1

# =====================================================
# Pywal16
# =====================================================
if [[ -f "$HOME/.cache/wal/colors-tty.sh" ]]; then
  source "$HOME/.cache/wal/colors-tty.sh"
fi

# Only print sequences when in an interactive TTY
if [[ -t 1 && -f "$HOME/.cache/wal/sequences" ]]; then
  cat "$HOME/.cache/wal/sequences"
fi

# Gum theme (optional)
[[ -f "$HOME/.cache/wal/gum.sh" ]] && source "$HOME/.cache/wal/gum.sh"

# =====================================================
# History
# =====================================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=$HISTSIZE

setopt extended_history hist_expire_dups_first hist_ignore_all_dups \
       hist_ignore_space hist_verify inc_append_history share_history \
       complete_in_word list_ambiguous nolisttypes listpacked automenu autocd

unsetopt correct

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Test
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"


# =====================================================
# Aliases
# =====================================================
if command -v eza >/dev/null; then
  alias ls='eza -a --icons'
  alias ll='eza -al --icons'
  alias la='eza -Alh --icons'
  alias lls='eza -l --icons'
  alias ldir="eza -l --icons | egrep '^d'"
else
  alias ls='ls --color=auto -A'
  alias ll='ls --color=auto -al'
fi

if command -v bat >/dev/null; then
  export BAT_THEME="gruvbox-dark"
  alias cat='bat -pp'
  alias less='bat'
else
  alias less='less -R'
fi

# Directory navigation
alias ..='cd .. && ls'
alias ...='cd ../.. && ls'
alias ....='cd ../../.. && ls'
alias .....='cd ../../../../.. && ls'
alias bd='cd "$OLDPWD"'

# General
alias rmd='/bin/rm -rfv'
alias hypr='$EDITOR ~/.config/hypr/'
alias c='clear && $SHELL'
alias ff='fastfetch'
alias tm='tmux'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gsp='git stash && git pull'
#alias gup='cd ~/.hyprgruv && git add . && git commit -m "update" && git push'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'
alias reload='hyprctl reload'
alias scripts= 'cd ~/.config/hypr/scripts'

# Zoxide
alias za='zoxide add'
alias zr='zoxide remove'
alias zl='zoxide query -l'
alias zi='zoxide query -i'


# YAY
alias i="yay -S"
alias r="yay -Rns"
alias u="yay -Syu"
alias s="yay -Ss"
alias q="yay -Q"

# Test
plugins=(git zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

alias reload="hyprctl reload"

# =====================================================
# Functions
# =====================================================
trim() {
  local var=$*; var="${var#"${var%%[![:space:]]*}"}"; var="${var%"${var##*[![:space:]]}"}"; print -r -- "$var"
}

extract() {
  for f in "$@"; do
    [[ -f "$f" ]] || { echo "Not a file: $f"; continue; }
    case "$f" in
      *.tar.bz2) tar xvjf "$f" ;;
      *.tar.gz)  tar xvzf "$f" ;;
      *.bz2)     bunzip2 "$f" ;;
      *.rar)     unrar x "$f" ;;
      *.gz)      gunzip "$f" ;;
      *.tar)     tar xvf "$f" ;;
      *.tbz2)    tar xvjf "$f" ;;
      *.tgz)     tar xvzf "$f" ;;
      *.zip)     unzip "$f" ;;
      *.Z)       uncompress "$f" ;;
      *.7z)      7z x "$f" ;;
      *)         echo "Don't know how to extract: $f" ;;
    esac
  done
}

cd() {
  if builtin cd "$@"; then
    ls
  fi
}

ftext() { grep -iIHrn --color=always "${1:?pattern}" . | less -r; }

whatsmyip() {
  echo -n "Internal IP: "
  ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
  echo -n "External IP: "
  curl -fsS ifconfig.me || echo "unavailable"
}
alias whatismyip='whatsmyip'

# Yazi wrapper
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# =====================================================
# FZF
# =====================================================
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# =====================================================
# Zinit + Plugins + Pywal16 Theming
# =====================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d $ZINIT_HOME ]]; then
  print -P "%F{33}Installing %F{220}Zinit%f…"
  command mkdir -p "$(dirname $ZINIT_HOME)"
  command git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" >/dev/null 2>&1
fi

source "${ZINIT_HOME}/zinit.zsh"

# Zinit + pywal16 theming
if [[ -f "$HOME/.cache/wal/colors-tty.sh" ]]; then
  source "$HOME/.cache/wal/colors-tty.sh"

  zstyle ':zinit:*'         default-color "${color4:-4}"
  zstyle ':zinit:plugin'    loaded-color  "${color2:-2}"
  zstyle ':zinit:plugin'    error-color   "${color1:-1}"
  zstyle ':zinit:plugin'    warning-color "${color3:-3}"

  zstyle ':zinit:status'    plugin-color  "${color5:-5}"
  zstyle ':zinit:status'    ice-color     "${color6:-6}"
  zstyle ':zinit:status'    time-color    "${color7:-7}"

  zstyle ':zinit:annex'     quiet         'yes'
fi

# Plugins
zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

# Fast syntax highlighting (loaded first)
zinit light zdharma-continuum/fast-syntax-highlighting

# Pywal16 colors — applied AFTER plugin loads
if [[ -f "$HOME/.cache/wal/colors-tty.sh" ]]; then
  source "$HOME/.cache/wal/colors-tty.sh"

 # ZSH_HIGHLIGHT_STYLES[default]=none
 # ZSH_HIGHLIGHT_STYLES[unknown-token]="${color1:-1}"
 # ZSH_HIGHLIGHT_STYLES[reserved-word]="${color3:-3}"
 # ZSH_HIGHLIGHT_STYLES[command]="${color2:-2}"
 # ZSH_HIGHLIGHT_STYLES[alias]="${color2:-2},bold"
 # ZSH_HIGHLIGHT_STYLES[builtin]="${color2:-2},bold"
 # ZSH_HIGHLIGHT_STYLES[function]="${color4:-4}"
 # ZSH_HIGHLIGHT_STYLES[path]="${color6:-6}"
 # ZSH_HIGHLIGHT_STYLES[single-quoted-argument]="${color5:-5}"
 # ZSH_HIGHLIGHT_STYLES[double-quoted-argument]="${color5:-5}"
fi

# Beautiful fuzzy tab completion
zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Enhanced history search
zinit ice wait lucid
zinit light zdharma-continuum/history-search-multi-word

# Completion setup
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
autoload -Uz compinit && compinit -C

# Autosuggestions color
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=${color8:-8}"

# =====================================================
# Zoxide
# =====================================================
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# =====================================================
# Prompt (Starship)
# =====================================================
command -v starship >/dev/null && eval "$(starship init zsh)"

# =====================================================
# Fastfetch intro
# =====================================================
if [[ $TERM == "kitty" && -t 1 ]]; then
  clear
  command -v fastfetch >/dev/null && fastfetch
fi

# =====================================================
# The Fuck
# =====================================================
eval "$(thefuck --alias)"

# =====================================================
# Atuin (keep near the end)
# =====================================================
eval "$(atuin init zsh)"
. "$HOME/.atuin/bin/env"

# Control + Backspace
bindkey '^H' backward-kill-word

export PATH="$HOME/bin:$PATH"

export CLUTTER_BACKEND=wayland
