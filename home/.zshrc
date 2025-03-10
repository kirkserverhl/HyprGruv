# ANSI color codes
RESET="\e[0m"
GREEN="\e[38;2;142;192;124m"
CYAN="\e[38;2;69;133;136m"
YELLOW="\e[38;2;215;153;33m"
RED="\e[38;2;204;36;29m"
BOLD="\e[1m"

# Logging functions
log_status() { echo -e "${CYAN}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${RESET} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${RESET} $1"; }
log_error() { echo -e "${RED}[ERROR]${RESET} $1"; }

###-----------------------------------------------------###
### INIT
###-----------------------------------------------------###
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/scripts:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export QT_QPA_PLATFORMTHEME=qt6ct
export PYWAL='~/.cache/wal/colors.sh'
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent

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
# Eza-based ls aliases 
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='eza -a --tree --level=1 --icons'

# Productivity
alias c='clear && $SHELL'
alias ts='~/scripts/snapshot.sh'
alias cleanup='~/scripts/cleanup.sh'
alias update='~/scripts/system_cleanup_and_update.sh'
alias fig='~/scripts/figlet.sh'
alias monitor='~/scripts/monitor.sh'
alias zsh='nvim ~/.zshrc'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'
alias zz='~/scripts/yazi.sh'
alias python=python3

# Color
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias ls='eza --long --color=always --icons --no-user'
alias woah='| lsd-print'

# Git
alias gs="git status"
alias ga="git add"
alias add="cd ~/.dotfiles && git add ."
alias gc="git commit -m"
alias commit="cd ~/.dotfiles && git commit -m"
alias gp="git push"
alias gpl="git pull"
alias pull="git pull"
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
alias dusage='du -sh * 2>/dev/null'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'

# Miscellaneous
alias ff='fastfetch'
alias tm='tmux -2'
alias ps='pacseek'
alias lp='lsd-print'
alias doom='~/scripts/doom.sh'

###-----------------------------------------------------
### Plugins and Features
###-----------------------------------------------------
plugins=( 
  # aliases 
  archlinux 
  bun 
  colorize 
  fig 
  git 
  history
  man 
  pip 
  poetry 
  pylint 
  python 
  thefuck 
  tig 
  tmux 
  zoxide
)

###-----------------------------------------------------
### Starship
### -----------------------------------------------------
eval "$(starship init zsh)"

# Old zinit source path - now using XDG path below
# source ~/.zinit/bin/zinit.zsh

autoload -Uz compinit
compinit

# Source Pywal Colors
source "$HOME/.cache/wal/colors-tty.sh"

### Oh-My-Zsh Configuration ###
zstyle ':omz:update' mode disabled
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="%F{cyan}waiting...%f"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':completion:*' menu select

### Load oh-my-zsh ###
source $ZSH/oh-my-zsh.sh

# FZF Integration
source <(fzf --zsh)

# ZSH History Configuration
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# BAT Theme
export BAT_THEME="gruvbox-dark"

# Bun Completion
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# -----------------------------------------------------
# ZNT and Zharma
# -----------------------------------------------------
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load zinit plugins that enhance zsh experience
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-autosuggestions

zinit light denysdovhan/spaceship-prompt

zinit light MichaelAquilina/zsh-you-should-use
YSU_HARDCORE=0

zinit light hlissner/zsh-autopair

zinit ice from"gh-r" as"program" mv"yaml2json* -> yaml2json"
zinit load wakeful/yaml2json

if uname | grep -iq linux; then
    zinit ice from"gh-r" as"program" bpick"*.deb" pick"usr/bin/interactive-rebase-tool"
    zinit load MitMaro/git-interactive-rebase-tool
fi

if uname | grep -iq darwin; then
    zinit ice from"gh-r" as"program" mv"macos-interactive-rebase-tool -> interactive-rebase-tool" bpick"macos-interactive-rebase-tool"
    zinit load MitMaro/git-interactive-rebase-tool
fi

if uname | grep -iq darwin; then
    if ! [[ $commands[jq] ]]; then
        brew install jq
    fi
    # zinit ice from"gh-r" as"program" ver"1.6"; zinit load jqlang/jq
else
    zinit ice from"gh-r" as"program" bpick"jq-linux64" mv"jq-linux64 -> jq"; zinit load jqlang/jq
fi

# Colorls-based aliases, currently superseded by eza aliases above
function _ls-aliases() {
    alias colorls_ls="colorls --almost-all --git-status --group-directories-first"
    alias l="colorls_ls -l"
    alias ldir="l --dirs"
    alias lf="l --files"
    alias cls="/bin/ls"
}

zinit ice from"gh-r" as"program"
zinit load dduan/tre

zinit ice from"gh-r" as"program" bpick"*.tar.gz" mv"bat* -> bat" pick"bat/bat"
zinit load sharkdp/bat

zinit ice from"gh-r" as"program" bpick"*.tar.gz" mv"fd* -> fd" pick"fd/fd"
zinit load sharkdp/fd
zinit light zdharma-continuum/z-a-as-monitor
zinit light zdharma-continuum/z-a-bin-gem-node
for lib in functions clipboard directories termsupport key-bindings history; do
    zinit snippet OMZ::lib/$lib.zsh
done

if [[ $commands[fasd] ]]; then
    zinit snippet OMZ::plugins/fasd/fasd.plugin.zsh
fi

GIT_AUTO_FETCH_INTERVAL=1800
HIST_STAMPS="yyyy-mm-dd"

# Already loaded above

zinit ice from"gh-r" as"program"
zinit load junegunn/fzf

zinit ice as"program" pick"$ZPFX/bin/git-*" src"etc/git-extras-completion.zsh" make"PREFIX=$ZPFX"
zinit light tj/git-extras

HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="bg=cyan,fg=white,bold"
bindkey '^[OA' history-substring-search-up
bindkey '^[OB' history-substring-search-down

zinit light Tarrasch/zsh-bd
zinit light brymck/print-alias

zinit ice gem'!colorls' atload"_ls-aliases" id-as'colorls'
zinit load zdharma-continuum/null

# Function already defined above
zinit ice from"gh-r" as"program" mv"peco* -> peco" pick"peco/peco"
zinit load peco/peco

if [ "$DOTFILES_CONF_kubectl" = "true" ]; then
    # loaded manually
    # zinit snippet OMZ::plugins/kubectl/kubectl.plugin.zsh

    zinit ice from"gh-r" as"program" bpick"*$(uname)*.tar.gz" mv "kubecolor* -> kubecolor" pick "kubecolor/kubecolor"
    zinit load hidetatz/kubecolor

    zinit ice from"gh-r" as"program" bpick"*$(uname | tr '[:upper:]' '[:lower:]')*.tar.gz" mv "kubectl-debug* -> kubectl-debug" pick "kubectl-debug/kubectl-debug"
    zinit load aylei/kubectl-debug

    zinit ice from"gh-r" as"program" bpick"*$(uname | tr '[:upper:]' '[:lower:]')*"
    zinit load sbstp/kubie
}

# LSCOLORS
export LSCOLORS="Gxfxcxdxbxegedabagacab"
export LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:ow=0;41:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:*.patch=00;34:*.o=00;32:*.so=01;35:*.ko=01;31:*.la=00;33'
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

## -----------------------------------------------------
## Terminal Customization
## -----------------------------------------------------

if [[ $TERM == "kitty" ]]; then
    clear
    ff && fortune | lsd-print
    ls
    clear
fi

# ----------------------------------------------------------
# End of .zshrc
# ----------------------------------------------------------
