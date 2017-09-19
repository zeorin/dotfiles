#!/bin/bash
# Usage in .tmux.conf:
# if-shell "~/.tmux/tmux-version.sh '-ge' '2.1'" 'command' ['command']

if [ "$(tmux -V | cut -c 6- | sed 's/\([0-9]\+\)\.\?\([0-9]*\).*/\1\2/')" $1 "$(sed 's/\([0-9]\+\)\.\?\([0-9]*\).*/\1\2/' <<< $2)" ]; then
	exit 0
else
	exit 1
fi
