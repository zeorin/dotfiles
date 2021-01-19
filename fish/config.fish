if status is-interactive

	# Tmux session chooser {{{
		if test -e ~/.tmux/session_chooser.fish
			source ~/.tmux/session_chooser.fish
		end
	# }}}

	set -Ux EDITOR nvim
	set -Ux VISUAL nvim
	set -Ux LESS "-FiRx4"
	set -Ux PAGER "less $LESS"

	alias g "git"
	alias e nvim
	alias m "neomutt"
	alias o "xdg-open"
	alias s "systemctl"
	alias d "docker"
	alias j "journalctl -xe"
	alias cat "bat"
	alias grep "grep --color=auto"
	alias ls "ls --color=auto"
	function man --wraps man --description 'man with more formatting'
		set -x MANWIDTH ([ $COLUMNS -gt "80" ] && echo "80" || echo $COLUMNS)
		set -x LESS_TERMCAP_mb (printf '\e[5m')
		set -x LESS_TERMCAP_md (printf '\e[1;38;5;7m')
		set -x LESS_TERMCAP_me (printf '\e[0m')
		set -x LESS_TERMCAP_so (printf '\e[7;38;5;3m')
		set -x LESS_TERMCAP_se (printf '\e[27;39m')
		set -x LESS_TERMCAP_us (printf '\e[4;38;5;4m')
		set -x LESS_TERMCAP_ue (printf '\e[24;39m')
		command man $argv
	end

	eval (direnv hook fish)

	# Use Vi keys, and Emacs keys
	function fish_user_key_bindings
		# Execute this once per mode that emacs bindings should be used in
		fish_default_key_bindings -M insert
		# Then execute the vi-bindings so they take precedence when there's a conflict.
		# Without --no-erase fish_vi_key_bindings will default to
		# resetting all bindings.
		# The argument specifies the initial mode (insert, "default" or visual).
		fish_vi_key_bindings --no-erase insert
	end

	fish_vi_cursor
	# Emulates vim's cursor shape behavior
	# Set the normal and visual mode cursors to a block
	set fish_cursor_default block
	# Set the insert mode cursor to a line
	set fish_cursor_insert line
	# Set the replace mode cursor to an underscore
	set fish_cursor_replace_one underscore
	# The following variable can be used to configure cursor shape in
	# visual mode, but due to fish_cursor_default, is redundant here
	set fish_cursor_visual block

	starship init fish | source

	function ntfy_on_duration -e fish_prompt
		if test $CMD_DURATION; and test $CMD_DURATION -gt (math "1000 * 10")
			set secs (math "$CMD_DURATION / 1000")
			ntfy -t "$history[1]" send "Returned $status, took $secs seconds"
		end
	end

end
