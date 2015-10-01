# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="xandor"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(debian gibo git git-extras git-flow github git-hubflow git-remote-branch gnu-utils history history-substring-search node npm svn zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=$PATH:$HOME/.bin:$HOME/.bin/todo.txt:$HOME/.rvm/bin

# Execute rvm scripts, need this to enable compass
[[ -e "$HOME/.rvm/scripts/rvm" ]] && source ~/.rvm/scripts/rvm
[[ -e "/usr/local/rvm/scripts/rvm" ]] && source /usr/local/rvm/scripts/rvm

# Turn on colors in autocompletion
if [[ "$OSTYPE" == *gnu* ]]
then
	eval `dircolors ~/.dir_colors`
fi

# Turn on syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
ZSH_HIGHLIGHT_STYLES[alias]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=default'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta,bold'

# Correct the TERM value if we're not inside a tmux session
[[ $COLORTERM = gnome-terminal && ! $TERM = screen-256color ]] && TERM=xterm-256color

# get Powerline if it's installed
if (( $+commands[powerline] ))
then
	powerline-daemon -q
	[[ -e "/usr/local/lib/python2.7/dist-packages/powerline/bindings/zsh/powerline.zsh" ]] && source /usr/local/lib/python2.7/dist-packages/powerline/bindings/zsh/powerline.zsh
fi

# Ignore vim backup files in autocompletion
zstyle ':completion:*:*:*:*:*files' ignored-patterns '*~'

# Allow completions for git aliases when git is wrapped by hub
compdef hub=git

# vi keybindings
bindkey -v
# map JK to ESC in command mode
bindkey -M viins 'jk' vi-cmd-mode
# VIm-style backspace
bindkey "^?" backward-delete-char

# completion
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# no autocorrect, thank you
unsetopt correct_all

# Set up aliases
alias ..='cd ..'
alias ~='cd ~'

alias todo='~/.bin/todo.txt/todo.sh -d ~/.bin/todo.txt/todo.cfg'

if [[ "$OSTYPE" == *gnu* ]]
then
	alias ls='ls -h --color --group-directories-first'

	alias grep='grep --color=auto'
fi
if [[ "$OSTYPE" == *darwin* ]]
then
	alias ls='ls -hG'
fi
alias l='ls -lB'
alias ll='ls -la'

alias -g L="|less"
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

alias tmux='tmux -2'

# Use hub instead of git if it's installed
hub --version >/dev/null 2>&1 && alias git=hub

# source alias.sh aliases
source ~/.aliases

# Show time for long commands
REPORTTIME=5
TIMEFMT="%U user %S system %P cpu %*Es total"

# Set up custom functions
precmd() {
	[[ -t 1 ]] || return
	case $TERM in
		(sun-cmd) print -Pn "\e]l%~\e\\"
			;;
		(*xterm*|rxvt|(dt|k|E)term) print -Pn "\e]2;%~\a"
			;;
	esac

	# History logs
	if [ "$(id -u)" -ne 0 ]; then
		FULL_CMD_LOG="$HOME/.logs/zsh-history-$(date -u "+%Y-%m-%d").log"
		echo "$USER@`hostname`:`pwd` [$(date -u)] `\history -1`" >> ${FULL_CMD_LOG}
	fi
}

# Better command history tracking
export HISTSIZE=100000 SAVEHIST=100000 HISTFILE=~/.zhistory
if [[ ! -d ~/.logs ]] then
	mkdir ~/.logs
fi

# Create and enter directory
mcd() {
	mkdir -p "$1" && cd "$1";
}


# Switch between running program and shell real quick
fancy-ctrl-z () {
	if [[ $#BUFFER -eq 0 ]]; then
		BUFFER="fg"
		zle accept-line
	else
		zle push-input
		zle clear-screen
	fi
}
zle -N fancy-ctrl-z
bindkey '^Z' fancy-ctrl-z

# Try to attach to a Tmux session when using SSH to log in
ssh () {
	/usr/bin/ssh -t $@ /bin/sh -c 'tmux has-session > /dev/null 2>&1 && exec tmux attach || exec tmux'
}
