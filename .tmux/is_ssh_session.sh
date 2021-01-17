#!/usr/bin/env sh
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ] || [ -n "$SSH_CONNECTION" ]; then
	exit 0
else
	case $(ps -o comm= -p $PPID) in
		sshd|*/sshd) exit 0;;
	esac
fi
exit 1
