color0 #1d2021
color1 #cc241d
color2 #98971a
color3 #d79921
color4 #458588
color5 #b16286
color6 #689d6a
color7 #a89984
color8 #928374
color9 #fb4934
color10 #b8bb26
color11 #fabd2f
color12 #83a598
color13 #d3869b
color14 #8ec07c
color15 #ebdbb2
background #1d2021
selection_foreground #1d2021
cursor #ebdbb2
cursor_text_color #1d2021
foreground #ebdbb2
selection_background #ebdbb2

#-----------------------------------------------------
# INIT
# -----------------------------------------------------

# ANSI color codes
RESET="\e[0m"
GREEN="\e[38;2;142;192;124m"
CYAN="\e[38;2;69;133;136m"
YELLOW="\e[38;2;215;153;33m"
RED="\e[38;2;204;36;29m"
BOLD="\e[1m"

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
eval $(keychain --eval --agents ssh id_ed25519)

# -----------------------------------------------------
# Pywal
# -----------------------------------------------------

source "$HOME/.cache/wal/colors-tty.sh"
# cat ~/.cache/wal/sequence

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
  aliases
  archlinux
  colored-man-pages
  emoji
  emoji-clock
  fig
  history
  man
  magic-enter
  pip
  poetry
  pylint
  python
  thefuck
  tig
  tmux
  web-search
  zoxide
)

zstyle ':omz:update' mode disabled
ENABLE_CORRECTION="true"
COMPLETION_WAITING_DOTS="%F{cyan}waiting...%f"
DISABLE_UNTRACKED_FILES_DIRTY="true"
zstyle ':completion:*' menu select

source $ZSH/oh-my-zsh.sh
source $(dirname $(gem which colorls))/tab_complete.sh
alias lc='colorls -lA --sd'
###-----------------------------------------------------
### Starship
### -----------------------------------------------------
eval "$(starship init zsh)"

# autoload -Uz compinit
# zinit compinit

# -----------------------------------------------------
# Set-up FZF key bindings (CTRL R for fuzzy history finder)
# -----------------------------------------------------
source <(fzf --zsh)

# zsh history
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

#export FZF_DEFAULT_COMMAND='fdfind --type f'
#export FZF_DEFAULT_OPTS=" --layout=reverse --inline-info --height=80%"

# BAT Theme
export BAT_THEME="gruvbox-dark"

# Bun Completion
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

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

# alias to show the date
alias da='date "+%Y-%m-%d %A %T %Z"'
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
alias lt='eza -a --tree --level=2 --icons'
alias la='eza -Alh --icons'                # show hidden files
alias lx='eza -lXBh --icons'               # sort by extension
alias lk='eza -lSrh --icons'               # sort by size
alias lc='eza -ltcrh --icons'              # sort by change time
alias lu='eza -lturh --icons'              # sort by access time
alias lr='eza -lRh --icons'                # recursive ls
alias lt='eza -ltrh --icons'               # sort by date
alias lm='eza -alh --icons |more'          # pipe through 'more'
alias lw='eza -xAh --icons'                # wide listing format
alias labc='ls -lap --icons'               # alphabetical sort
alias lf="eza -l --icons | egrep -v '^d'"  # files only
alias ldir="eza -l --icons | egrep '^d'"   # directories only
alias lla='eza -Al --icons'                # List and Hidden Files
alias las='eza -A -- icons'                # Hidden Files
alias lls='eza -l --icons'                 # List

# Productivity
alias c='clear && $SHELL'
alias ts='~/scripts/snapshot.sh'
alias cleanup='~/scripts/cleanup.sh'
alias update='~/scripts/system_cleanup_and_update.sh'
alias fig='~/scripts/figlet.sh'
alias monitor='~/scripts/monitor.sh'
alias keybinds='nvim ~/.config/hypr/conf/keybindings/default.conf'
alias zz='~/scripts/yazi.sh'
alias python='python3'
alias v='$EDITOR'
alias vim='$EDITOR'
alias vim='nvim'
alias vi='nvim'
alias svi='sudo nvim'
alias vis='nvim "+set si"'
alias shell='~/scripts/shell.sh'
alias ps='ps auxf'
alias less='less -R'
alias vi='nvim'
alias svi='sudo vi'
alias vis='nvim "+set si"'
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
alias gcheck='git checkout'
alias gall='git add -A'
alias gl='git log'
alias gll='git log --oneline'
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
alias dusage='du -sh * 2>/dev/null'
alias ping='ping -c 5'
alias fastping='ping -c 100 -i .2'

# Miscellaneous
alias ff='fastfetch'
alias tm='tmux'
alias ps='pacseek'
alias lp='lsd-print'
alias doom='~/scripts/doom.sh'

# Search command line history
alias h='history | grep'

# Search running processes
alias p='ps aux | grep'
alias topcpu="/bin/ps -eo pcpu,pid,user,args | sort -k 1 -r | head -10"

# Search files in the current folder
alias f="find . | grep "

# To see if a command is aliased, a file, or a built-in command
alias checkcommand="type -t"

# Show open ports
alias openports='netstat -nape --inet'

# aliases for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# aliases to show disk space and space used in a folder
alias duf='duf -theme ansi'
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'

# aliases for archives
alias mktar='tar -cvf'
alias mkbz2='tar -cvjf'
alias mkgz='tar -cvzf'
alias untar='tar -xvf'
alias unbz2='tar -xvjf'
alias ungz='tar -xvzf'

# Show all logs in /var/log
alias logs="sudo find /var/log -type f -exec file {} \; | grep 'text' | cut -d' ' -f1 | sed -e's/:$//g' | grep -v '[0-9]$' | xargs tail -f"

# this uses bat (called batcat on debian)
# to colorize man pages

export MANPAGER="sh -c 'col -bx | batcat -l man -p'"

# -----------------------------------------------------
# Fastfetch
# -----------------------------------------------------
if [[ $TERM == "kitty" ]]; then
    clear ff && fortune | lsd-print
else
    clear
fi

ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit
