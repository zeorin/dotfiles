#!/bin/sh

dark_mode_on=$( [ "$(xfconf-query -c xsettings -p /Net/ThemeName)" = "Nordic" ]; echo $? )

if [ $dark_mode_on = 0 ]; then
	~/.local/share/light-mode.d/gtk-theme.sh
else
	~/.local/share/dark-mode.d/gtk-theme.sh
fi
