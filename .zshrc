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

# Tmux session chooser {{{
	if which tmux >/dev/null 2>&1 && [[ -z "$TMUX" ]]; then

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

# Load antigen {{{
	_ANTIGEN_COMP_ENABLED=false source ~/.dotfiles/antigen/antigen.zsh
# }}}

# Appearance {{{

	# Set LS_COLORS {{{
		if [[ "$OSTYPE" == *gnu* ]]; then
			eval `dircolors ~/.dir_colors`
		fi
	# }}}

	# Cursor shape {{{
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
	# }}}

	# Syntax highlighting {{{
		antigen bundle zsh-users/zsh-syntax-highlighting
		ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
		typeset -A ZSH_HIGHLIGHT_STYLES
		ZSH_HIGHLIGHT_STYLES[alias]='fg=default,bold'
		ZSH_HIGHLIGHT_STYLES[builtin]='fg=default,bold'
		ZSH_HIGHLIGHT_STYLES[command]='fg=default,bold'
		ZSH_HIGHLIGHT_STYLES[function]='fg=default,bold'
		ZSH_HIGHLIGHT_STYLES[precommand]='fg=default,bold'
		ZSH_HIGHLIGHT_STYLES[path]='fg=default'
		ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'
		ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'
	# }}}

	# Powerline {{{
		PATH="$HOME/.local/bin:$PATH"
		source "$(python -m site --user-site)/powerline/bindings/zsh/powerline.zsh"
	# }}}

# }}}

# Behaviour {{{

	# vi keybindings {{{
		bindkey -v
		# map JK to ESC in command mode
		bindkey -M viins 'jk' vi-cmd-mode
		# VIm-style backspace
		bindkey "^?" backward-delete-char
	# }}}

	# Completion {{{

		# A whole bunch of useful completions
		antigen bundle zsh-users/zsh-completions
		fpath=($fpath $HOME/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-zsh-users-SLASH-zsh-completions.git/src)

		# Vagrant completion
		if which vagrant >/dev/null 2>&1; then
			antigen bundle vagrant
			fpath=($fpath $HOME/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-robbyrussell-SLASH-oh-my-zsh.git/plugins/vagrant)
		fi

		zmodload -i zsh/complist

		# Initialize the completion system
		autoload -Uz compinit
		compfresh=
		if [[ ! -a "${HOME}/.zcompdump" || $(date +'%j') > $(date +'%j' -r "${HOME}/.zcompdump") ]]; then
			compinit
		else
			compinit -C
		fi

		unsetopt menu_complete
		unsetopt flowcontrol
		setopt auto_menu
		setopt complete_in_word
		setopt always_to_end

		setopt auto_list
		setopt no_list_beep

		# Completions are case- and hypen-insensitive, and do substring completion
		zstyle ':completion:*' matcher-list 'm:{a-zA-Z-_}={A-Za-z_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

		# Use the menu select style
		zstyle ':completion:*:*:*:*:*' menu select
		bindkey '^[[Z' reverse-menu-complete # SHIFT-TAB to go back

		# Color completions when they’re files
		zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

		# Colors for processes in kill
		zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
		# List all processes owned by current user
		zstyle ':completion:*:*:*:*:processes' command "ps -u $USER -o pid,user,comm -w -w"

		# Disable named-directories autocompletion
		zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories

		# Use caching so that commands like apt and dpkg complete are useable
		zstyle ':completion::complete:*' use-cache 1
		zstyle ':completion::complete:*' cache-path "$HOME/.cache/zsh"

		# Don't complete uninteresting users
		zstyle ':completion:*:*:*:users' ignored-patterns \
			adm amanda apache at avahi avahi-autoipd beaglidx bin cacti \
			canna clamav daemon dbus distcache dnsmasq dovecot fax ftp games \
			gdm gkrellmd gopher hacluster haldaemon halt hsqldb ident \
			junkbust kdm ldap lp mail mailman mailnull man messagebus \
			mldonkey mysql nagios named netdump news nfsnobody nobody nscd \
			ntp nut nx obsrun openvpn operator pcap polkitd postfix postgres \
			privoxy pulse pvm quagga radvd rpc rpcuser rpm rtkit scard \
			shutdown squid sshd statd svn sync tftp usbmux uucp vcsa wwwrun \
			xfs '_*'
		# … unless we really want to.
		zstyle '*' single-ignored show

		expand-or-complete-with-dots() {
			# toggle line-wrapping off and back on again
			[[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
			print -Pn "%{%F{blue}……⌛%f%}"
			[[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam
			zle expand-or-complete
			zle redisplay
		}
		zle -N expand-or-complete-with-dots
		bindkey "^I" expand-or-complete-with-dots

	# }}}

	# No autocorrect, thank you {{{
		unsetopt correct_all
	# }}}

	# Show time for long commands {{{
		REPORTTIME=5
		TIMEFMT="%U user %S system %P cpu %*Es total"
	# }}}

	# History search {{{
		antigen bundle history-substring-search
	# }}}

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

# }}}

# Commands, functions, aliases {{{

	# EDITOR and VISUAL {{{
		if which nvim >/dev/null 2>&1; then
			export EDITOR=nvim
			export VISUAL=nvim
		elif which vim >/dev/null 2>&1; then
			export EDITOR=vim
			export VISUAL=vim
		elif which vi >/dev/null 2>&1; then
			export EDITOR=vi
			export VISUAL=vi
		fi
	# }}}

	# Add local executables to PATH {{{
		[[ -e "$HOME/.bin" ]] && PATH="$HOME/.bin:$PATH"
		[[ -e "$HOME/bin" ]] && PATH="$HOME/bin:$PATH"
	# }}}

	# Aliases {{{
		autoload -U is-at-least	# needed for the common-aliases plugin
		antigen bundle common-aliases
		alias ls='ls --color=auto'
		alias grep='grep --color=auto'
		alias ..='cd ..'
		alias ~='cd ~'
		alias -g ...='../..'
		alias -g ....='../../..'
		alias -g .....='../../../..'
		alias -g ......='../../../../..'
	# }}}

	# Create and enter directory {{{
		mcd() {
			mkdir -p "$1" && cd "$1";
		}
	# }}}

	# Switch between running program and shell real quick {{{
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
	# }}}

	# todo.txt {{{
		alias todo="${HOME}/.bin/todo.txt/todo.sh -d ~/.bin/todo.txt/todo.cfg"
	# }}}

	# gibo — .gitignore boilerplates {{{
		antigen bundle simonwhitaker/gibo
		PATH="$HOME/.antigen/repos/https-COLON--SLASH--SLASH-github.com-SLASH-simonwhitaker-SLASH-gibo.git:$PATH"
	# }}}

	# Github’s Hub {{{
		if which hub >/dev/null 2>&1; then
			alias git=hub
			# Allow completions for git aliases when git is wrapped by hub
			compdef hub=git
		fi
	# }}}

	# RVM {{{
		[[ -e "$HOME/.rvm/scripts/rvm" ]] && source ~/.rvm/scripts/rvm
		[[ -e "/usr/local/rvm/scripts/rvm" ]] && source /usr/local/rvm/scripts/rvm
		[[ -e "$HOME/.rvm/bin" ]] && PATH="$HOME/.rvm/bin:$PATH"
	# }}}

	# Load NVM {{{
		export NVM_LAZY_LOAD=true
		antigen bundle lukechilds/zsh-nvm
	# }}}

	# direnv {{{
		which direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
	# }}}

	# Composer {{{
		[[ -e "$HOME/.config/composer/vendor/bin" ]] && PATH="$HOME/.config/composer/vendor/bin:$PATH"
	# }}}

# }}}

# Apply antigen {{{
	antigen apply
# }}}

# Things that must come last {{{

	# Use history-substring-search in vi mode also
	# https://github.com/zsh-users/zsh-syntax-highlighting/issues/340
	bindkey -M vicmd 'k' history-substring-search-up
	bindkey -M vicmd 'j' history-substring-search-down

# }}}

# Export PATH {{{
	# Instead of exporting it multiple times, do it once at the end for better
	# perfomance.
	export PATH
# }}}

# vim: set foldmethod=marker foldlevel=0 textwidth=78:
