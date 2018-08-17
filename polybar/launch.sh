#!/bin/sh

# Terminate already running bar instances
killall -q polybar

# Wait until the processes have been shut down
while pgrep -u "$(id -u)" -x polybar >/dev/null; do sleep 1; done

# Launch bar on each monitor
if command -v xrandr >/dev/null 2>&1; then
	for m in $(xrandr --query | grep " connected" | cut -d" " -f1); do
		MONITOR=$m polybar top &
	done
else
	polybar top &
fi
