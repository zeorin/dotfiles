#  Start shell in tmux
if command -v tmux >/dev/null && [[ -z "$TMUX" ]]; then

	# Check for unattached sessions
	TMUX_UNATTACHED_SESSIONS=`tmux list-sessions | grep -v '(\(attached\))$'`

	# if we found no unattached sessions
	if [[ -z "$TMUX_UNATTACHED_SESSIONS" ]]; then

		exec tmux

	else

		# ask which session we’d like to attach to
		TMUX_SESSION=false
		ERROR_MSG=""
		SHOW_ATTACHED_SESSIONS=false
		while [[ "$TMUX_SESSION" == false ]]; do
			TMUX_UNATTACHED_SESSIONS=`tmux list-sessions | grep -v '(\(attached\))$'`
			TMUX_ALL_SESSIONS=`tmux list-sessions`
			clear
			if [[ "$SHOW_ATTACHED_SESSIONS" == false ]]; then
				echo "Would you like to attach to any of the following"
				echo "unattached tmux sessions?"
				echo ""
				echo "$TMUX_UNATTACHED_SESSIONS"
			else
				echo "Would you like to attach to any of the following"
				echo "tmux sessions?"
				echo ""
				echo "$TMUX_ALL_SESSIONS"
			fi
			echo ""
			echo "Type the name/number of the session to attach to it."
			if [[ "$SHOW_ATTACHED_SESSIONS" == false ]]; then
				echo "Type \"all\" to see all sessions."
			fi
			echo "Or type \"e\" for a new tmux session."
			echo ""
			if [[ ! -z "$ERROR_MSG" ]]; then
				echo "$ERROR_MSG"
				echo ""
			fi

			read INPUT

			case "$INPUT" in
				"E" | "e" )
					clear
					echo "What would you like to name this session?"
					echo ""
					read TMUX_SESSION_NAME
					if [[ ! -z "$TMUX_SESSION_NAME" ]]; then
						exec tmux new-session -s "$TMUX_SESSION_NAME"
					else
						exec tmux
					fi
					TMUX_SESSION=true
				;;

				"All" | "ALL" | "all" )
					SHOW_ATTACHED_SESSIONS=true
					TMUX_SESSION=false
				;;

				* )
					tmux has-session -t "$INPUT" 2&>1 >/dev/null
					if [[ "$?" == 0 ]]; then
						exec tmux attach-session -t "$INPUT"
						TMUX_SESSION=true
					else
						ERROR_MSG="Session '$INPUT' does not exist!"
						TMUX_SESSION=false
					fi
				;;
			esac
		done
	fi
fi

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
plugins=(debian gibo git git-extras git-flow github git-hubflow git-flow-completion git-remote-branch gnu-utils history node npm svn zsh-syntax-highlighting history-substring-search)

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

# Use history-substring-search in vi mode also
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# Source promptline
source ~/.shell_prompt.sh

# Set Neovim or Vim or Vi to default CLI editor if one is installed
if (( $+commands[nvim] ))
then
	export EDITOR=nvim
	export VISUAL=nvim
elif (( $+commands[vim] ))
then
	export EDITOR=vim
	export VISUAL=vim
elif (( $+commands[vi] ))
then
	export EDITOR=vi
	export VISUAL=vi
fi

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
setopt auto_list
setopt no_list_beep
bindkey '^[[Z' reverse-menu-complete # SHIFT-TAB to go back

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

# ag is the silver searcher, not apt-get (oh-my-zsh debian plugin)
unalias ag

# Use hub instead of git if it's installed
hub --version >/dev/null 2>&1 && alias git=hub

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

# Load NVM if it exists
export NVM_DIR="/home/xandor/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
