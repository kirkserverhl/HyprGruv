#-----------------------------------------------------
# INIT
# -----------------------------------------------------
# Define color variables
autoload -U colors && colors
YELLOW="%{$fg[yellow]%}"
GREEN="%{$fg[green]%}"
CYAN="%{$fg[cyan]%}"
RED="%{$fg[red]%}"
RESET="%{$reset_color%}"

# Now you can use the pywal color variables in your scripts
function log_success() {
  echo "${GREEN}[SUCCESS]${RESET} $1"
}
function log_error() {
  echo "${RED}[ERROR]${RESET} $1"
}
function log_info() {
  echo "${CYAN}[INFO]${RESET} $1"
}

###-----------------------------------------------------
### INIT
###-----------------------------------------------------
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"
export PATH="$HOME/scripts:$PATH"
export ZSH="$HOME/.oh-my-zsh"
export LESSOPEN="| /usr/bin/source-highlight-esc.sh %s"
export QT_QPA_PLATFORMTHEME=qt6ct
export PYWAL='~/.cache/wal/colors.sh'
export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
gpgconf --launch gpg-agent
eval $(keychain --a eval --agents ssh id_ed25519)

# -----------------------------------------------------
# Pywal
# -----------------------------------------------------
source "$HOME/.cache/wal/colors-tty.sh"
cat ~/.cache/wal/sequences

# Source gum pywal theme
[ -f "$HOME/.cache/wal/gum.sh" ] && . "$HOME/.cache/wal/gum.sh"

alias ls='ls --color=auto'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# -----------------------------------------------------
# Themes:
# -----------------------------------------------------

source ~/.config/zshrc/ultima-shell/ultima.zsh-theme

# -----------------------------------------------------
# oh-myzsh plugins
# -----------------------------------------------------
plugins=(
  # emoji
  # emoji-clock
  pip
  pylint
  python
  # thefuck
  tig
  # zoxide
)

zstyle ':omz:update' mode disabled
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="%F{cyan}waiting...%f"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':completion:*' menu select

source $ZSH/oh-my-zsh.sh
source $(dirname $(gem which colorls))/tab_complete.sh
alias ls='colorls -lA --sd'

###-----------------------------------------------------
### Starship
### -----------------------------------------------------
eval "$(starship init zsh)"
alias star='~/.hyprgruv/home/scripts/starship_theme.sh'

# -----------------------------------------------------
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
# -----------------------------------------------------
source <(fzf --zsh)

# zsh history
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

# Automatically do an ls after each cd, z, or zoxide
cd ()
{
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	else
		builtin cd ~ && ls
	fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# Trim leading and trailing spaces (for scripts)
trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}
# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# cd into the old directory
alias bd='cd "$OLDPWD"'

# Remove a directory and all files
alias rmd='/bin/rm  --recursive --force --verbose '

# Edit this .bashrc file
alias zsh='$EDITOR ~/.zshrc'

# Edit Hyprland
alias hypr='$EDITOR ~/.config/hypr/'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../../..'

# Eza-based ls aliases
alias ls='eza -a --icons'
alias ll='eza -al --icons'
alias lt='lsd -a --tree --level=2 --icons'
alias la='eza -Alh --icons'                # show hidden files
alias lx='eza -lXBh --icons'
alias labc='ls -lap --icons'              # alphabetical sort
alias lf="eza -l --icons | egrep -v '^d'"  # files only
alias ldir="eza -l --icons | egrep '^d'"   # directories only
alias lla='eza -Al --icons'                # List and Hidden Files
alias las='eza -A -- icons'                # Hidden Files
alias lls='eza -l --icons'
alias cat='bat --style=header,grid'
alias fzfp='fzf --preview "bat --color=always --style=numbers --line-range=:500 {}"'

# Productivity
alias c='clear && $SHELL'
alias ts='~/scripts/snapshot.sh'
alias cleanup='~/scripts/cleanup.sh'
alias update='~/scripts/system_cleanup_and_update.sh'
alias fig='~/scripts/figlet.sh'
alias monitor='~/.hyprgruv/assets/scripts/monitor.sh'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'
alias zz='~/scripts/yazi.sh'
alias python='python3'
alias shell='~/scripts/shell.sh'
alias less='less -R'
alias znt='~/.local/share/zinit.zsh'

# Color
alias diff='diff --color=auto'
alias grep='grep --color=auto'
alias ip='ip --color=auto'
alias lsd='lsd --long --color=always --icon=always'
alias woah='| lsd-print'

# Git
alias gs='git status'
alias ga='git add'
alias add='cd ~/.dotfiles && git add .'
alias gc='git commit -m'
alias commit='cd ~/.dotfiles && git commit -m'
alias gp='git push'
alias gpl='git pull'
alias pull='git pull'
alias gst='git stash'
alias stash='git stash'
alias gsp='git stash; git pull'
alias push='git push origin main --force'

# GitHub Titus Additions
gcom() {
	git add .
	git commit -m "$1"
}
lazyg() {
	git add .
	git commit -m "$1"
	git push
}

# System Commands
alias shutdown='systemctl poweroff'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'

# Miscellaneous
alias ff='fastfetch'
alias tm='tmux'
alias ps='pacseek'

# Search command line history
alias h='history | grep'

# Search files in the current folder
alias f='find . | grep'

# aliases to show disk space and space used in a folder
alias disko='diskonaut'
alias duf='duf -theme ansi'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'
alias less='bat'
alias cat='bat -pp'

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

#####################
# PROMPT            #
#####################
zinit ice from"gh-r" as"command"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-rust \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-bin-gem-node

### End of Zinit's installer chunk

##########################
# OMZ Libs and Plugins   #
##########################

# IMPORTANT:
# Ohmyzsh plugins and libs are loaded first as some these sets some defaults which are required later on.
# Otherwise something will look messed up
# ie. some settings help zsh-autosuggestions to clear after tab completion

setopt promptsubst

# Loading tmux first, to prevent jumps when tmux is loaded after .zshrc
# It will only be loaded on first start
zinit wait lucid for \
    OMZL::clipboard.zsh \
    OMZL::compfix.zsh \
    OMZL::completion.zsh \
    OMZL::correction.zsh \
    atload"
        alias ..='cd ..'
        alias ...='cd ../..'
        alias ....='cd ../../..'
        alias .....='cd ../../../..'
    " \
    OMZL::directories.zsh \
    OMZL::git.zsh \
    OMZL::grep.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::spectrum.zsh \
    OMZL::termsupport.zsh \
    atload"
        alias gcd='gco dev'
    " \
    OMZP::git \
    atload"
        alias dcupb='docker-compose up --build'
    " \
     djui/alias-tips \
     hlissner/zsh-autopair \
     chriskempson/base16-shell \

#####################
# PLUGINS           #
#####################
# @source: https://github.com/crivotz/dot_files/blob/master/linux/zplugin/zshrc

# IMPORTANT:
# These plugins should be loaded after ohmyzsh plugins

zinit wait lucid for \
        zsh-users/zsh-history-substring-search \
    light-mode atinit"ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20" atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    light-mode atinit"typeset -gA FAST_HIGHLIGHT; FAST_HIGHLIGHT[git-cmsg-len]=100; zpcompinit; zpcdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    light-mode blockf atpull'zinit creinstall -q .' \
    atinit"
        zstyle ':completion:*' completer _expand _complete _ignored _approximate
        zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
        zstyle ':completion:*' menu select=2
        zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'
        zstyle ':completion:*:descriptions' format '-- %d --'
        zstyle ':completion:*:processes' command 'ps -au$USER'
        zstyle ':completion:complete:*:options' sort false
        zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm,cmd -w -w'
    " \
        zsh-users/zsh-completions \
    bindmap"^R -> ^H" atinit"
        zstyle :history-search-multi-word page-size 10
        zstyle :history-search-multi-word highlight-color fg=red,bold
        zstyle :plugin:history-search-multi-word reset-prompt-protect 1
    " \
        zdharma-continuum/history-search-multi-word \
    reset \
    atclone"dircolors -b LS_COLORS > clrs.zsh" \
    atpull'%atclone' pick"c.zsh" nocompile'!' \
    atload'zstyle ":completion:*" list-colors “${(s.:.)LS_COLORS}”' \
        trapd00r/LS_COLORS

# Load pure theme
zinit ice pick"async.zsh" src"pure.zsh" # with zsh-async library that's bundled with it.
zinit light sindresorhus/pure

#####################
# HISTORY           #
#####################
[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
HISTSIZE=290000
SAVEHIST=$HISTSIZE

#####################
# SETOPT            #
#####################
setopt extended_history       # record timestamp of command in HISTFILE
setopt hist_expire_dups_first # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt hist_ignore_all_dups   # ignore duplicated commands history list
setopt hist_ignore_space      # ignore commands that start with space
setopt hist_verify            # show command with history expansion to user before running it
setopt inc_append_history     # add commands to HISTFILE in order of execution
setopt share_history          # share command history data
setopt always_to_end          # cursor moved to the end in full completion
setopt hash_list_all          # hash everything before completion
setopt completealiases        # complete alisases
setopt always_to_end          # when completing from the middle of a word, move the cursor to the end of the word
setopt complete_in_word       # allow completion from within a word/phrase
setopt nocorrect              # spelling correction for commands
setopt list_ambiguous         # complete as much of a completion until it gets ambiguous.
setopt nolisttypes
setopt listpacked
setopt automenu
setopt autocd

#####################
# ENV VARIABLE      #
#####################
ZSH_AUTOSUGGEST_MANUAL_REBIND=1  # make prompt faster
DISABLE_MAGIC_FUNCTIONS=true     # make pasting into terminal faster
export EDITOR=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

#####################
# ALIASES           #
#####################

# VSCode
alias code="code-insiders";

# Tmux
alias %t='_tmux_(){tmux new -s "$1"}; _tmux_'
alias sshrc="vim $HOME/.ssh/config"
alias python=/opt/homebrew/bin/python3

#npm
alias npmnuke="echo Deleting ^/node_modules/ && rm -rf ./**/node_modules"

zinit is-snippet for \
    if"[[ -f $HOME/.localrc  ]]" $HOME/.localrc


#######################################################
# SPECIAL FUNCTIONS
#######################################################
# Extracts any archive(s) (if unp isn't installed)
extract() {
	for archive in "$@"; do
		if [ -f "$archive" ]; then
			case $archive in
			*.tar.bz2) tar xvjf $archive ;;
			*.tar.gz) tar xvzf $archive ;;
			*.bz2) bunzip2 $archive ;;
			*.rar) rar x $archive ;;
			*.gz) gunzip $archive ;;
			*.tar) tar xvf $archive ;;
			.*.tbz2) tar xvjf $archive ;;
			*.tgz) tar xvzf $archive ;;
			*.zip) unzip $archive ;;
			*.Z) uncompress $archive ;;
			*.7z) 7z x $archive ;;
			*) echo "don't know how to extract '$archive'..." ;;
			esac
		else
			echo "'$archive' is not a valid file!"
		fi
	done
}

# Searches for text in all files in the current folder
ftext() {
	# -i case-insensitive
	# -I ignore binary files
	# -H causes filename to be printed
	# -r recursive search
	# -n causes line number to be printed
	# optional: -F treat search term as a literal, not a regular expression
	# optional: -l only print filenames and not the matching lines ex. grep -irl "$1" *
	grep -iIHrn --color=always "$1" . | less -r
}

# Copy file with a progress bar
cpp() {
    set -e
    strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            fprintf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                fprintf "="
            fprintf ">"
            for (i=percent;i<100;i++)
                fprintf " "
            fprintf "]\r"
        }
    }
    END { fprint "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# Copy and go to the directory
cpg() {
	if [ -d "$2" ]; then
		cp "$1" "$2" && cd "$2"
	else
		cp "$1" "$2"
	fi
}

# Move and go to the directory
mvg() {
	if [ -d "$2" ]; then
		mv "$1" "$2" && cd "$2"
	else
		mv "$1" "$2"
	fi
}

# Create and go to the directory
mkdirg() {
	mkdir -p "$1"
	cd "$1"
}

# Goes up a specified number of directories  (i.e. up 4)
up() {
	local d=""
	limit=$1
	for ((i = 1; i <= limit; i++)); do
		d=$d/..
	done

d=$(echo $d | sed 's/^\///')
	if [ -z "$d" ]; then
		d=..
	fi
	cd $d
}

# Automatically do an ls after each cd, z, or zoxide
cd ()
{
	if [ -n "$1" ]; then
		builtin cd "$@" && ls
	else
		builtin cd ~ && ls
	fi
}

# Returns the last 2 fields of the working directory
pwdtail() {
	pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}

# IP address lookup
alias whatismyip="whatsmyip"
function whatsmyip () {
    # Internal IP Lookup.
    if command -v ip &> /dev/null; then
        echo -n "Internal IP: "
        ip addr show wlan0 | grep "inet " | awk '{print $2}' | cut -d/ -f1
    else
        echo -n "Internal IP: "
        ifconfig wlan0 | grep "inet " | awk '{print $2}'
    fi

    # External IP Lookup
    echo -n "External IP: "
    curl -s ifconfig.me
}

# Trim leading and trailing spaces (for scripts)
trim() {
	local var=$*
	var="${var#"${var%%[![:space:]]*}"}" # remove leading whitespace characters
	var="${var%"${var##*[![:space:]]}"}" # remove trailing whitespace characters
	echo -n "$var"
}

#####################
# Exports           #
#####################
# https://blog.josephscott.org/2015/05/18/lscolors/
export LSCOLORS=GxFxCxDxbxegedabagaced

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if [[ $TERM == "kitty" ]]; then
    clear ff && fortune | lsd-print
else
    clear
fi
