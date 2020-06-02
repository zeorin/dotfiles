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
# * support for local modification with .zshrc.before and .zshrc.after; and
# * making it look attractive.

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
	[[ -e "$HOME/.tmux/session_chooser.sh" ]] && source ~/.tmux/session_chooser.sh
# }}}

# Load antigen {{{
	source ~/.dotfiles/antigen/antigen.zsh
# }}}

# Appearance {{{

<<<<<<< HEAD
	# Starship {{{
		eval "$(starship init zsh)"
	# }}}

=======
>>>>>>> chore: remove powerline
	# Cursor shape {{{
		function change-cursor {
			case $KEYMAP in
				viins|main) print -n -- "\E[5 q";;	# DECSCUSR Blink Bar
				vicmd)      print -n -- "\E[2 q";;	# DECSCUSR Steady Block
			esac
			# Starship has already defined this
			zle-keymap-select
			zle -R
		}
		function reset-cursor {
			print -n -- "\E[2 q"	# DECSCUSR Steady Block
		}
		zle -N zle-keymap-select change-cursor
		zle -N zle-line-init change-cursor
		zle -N zle-line-finish reset-cursor
	# }}}

	# Set LS_COLORS {{{
		if [[ "$OSTYPE" == *gnu* ]]; then
			eval `dircolors ~/.dir_colors`
		fi
	# }}}

	# Syntax highlighting {{{
		antigen bundle zsh-users/zsh-syntax-highlighting
		ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
		typeset -A ZSH_HIGHLIGHT_STYLES
		ZSH_HIGHLIGHT_STYLES[alias]='fg=white,bold'
		ZSH_HIGHLIGHT_STYLES[builtin]='fg=white,bold'
		ZSH_HIGHLIGHT_STYLES[command]='fg=white,bold'
		ZSH_HIGHLIGHT_STYLES[function]='fg=white,bold'
		ZSH_HIGHLIGHT_STYLES[precommand]='fg=white,bold'
		ZSH_HIGHLIGHT_STYLES[path]='fg=default'
		ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=cyan'
		ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=cyan'
	# }}}

	# man colors {{{
		# https://wiki.archlinux.org/index.php/Color_output_in_console#man
		# https://wiki.archlinux.org/index.php/Color_output_in_console#less
		# LESS_TERMCAP_mb begin blink
		# LESS_TERMCAP_md begin bold
		# LESS_TERMCAP_me reset all modes
		# LESS_TERMCAP_so begin reverse video
		# LESS_TERMCAP_se reset reverse video
		# LESS_TERMCAP_us begin underline
		# LESS_TERMCAP_ue reset underline
		man() {
			LESS_TERMCAP_mb=$'\e[5m' \
			LESS_TERMCAP_md=$'\e[1;38;5;7m' \
			LESS_TERMCAP_me=$'\e[0m' \
			LESS_TERMCAP_so=$'\e[7;38;5;3m' \
			LESS_TERMCAP_se=$'\e[27;39m' \
			LESS_TERMCAP_us=$'\e[4;38;5;4m' \
			LESS_TERMCAP_ue=$'\e[24;39m' \
			command man "$@"
		}
	# }}}

	# grep, ls colors {{{
		alias grep='grep --color=auto'
		alias ls='ls --color=auto'
	# }}}

# }}}

# Behaviour {{{

	# Make sure we can register hooks
	autoload -Uz add-zsh-hook

	# vi keybindings {{{
		bindkey -v
		# VIm-style backspace
		bindkey "^?" backward-delete-char
	# }}}

	# No autocorrect, thank you {{{
		unsetopt correct_all
	# }}}

	# Show time for long commands {{{
		REPORTTIME=5
		TIMEFMT="%U user %S system %P cpu %*Es total"
	# }}}

	# Send desktop notification and ring terminal bell when long command finishes {{{
		# Mostly copied from zbell.sh https://gist.github.com/jpouellet/5278239

		# get $EPOCHSECONDS. builtins are faster than date(1)
		zmodload zsh/datetime || return

		# initialize zbell_duration if not set
		(( ${+zbell_duration} )) || zbell_duration=60

		# initialize zbell_ignore if not set
		(( ${+zbell_ignore} )) || zbell_ignore=(fg man)

		# initialize it because otherwise we compare a date and an empty string
		# the first time we see the prompt. it's fine to have lastcmd empty on the
		# initial run because it evaluates to an empty string, and splitting an
		# empty string just results in an empty array.
		zbell_timestamp=$EPOCHSECONDS

		# right before we begin to execute something, store the time it started at
		zbell_begin() {
			zbell_timestamp=$EPOCHSECONDS
			zbell_lastcmd=$2
		}

		# when it finishes, if it's been running longer than $zbell_duration,
		# and we dont have an ignored command in the line, then print a bell.
		zbell_end() {
			local ran_long=$(( $EPOCHSECONDS - $zbell_timestamp >= $zbell_duration ))
			local ignore_cmds=($EDITOR $VISUAL $PAGER $zbell_ignore)

			local has_ignored_cmd=0
			for cmd in ${(s:;:)zbell_lastcmd//|/;}; do
				local words=(${(z)cmd})
				local util=${words[1]}
				if (( ${ignore_cmds[(i)$util]} <= ${#ignore_cmds} )); then
					has_ignored_cmd=1
					break
				fi
			done

			if (( ! $has_ignored_cmd )) && (( ran_long )); then
				if (( $+commands[notify-send] )); then
					notify-send "Job \"$zbell_lastcmd\" has finished!"
				else
					print -n "\a"
				fi
			fi
		}

		# register the functions as hooks
		add-zsh-hook preexec zbell_begin
		add-zsh-hook precmd zbell_end
	# }}}

	# History search {{{
		antigen bundle zsh-users/zsh-history-substring-search zsh-history-substring-search.zsh
	# }}}

	# Change directories more easily {{{
		setopt auto_cd
	# }}}

	# Window title {{{
		title_precmd() {
			print -n "\e]2;$("$HOME"/.dotfiles/scripts/short_path "$(print -P '%d')")\a"
		}
		title_preexec() {
			print -n "\e]2;$("$HOME"/.dotfiles/scripts/short_path "$(print -P '%d')") ${(q)1}\a"
		}
		if [[ "$TERM" == (tmux*|screen*|xterm*|rxvt*) ]]; then
			add-zsh-hook -Uz precmd title_precmd
			add-zsh-hook -Uz preexec title_preexec
		fi
	# }}}

	# Configure history {{{
		export HISTSIZE=100000 SAVEHIST=100000 HISTFILE=~/.zhistory
		setopt share_history
		setopt hist_expire_dups_first
		setopt hist_find_no_dups
		setopt hist_ignore_all_dups
		setopt hist_ignore_space
		setopt hist_reduce_blanks
		setopt hist_save_no_dups
		setopt hist_verify
	# }}}

# }}}

# Commands, functions, aliases {{{

	# Home Manager {{{
		export NIX_PATH=$HOME/.nix-defexpr/channels${NIX_PATH:+:}$NIX_PATH
	# }}}

	# Named directories {{{
		# Make all Client directories bookmarks
		for dir in ~/Documents/Pixel\ Theory/Clients/*; do
			hash -d "$(echo $(basename $dir) | sed "s/ /_/g" | sed 's/[][]//g')"=$dir
		done
	# }}}

	# $EDITOR, $VISUAL, $LESS, and $PAGER {{{
		if command -v emacsclient >/dev/null 2>&1; then
			export EDITOR="emacsclient -c"
			alias e="emacsclient -c -n"
		elif command -v vi >/dev/null 2>&1; then
			export EDITOR=vi
			alias e=vi
		fi
		export VISUAL="$EDITOR"
		export LESS="-FiRx4"
		export PAGER="less $LESS"
	# }}}

	# Ask the shell nicely to do things as root {{{
		alias please='sudo $(fc -ln -1)'
	# }}}

	# Aliases {{{
		autoload -U is-at-least	# needed for the common-aliases plugin

		# Common aliases {{{
			# antigen bundle common-aliases
			# We don’t want some of these aliases, so manually include the
			# ones we like from
			# https://github.com/robbyrussell/oh-my-zsh/blob/master/plugins/common-aliases/common-aliases.plugin.zsh

			# ls, the common ones I use a lot shortened for rapid fire usage
			alias l='ls -lFh'     #size,show type,human readable
			alias la='ls -lAFh'   #long list,show almost all,show type,human readable
			alias lr='ls -tRFh'   #sorted by date,recursive,show type,human readable
			alias lt='ls -ltFh'   #long list,sorted by date,show type,human readable
			alias ll='ls -l'      #long list
			alias ldot='ls -ld .*'
			alias lS='ls -1FSsh'
			alias lart='ls -1Fcart'
			alias lrt='ls -1Fcrt'

			alias zshrc='${=EDITOR} ~/.zshrc' # Quick access to the ~/.zshrc file

			# alias grep='grep --color'
			alias sgrep='grep -R -n -H -C 5 --exclude-dir={.git,.svn,CVS} '

			# alias t='tail -f'

			# Command line head / tail shortcuts
			alias -g H='| head'
			alias -g T='| tail'
			alias -g G='| grep'
			alias -g L="| less"
			alias -g M="| most"
			alias -g LL="2>&1 | less"
			alias -g CA="2>&1 | cat -A"
			alias -g NE="2> /dev/null"
			alias -g NUL="> /dev/null 2>&1"
			alias -g P="2>&1| pygmentize -l pytb"

			alias dud='du -d 1 -h'
			alias duf='du -sh *'
			alias fd='find . -type d -name'
			alias ff='find . -type f -name'

			alias h='history'
			alias hgrep="fc -El 0 | grep"
			alias help='man'
			alias p='ps -f'
			alias sortnr='sort -n -r'
			alias unexport='unset'

			# alias rm='rm -i'
			# alias cp='cp -i'
			# alias mv='mv -i'

			# zsh is able to auto-do some kungfoo
			# depends on the SUFFIX :)
			if is-at-least 4.2.0; then
			# open browser on urls
			if [[ -n "$BROWSER" ]]; then
				_browser_fts=(htm html de org net com at cx nl se dk)
				for ft in $_browser_fts; do alias -s $ft=$BROWSER; done
			fi

			_editor_fts=(cpp cxx cc c hh h inl asc txt TXT tex)
			for ft in $_editor_fts; do alias -s $ft=$EDITOR; done

			if [[ -n "$XIVIEWER" ]]; then
				_image_fts=(jpg jpeg png gif mng tiff tif xpm)
				for ft in $_image_fts; do alias -s $ft=$XIVIEWER; done
			fi

			_media_fts=(ape avi flv m4a mkv mov mp3 mpeg mpg ogg ogm rm wav webm)
			for ft in $_media_fts; do alias -s $ft=mplayer; done

			#read documents
			alias -s pdf=acroread
			alias -s ps=gv
			alias -s dvi=xdvi
			alias -s chm=xchm
			alias -s djvu=djview

			#list whats inside packed file
			alias -s zip="unzip -l"
			alias -s rar="unrar l"
			alias -s tar="tar tf"
			alias -s tar.gz="echo "
			alias -s ace="unace l"
			fi

			# Make zsh know about hosts already accessed by SSH
			zstyle -e ':completion:*:(ssh|scp|sftp|rsh|rsync):hosts' hosts 'reply=(${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })'
		# }}}

		alias ..='cd ..'
		alias ~='cd ~'
		alias -g ...='../..'
		alias -g ....='../../..'
		alias -g .....='../../../..'
		alias -g ......='../../../../..'

		alias dotfiles='cd ~/.dotfiles'
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

	# Open ZLE buffer as filename in editor {{{
		edit-file () {
			BUFFER="$VISUAL $BUFFER"
			zle accept-line "$@"
		}
		zle -N edit-file
		bindkey '^P' edit-file
	# }}}

	# Alt-left to go back {{{
		cdUndoDir() {
			popd
			zle reset-prompt
			echo
			ls -l
			zle reset-prompt
		}
		zle -N cdParentDir
		bindkey '^[[1;3A' cdParentDir
	# }}}

	# Alt-up to go to parent directory {{{
		cdParentDir() {
			pushd ..
			zle reset-prompt
			echo
			ls -l
			zle reset-prompt
		}
		zle -N cdUndoDir
		bindkey '^[[1;3D' cdUndoDir
	# }}}

	# Pretty file print {{{
		alias cat=bat
		export BAT_PAGER="$PAGER"
	# }}}

	# git {{{
		alias g='git'
	# }}}

	# Github’s Hub {{{
		# if command -v hub >/dev/null 2>&1; then
		# 	alias git='hub'
		# fi
	# }}}

	# RVM {{{
		[[ -e "$HOME/.rvm/scripts/rvm" ]] && source ~/.rvm/scripts/rvm
		[[ -e "/usr/local/rvm/scripts/rvm" ]] && source /usr/local/rvm/scripts/rvm
		[[ -d "$HOME/.rvm/bin" ]] && PATH="$PATH:$HOME/.rvm/bin"
	# }}}

	# Load NVM {{{
		export NVM_NO_USE=true
		antigen bundle lukechilds/zsh-nvm
	# }}}

	# direnv {{{
		command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"
	# }}}

	# todo.sh {{{
		export TODOTXT_DEFAULT_ACTION=ls
		(( $+commands[todo.sh] )) && alias t='todo.sh'
	# }}}

	# Yarn binaries in path {{{
		[[ -d "$HOME/.yarn/bin" ]] && PATH="$PATH:$HOME/.yarn/bin"
	# }}}

	# Local bin {{{
		[[ -d "$HOME/.local/bin" ]] && PATH="$PATH:$HOME/.local/bin"
	# }}}

# }}}

# Completion {{{

	# A whole bunch of useful completions
	antigen bundle zsh-users/zsh-completions

	# Vagrant completion
	if command -v vagrant >/dev/null 2>&1; then
		antigen bundle vagrant
	fi

	# Completion for `git ci` (complex alias defined in ~/.gitconfig)
	_git-ci () { _git-commit }

	# Initialize the completion system
	autoload -U +X compinit && compinit
	autoload -U +X bashcompinit && bashcompinit

	zmodload -i zsh/complist

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

	# Support for custom local completions
	[[ -d "$HOME/.zsh/completions" ]] && fpath=("$HOME/.zsh/completions" $fpath)

	# Support for custom local bash completions
	if [[ -d "$HOME/.bash/completions" ]]; then
		for file in "$HOME/.bash/completions/"*; do
			source "$file"
		done
	fi

# }}}

# Apply antigen {{{
	antigen apply
# }}}

# Export PATH {{{
	# Instead of exporting it multiple times, do it once at the end for better
	# performance.
	export PATH
# }}}

# Things that must come last {{{
	bindkey -M vicmd 'k' history-substring-search-up
	bindkey -M vicmd 'j' history-substring-search-down
# }}}

# vim: set foldmethod=marker foldlevel=0 foldcolumn=3 textwidth=78:
