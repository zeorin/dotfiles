wget -q -O - "$@" https://alias.sh/user/2006/alias > ~/.aliases

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
