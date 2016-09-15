#!/bin/bash
# Usage in .tmux.conf:
# if-shell "~/.tmux/tmux-version.sh '-ge' '2.1'" 'command' ['command']

if [ "$(tmux -V | cut -c 6- | sed 's/[a\.]//g')" $1 "$(sed 's/[a\.]//g' <<< $2)" ]; then
	exit 0
else
	exit 1
fi
