#!/bin/sh

dark_mode_on=$( [ "$(xfconf-query -c xsettings -p /Net/ThemeName)" = "Nordic" ]; echo $? )

if [ $dark_mode_on = 0 ]; then
	xfconf-query --create --type=string -c xsettings -p /Net/ThemeName -s "Nordic-Polar"
else
	xfconf-query --create --type=string -c xsettings -p /Net/ThemeName -s "Nordic"
fi
