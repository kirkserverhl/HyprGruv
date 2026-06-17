#
# ~/.bashrc — bash fallback mirroring ~/.zshrc where practical
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# =====================================================
# Core Environment
# =====================================================
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/bin:$HOME/scripts:$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
export TERMINAL=kitty

if command -v bat >/dev/null; then
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
fi

# GPG / SSH agent (quiet)
export GPG_TTY="$(tty)"
export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
gpgconf --launch gpg-agent >/dev/null 2>&1

# =====================================================
# Matugen Terminal Colors (OSC sequences)
# =====================================================
# Non-kitty terminals only. Kitty uses ~/.config/kitty/colors.conf
# (reloaded on wallpaper change via reload-kitty-colors.sh / SIGUSR1).
# Applying OSC here in kitty would override colors.conf and fight matugen.
if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
  [[ -f ~/.config/terminal-sequences ]] && cat ~/.config/terminal-sequences
fi

# =====================================================
# History (bash equivalents of zsh history options)
# =====================================================
HISTFILE="$HOME/.bash_history"
HISTSIZE=200000
HISTFILESIZE=200000
HISTCONTROL=ignorespace:erasedups
HISTTIMEFORMAT='%F %T '
shopt -s histappend histverify checkwinsize

# =====================================================
# Hyprgruv deployment (desktop → git → laptop)
# =====================================================
alias hgpkg='bash ~/.hyprgruv/sync-packages.sh'
alias hgadd='bash ~/.hyprgruv/sync-packages.sh add'
alias hgdeploy='bash ~/.hyprgruv/lib/scripts/repo-sync-deploy.sh --full'
alias hgupdates='bash ~/.hyprgruv/lib/scripts/repo-update-check.sh --prompt'

# =====================================================
# Aliases
# =====================================================
alias grep='grep --color=auto'

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
  export BAT_THEME="Matugen"
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
alias hyprstow='$HOME/bin/migrate-config-to-stow'
alias c='clear && $SHELL'
alias ff='fastfetch'
alias tm='tmux'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gsp='git stash && git pull'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'
alias keybinds='nvim ~/.config/hypr/conf/keybinds.lua'
alias reload='hyprctl reload'
alias hyprscripts='$EDITOR ~/.config/hypr/scripts'

# YAY
alias i="yay -S"
alias r="yay -Rns"
alias u="yay -Syu"
alias s="yay -Ss"
alias q="yay -Q"

# Matugen Palette Output
alias palette='~/.config/hypr/scripts/palette.sh'

# Errors
alias hyprerror='hyprctl configerrors'

# Unlock Faillock
alias unlock='~/.config/hypr/scripts/unlockroot.sh'
alias fail='faillock --reset'
alias cleanup='~/.hyprgruv/lib/scripts/cleanup.sh'
alias doom='~/scripts/doom.sh'
alias updates='~/.config/hypr/scripts/installupdates.sh'

# =====================================================
# Functions
# =====================================================
trim() {
  local var="$*"
  var="${var#"${var%%[![:space:]]*}"}"
  var="${var%"${var##*[![:space:]]}"}"
  printf '%s' "$var"
}

extract() {
  for f in "$@"; do
    [[ -f "$f" ]] || { echo "Not a file: $f"; continue; }
    case "$f" in
      *.tar.bz2) tar xvjf "$f" ;;
      *.tar.gz)  tar xvzf "$f" ;;
      *.bz2)     bunzip2 "$f" ;;
      *.rar)
        if command -v unrar >/dev/null; then
          unrar x "$f"
        else
          echo "unrar not installed — cannot extract: $f"
        fi
        ;;
      *.gz)      gunzip "$f" ;;
      *.tar)     tar xvf "$f" ;;
      *.tbz2)    tar xvjf "$f" ;;
      *.tgz)     tar xvzf "$f" ;;
      *.zip)     unzip "$f" ;;
      *.Z)       uncompress "$f" ;;
      *.7z)
        if command -v 7z >/dev/null; then
          7z x "$f"
        else
          echo "7z not installed — cannot extract: $f"
        fi
        ;;
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
y() {
  command -v yazi >/dev/null || { echo "yazi not installed"; return 1; }
  local tmp
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# =====================================================
# FZF
# =====================================================
if [[ -f ~/.fzf.bash ]]; then
  source ~/.fzf.bash
elif [[ -f /usr/share/fzf/completion.bash ]]; then
  source /usr/share/fzf/completion.bash
  source /usr/share/fzf/key-bindings.bash
fi

# =====================================================
# Zoxide
# =====================================================
if command -v zoxide >/dev/null; then
  eval "$(zoxide init bash)"
  alias za='zoxide add'
  alias zr='zoxide remove'
  alias zl='zoxide query -l'
  alias zi='zoxide query -i'
fi

# =====================================================
# Prompt (Starship)
# =====================================================
export STARSHIP_CONFIG="${STARSHIP_CONFIG:-$HOME/.config/starship/matugen-rainbow.toml}"
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
else
  PS1='[\u@\h \W]\$ '
fi

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
if command -v thefuck >/dev/null; then
  eval "$(thefuck --alias)"
fi

# =====================================================
# Atuin (keep near the end)
# =====================================================
if command -v atuin >/dev/null; then
  [[ -f "$HOME/.atuin/bin/env" ]] && . "$HOME/.atuin/bin/env"
  [[ -f "$HOME/.bash-preexec.sh" ]] && source "$HOME/.bash-preexec.sh"
  eval "$(atuin init bash)"
fi

# Control + Backspace
bind '"\C-H": backward-kill-word'

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
[[ -r "$HOME/.grok/completions/bash/grok.bash" ]] && source "$HOME/.grok/completions/bash/grok.bash"
# <<< grok installer <<<

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"