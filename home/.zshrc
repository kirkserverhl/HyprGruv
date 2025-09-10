# ─────────────────────────────────────────────────────
# Core env
# ─────────────────────────────────────────────────────
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/scripts:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# GPG / SSH agent (quiet)
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent >/dev/null 2>&1

# Keychain (quiet if available)
if command -v keychain >/dev/null; then
  eval "$(keychain --quiet --eval --agents ssh id_ed25519 2>/dev/null)"
fi

# ─────────────────────────────────────────────────────
# Pywal (quiet)
# ─────────────────────────────────────────────────────
if [[ -f "$HOME/.cache/wal/colors-tty.sh" ]]; then
  source "$HOME/.cache/wal/colors-tty.sh"
fi
# Only print sequences when in an interactive TTY (optional)
if [[ -t 1 && -f "$HOME/.cache/wal/sequences" ]]; then
  # comment the next line if you don’t want the terminal recolor “flash”
  cat "$HOME/.cache/wal/sequences"
fi
# Gum theme (optional)
[[ -f "$HOME/.cache/wal/gum.sh" ]] && source "$HOME/.cache/wal/gum.sh"

# ─────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────
HISTFILE="$HOME/.zsh_history"
HISTSIZE=200000
SAVEHIST=$HISTSIZE

setopt extended_history hist_expire_dups_first hist_ignore_all_dups \
       hist_ignore_space hist_verify inc_append_history share_history \
       complete_in_word list_ambiguous nolisttypes listpacked automenu autocd
unsetopt correct  # no autocorrect on commands

# ─────────────────────────────────────────────────────
# Aliases: choose ONE ls/cat/less stack (Eza + Bat)
# ─────────────────────────────────────────────────────
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

alias ..='cd ..'; alias ...='cd ../..'; alias ....='cd ../../..'; alias .....='cd ../../../../..'
alias bd='cd "$OLDPWD"'
alias rmd='/bin/rm -rfv'
alias hypr='$EDITOR ~/.config/hypr/'
alias c='clear && $SHELL'
alias ff='fastfetch'
alias tm='tmux'
alias gs='git status'; alias ga='git add'; alias gc='git commit -m'
alias gp='git push'; alias gpl='git pull'
alias gsp='git stash && git pull'
alias ping='ping -c 5'; alias fastping='ping -c 100 -i .2'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'

# ─────────────────────────────────────────────────────
# Functions
# ─────────────────────────────────────────────────────
# Trim spaces
trim() {
  local var=$*; var="${var#"${var%%[![:space:]]*}"}"; var="${var%"${var##*[![:space:]]}"}"; print -r -- "$var"
}

# Extract archives
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

# cd that lists after entering (quiet, no duplication)
cd() {
  if builtin cd "$@"; then
    ls
  fi
}

# Quick grep in files
ftext() { grep -iIHrn --color=always "${1:?pattern}" . | less -r; }

# IP lookup (more robust)
whatsmyip() {
  echo -n "Internal IP: "
  ip -o -4 addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
  echo -n "External IP: "
  curl -fsS ifconfig.me || echo "unavailable"
}
alias whatismyip='whatsmyip'

# ─────────────────────────────────────────────────────
# FZF (quiet)
# ─────────────────────────────────────────────────────
# Prefer installed key-bindings over spawning `fzf --zsh`
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# ─────────────────────────────────────────────────────
# Zinit (plugin manager) – keep it, drop Oh-My-Zsh
# ─────────────────────────────────────────────────────
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
  command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
  command git clone --depth=1 https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" >/dev/null 2>&1
fi
source "$HOME/.zinit/bin/zinit.zsh"

# Minimal, fast essentials
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# Completion styles (quiet)
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
autoload -Uz compinit && compinit -C

# ─────────────────────────────────────────────────────
# Prompt (Starship only)
# ─────────────────────────────────────────────────────
command -v starship >/dev/null && eval "$(starship init zsh)"

# ─────────────────────────────────────────────────────
# Optional “Fastfetch intro” (quieted & guarded)
# ─────────────────────────────────────────────────────
if [[ $TERM == "kitty" && -t 1 ]]; then
  clear
  command -v fastfetch >/dev/null && fastfetch
  # Uncomment if you still want a quote:
  # command -v fortune >/dev/null && fortune | lsd-print
fi
