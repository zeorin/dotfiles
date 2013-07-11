#!/bin/sh

##########
# setup.sh
#
# This file is used to set up a new machine with the dotfiles.
# Currently only compatible with Ubuntu (and maybe Debian, haven't
# tested this).
##########

# Install programs and their settings
##########
# Each program and it's settings are installed using their own shell scripts
# The programs we want are:
# * zsh: a superior command line shell, currently using oh-my-zsh
# * tmux: a terminal multiplexer;
# * git: version control;
# * vim: best text editor IMO;
# * ack: beyond grep;

# Install various configuration files
##########
# * editorconfig: nice to make editors behave consistently;
# * inputrc: configure GNU readline;
# * terminatorconfig: config for my favourite pty;
