#!/bin/sh

dark_mode_on=$( [ "$(xfconf-query -c xsettings -p /Net/ThemeName)" = "Arc-Dark" ]; echo $? )

if [ $dark_mode_on = 0 ]; then
	xfconf-query --create --type=string -c xsettings -p /Net/ThemeName -s "Arc"
else
	xfconf-query --create --type=string -c xsettings -p /Net/ThemeName -s "Arc-Dark"
fi
