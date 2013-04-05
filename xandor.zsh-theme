# Define colour variables to make life easier. Colour names are from Solarized.
eval FG_BASE01='%{$fg_bold[green]%}'
eval FG_BASE00='%{$fg_bold[yellow]%}'
eval FG_BASE0='%{$fg_bold[blue]%}'
eval FG_BASE1='%{$fg_bold[cyan]%}'
eval FG_YELLOW='%{$fg_no_bold[yellow]%}'
eval FG_ORANGE='%{$fg_bold[red]%}'
eval FG_RED='%{$fg_no_bold[red]%}'
eval FG_MAGENTA='%{$fg_no_bold[magenta]%}'
eval FG_VIOLET='%{$fg_bold[magenta]%}'
eval FG_BLUE='%{$fg_no_bold[blue]%}'
eval FG_CYAN='%{$fg_no_bold[cyan]%}'
eval FG_GREEN='%{$fg_no_bold[green]%}'
eval BG_DARK='%{$bg[black]%}'
eval BG_LIGHT='%{$bg[white]%}'

PROMPT='%{$FG_BASE00%}%20<...<%~%<< %{$FG_BASE0%}$(svn_prompt_info)%{$FG_BASE0%}%{$FG_BASE0%}$(git_prompt_info)%{$FG_BASE0%}%{$FG_GREEN%}%% %{$reset_color%}'
RPROMPT='%{$FG_BASE01%}%T%{$reset_color%}'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$FG_YELLOW%}git%{$FG_BASE00%}:%{$FG_BLUE%}"
ZSH_THEME_GIT_PROMPT_SUFFIX=""
ZSH_THEME_GIT_PROMPT_DIRTY=" %{$FG_RED%}✗  "
ZSH_THEME_GIT_PROMPT_CLEAN=" "

ZSH_THEME_SVN_PROMPT_PREFIX="%{$FG_YELLOW%}svn%{$FG_BASE00%}:%{$FG_BLUE%}"
ZSH_THEME_SVN_PROMPT_SUFFIX=""
ZSH_THEME_SVN_PROMPT_DIRTY=" %{$FG_RED%}✗  "
ZSH_THEME_SVN_PROMPT_CLEAN=" "
