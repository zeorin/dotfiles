if status is-interactive

	# Tmux session chooser {{{
		if test -e ~/.tmux/session_chooser.fish
			source ~/.tmux/session_chooser.fish
		end
	# }}}

	set EDITOR nvim

	alias g "git"
	alias e $EDITOR
	alias m "neomutt"
	alias o "xdg-open"

	alias cat "bat"
	alias man "MANWIDTH=([ $COLUMNS -gt "80" ] && echo "80" || echo $COLUMNS) command man"

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

end
