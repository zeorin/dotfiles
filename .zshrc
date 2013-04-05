# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="xandor"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(debian gibo git git-extras git-flow github git-hubflow git-remote-branch gnu-utils history history-substring-search node npm svn zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=/usr/lib/lightdm/lightdm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/opt/android/tools:~/.bin:$HOME/.rvm/bin:/usr/local/bin/android-sdk-linux/platform-tools

# Execute rvm scripts, need this to enable compass
[[ -a '~/.rvm/scripts/rvm' ]] && print file exists
[[ -a '~/.rvm/scripts/rvm' ]] && source ~/.rvm/scripts/rvm 

# Turn on colors in autocompletion
eval `dircolors ~/.dir_colors`

# Turn on syntax highlighting
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
ZSH_HIGHLIGHT_STYLES[alias]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[command]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=default,bold'
ZSH_HIGHLIGHT_STYLES[path]='fg=default'
ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=magenta,bold'
ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=magenta,bold'

# completion
zmodload -i zsh/complist
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# no autocorrect, thank you
unsetopt correct_all

# Set up aliases
alias ..='cd ..'
alias ~='cd ~'

alias ls='ls -h --color --group-directories-first'
alias ll='ls -l'
alias la='ls -la'

alias -g L="|less"
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'

# MTP aliases
alias galaxys2-connect="go-mtpfs -allow-other=true /media/galaxys2"
alias galaxys2-disconnect="umount /media/galaxys2"
alias nexus7-connect="go-mtpfs -allow-other=true /media/nexus7"
alias nexus7-disconnect="umount /media/nexus7"
alias tf201-connect="go-mtpfs -allow-other=true /media/tf201"
alias tf201-disconnect="umount /media/tf201"

# source alias.sh aliases
source ~/.aliases

# Show time for long commands
REPORTTIME=5
TIMEFMT="%U user %S system %P cpu %*Es total"

# Set up custom functions
precmd() {
  [[ -t 1 ]] || return
  case $TERM in
    (sun-cmd) print -Pn "\e]l%~\e\\"
      ;;
    (*xterm*|rxvt|(dt|k|E)term) print -Pn "\e]2;%~\a"
      ;;
  esac
}
