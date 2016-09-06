#                     _       _                 _
#  _______  ___  _ __(_)_ __ ( )___     _______| |__  _ __ ___
# |_  / _ \/ _ \| '__| | '_ \|// __|   |_  / __| '_ \| '__/ __|
#  / /  __/ (_) | |  | | | | | \__ \  _ / /\__ \ | | | | | (__
# /___\___|\___/|_|  |_|_| |_| |___/ (_)___|___/_| |_|_|  \___|
#

# This is the personal .zshrc of Xandor Schiefer.

# Goals are:
# * ease of use: great autocompletions, vi-style keybindings, and many
#   features one would expect from a modern terminal experience.
# * tmux integration: because tmux is awesome;
# * performance: adding lots of plugins and functionality can make Zsh slow—
#   keep it snappy;
# * Linux, Mac, and Windows compatibility; one .zshrc to rule them all;
# * support for local modification with .zshrc.before and .zshrc.after;
# * making it look attractive—powerline is pretty.

# This file is licensed under the MIT License. The various plugins are
# licensed under their own licenses. Please see their documentation for more
# information.

# The MIT License (MIT) {{{

# Copyright ⓒ 2016 Xandor Schiefer

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
# IN THE SOFTWARE.

# }}}

#  Start shell in tmux, choose a session if there’re unattached sessions {{{
	if command -v tmux >/dev/null && [[ -z "$TMUX" ]]; then

		# Check for unattached sessions
		TMUX_UNATTACHED_SESSIONS=`tmux list-sessions -F '#S #{session_attached}' 2>/dev/null | grep ' 0$' | sed -e 's/ 0$//'`

		# if we found no unattached sessions
		if [[ -z "$TMUX_UNATTACHED_SESSIONS" ]]; then

			exec tmux

		else

			# ask which session we’d like to attach to
			TMUX_SESSION=false
			SHOW_ATTACHED_SESSIONS=false
			while [[ "$TMUX_SESSION" == false ]]; do

				# Build up the menu options
				TMUX_MENU_OPTIONS=("New session" "")
				if [[ "$SHOW_ATTACHED_SESSIONS" == false ]]; then
					TMUX_MENU_PROMPT="Which unattached tmux session do you want to attach to?"
					# This is some heinous code, basically it makes unattached
					# session names into array items.
					TMUX_MENU_OPTIONS+=("${(f)$(tmux list-sessions -F '#S #{session_attached}' 2>/dev/null | grep ' 0$' | sed -e 's/ 0$//')}")
					TMUX_MENU_OPTIONS+=("" "Show all sessions")
				else
					TMUX_MENU_PROMPT="Which tmux session do you want to attach to?"
					# Same heinousness as earlier, except for all sessions
					TMUX_MENU_OPTIONS+=("${(f)$(tmux list-sessions -F '#S' 2>/dev/null)}")
				fi

				# Because whiptail expects arguments in a [tag item]... format
				TMUX_MENU_TAG_ITEMS=()
				for key in "${TMUX_MENU_OPTIONS[@]}"; do
					TMUX_MENU_TAG_ITEMS+=("$key" "")
				done

				INPUT=$(whiptail --title "Choose tmux session" --nocancel --menu "$TMUX_MENU_PROMPT" 0 0 0 -- "${TMUX_MENU_TAG_ITEMS[@]}" 3>&1 1>&2 2>&3)

				case "$INPUT" in
					"New session" )
						echo "What would you like to name this session?"
						TMUX_SESSION_NAME=$(whiptail --title "Choose tmux session" --nocancel --inputbox "What would you like to name this session?" 0 0 3>&1 1>&2 2>&3)
						if [[ ! -z "$TMUX_SESSION_NAME" ]]; then
							exec tmux new-session -s "$TMUX_SESSION_NAME"
						else
							exec tmux
						fi
						TMUX_SESSION=true
					;;

					"Show all sessions" )
						SHOW_ATTACHED_SESSIONS=true
					;;

					"" )
						# If the user choose a blank spacer line (dumbass)
						# just redraw the menu
						continue 2
					;;

					* )
						tmux has-session -t "$INPUT" 2&>1 >/dev/null
						if [[ "$?" == 0 ]]; then
							exec tmux attach-session -t "$INPUT"
							TMUX_SESSION=true
						fi
					;;
				esac
			done
		fi
	fi
# }}}

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

# Change cursor shape depending on mode
function zle-keymap-select zle-line-init {
	case $KEYMAP in
		viins|main) print -n -- "\E[5 q";;	# DECSCUSR Blink Bar
		vicmd)      print -n -- "\E[2 q";;	# DECSCUSR Steady Block
	esac
	zle reset-prompt
	zle -R
}
function zle-line-finish {
	print -n -- "\E[2 q"	# DECSCUSR Steady Block
}
zle -N zle-line-init
zle -N zle-line-finish
zle -N zle-keymap-select

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


if (( $+commands[direnv] ))
then
	eval "$(direnv hook zsh)"
fi

# vim: set foldmethod=marker foldlevel=0:
