# To do list for zeorin's dotfiles

## Installation of programs
We need to add bash configuration files in case zsh cannot be installed. On
some systems installing programs is not going to be allowed, and the resulting
environment should still be as close as possible to what is ideal.

Add vi configuration for when vim is not available.

Add screen configuration for when tmux is not available.

Add svn configuration for when git is not available.

## Compatibility
Currently it has only been set up to work with Ubuntu. Although it's likely
that it will work for Debian systems also, this has not been tested.

In the future this should be compatible with various major flavours of Linux,
OS X and Cygwin.

## Dependence on other projects
Currently a major depenency is on oh-my-zsh. This is a great starting place,
but adds a lot of overhead for things that aren't used, and complicates the
git setup. Over time I should pick the things I like about oh-my-zsh and
implement them independently.

There are a lot of submodules in this repo, e.g. vim plugins. However, that is
as it should be. This makes it easy to add, remove and update these plugins

## Automation
Currently updating this repo (and it's submodules) needs to be done by hand.
It would be better if this were updated regularly (perhaps once a day, if the
user is logging in) and transparently to the user. Perhaps this can be added
to the rc shell scripts.

## Terminal emulator setup
Currently the colour scheme has been set for terminator, but I should try to
find out whether there is a way to change ASCII codes in such a way that it
would work for any terminal emulator, or even yet a tty instead only a pty.
