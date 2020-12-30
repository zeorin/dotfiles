# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
	PATH="$HOME/bin:$PATH"
fi

# https://bugs.launchpad.net/bugs/1876219
export MESA_LOADER_DRIVER_OVERRIDE=i965
