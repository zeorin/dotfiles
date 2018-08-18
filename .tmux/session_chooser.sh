#!/bin/sh
if command -v tmux >/dev/null 2>&1 && [ -z "$TMUX" ]; then

	# If this is a remote tty, allow the MOTD, banner, etc. to be seen first
	parent_process=$(ps -o comm= -p "$PPID")
	if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -z "${parent_process##*sshd}" ]; then
		print -n '\e[7mPress any key to continue…\e[0m';
		saved_tty=$(stty -g </dev/tty)
		stty raw -echo
		dd if=/dev/tty bs=1 count=1 >/dev/null 2>&1
		stty "$saved_tty"
	fi

	tmux_unattached_sessions=$(tmux list-sessions -F '#{session_name} #{session_attached}' 2>/dev/null | grep ' 0$' | sed -e 's/ 0$//')

	if [ -z "$tmux_unattached_sessions" ]; then
		exec tmux new-session
	else
		tmux_new_session=$(tmux new-session -dPF '#{session_name}')
		exec tmux \
			attach -t "$tmux_new_session" \; \
			choose-tree -s -f '#{?session_attached,0,1}' \
				"switch-client -t '%%'; kill-session -t '$tmux_new_session'"
	fi
fi
