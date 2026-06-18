# =====================================================
# Core Environment
# =====================================================
export PATH="$HOME/bin:$HOME/scripts:$HOME/.local/bin:$PATH"
export QT_QPA_PLATFORMTHEME=qt6ct
# shellcheck source=/dev/null
[[ -f "$HOME/.config/settings/load-defaults.sh" ]] && source "$HOME/.config/settings/load-defaults.sh"
: "${EDITOR:=nvim}"
: "${SUDO_EDITOR:=$EDITOR}"
: "${TERMINAL:=kitty}"
: "${BROWSER:=firefox}"

# Grok Build + matugen truecolor in kitty (see ~/.grok/docs/user-guide/21-terminal-support.md)
: "${COLORTERM:=truecolor}"
export COLORTERM

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
# (reloaded on wallpaper change via matugen-posthook-terminal.sh / SIGUSR1).
# Applying OSC here in kitty would override colors.conf and fight matugen.
if [[ -z "${KITTY_WINDOW_ID:-}" ]]; then
    [[ -f ~/.config/terminal-sequences ]] && cat ~/.config/terminal-sequences
fi

# Live reload when matugen finishes (matugen-posthook-terminal.sh bumps reload-stamp)
_matugen_live_reload() {
    local stamp="$HOME/.cache/matugen/reload-stamp"
    local applied="$HOME/.cache/matugen/.reload-applied"
    [[ -f "$stamp" ]] || return
    [[ ! -f "$applied" || "$stamp" -nt "$applied" ]] || return

    if [[ -z "${KITTY_WINDOW_ID:-}" && -f "$HOME/.config/terminal-sequences" ]]; then
        cat "$HOME/.config/terminal-sequences"
    fi
    touch -r "$stamp" "$applied" 2>/dev/null || cp -f "$stamp" "$applied" 2>/dev/null || true
}
precmd_functions+=(_matugen_live_reload)

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

# Path to your Oh My Zsh installation (installed by shell.sh wizard, not stowed).
export ZSH="$HOME/.oh-my-zsh"

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
alias hyprscripts='$EDITOR ~/.config/hyprgruv/scripts'

# YAY
alias i="yay -S"
alias r="yay -Rns"
alias u="yay -Syu"
alias s="yay -Ss"
alias q="yay -Q"

# Starship owns the prompt — disable the default Oh My Zsh theme or it
# will fight matugen color updates from wallpaper changes.
ZSH_THEME=""

plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"

  # --- zsh-autosuggestions settings ---
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  ZSH_AUTOSUGGEST_STRATEGY=(history completion)
fi

# Matugen Palette Output
alias palette='~/.config/hyprgruv/scripts/palette.sh'

# Errors
alias hyprerror='hyprctl configerrors'

# Unlock Faillock
alias unlock='~/.config/hyprgruv/scripts/unlockroot.sh'
alias fail='faillock --reset'
alias cleanup='~/.hyprgruv/lib/scripts/cleanup.sh'
alias doom='~/.config/hyprgruv/scripts/unused/home-scripts/doom.sh'
alias updates='~/.config/hyprgruv/scripts/installupdates.sh'

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
function y() {
  command -v yazi >/dev/null || { echo "yazi not installed"; return 1; }
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
if [[ -f ~/.fzf.zsh ]]; then
  source ~/.fzf.zsh
elif [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
  source /usr/share/fzf/key-bindings.zsh
fi

# =====================================================
# Zoxide
# =====================================================
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
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
  eval "$(starship init zsh)"
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
  eval "$(atuin init zsh)"
fi

# Control + Backspace
bindkey '^H' backward-kill-word

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"