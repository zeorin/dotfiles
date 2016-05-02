" Vim settings {{{1
set nocompatible | filetype indent plugin on | syn on

" Set the leader, needs to be done early
let g:mapleader = "\<Space>"

if !has('nvim')
	set encoding=utf-8
endif

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" use visual terminal bell
set vb

" line numbers
set relativenumber
" Show current line number in number column
set number

" Don't break words when wrapping lines
set linebreak

" check final line for Vim settings
set modelines=1

" make wrapped lines more obvious
let &showbreak="↳ "
set cpoptions+=n

" When wrap is off, horizontally scroll a decent amount.
set sidescroll=16

" Ingore backup files & git directories
set wildignore+=*~,.git

" set tabs to display as 4 spaces wide (might be overwritten by .editorconfig
" files)
set tabstop=4 softtabstop=4 noexpandtab
set smarttab
set shiftround

" keep max lines of command line history
set history=10000

" show the cursor position all the time
set ruler

" Highlight the line I'm on
set cursorline

" Highlight matching paired delimiter
set showmatch

" Only redraw when necessary
set lazyredraw

" display incomplete commands
set showcmd

" do incremental searching
set incsearch

" ignore case sensitivity in searching
set ignorecase

" smart case sensitivity in searching
set smartcase

" better command line completion
set wildmode=longest,full
set wildmenu
set fileignorecase
set wildignorecase

" Enable code folding
set foldenable
set foldlevelstart=10
set foldnestmax=10
set foldmethod=indent

" Switch buffers even if modified
set hidden

" better split window locations
set splitright
set splitbelow

" In many terminal emulators the mouse works just fine, thus enable it.
if has('mouse')
	set mouse=a
endif

" Configure the use of backup files
if has("vms")
	set nobackup		" do not keep a backup file, use versions instead
else
	set backup		" keep a backup file
endif

" Make tabs, non-breaking spaces and trailing white space visible
set list
" Use a Musical Symbol Single Barline (0x1d100) to show a Tab, and
" a Middle Dot (0x00B7) for trailing spaces
set listchars=tab:\𝄀\ ,trail:·,extends:>,precedes:<,nbsp:+

" Spell check & word completion
" TODO: Figure out how to support smart quotes in spell check
set spell spelllang=en_gb
set complete+=kspell
set complete-=i

" Display as much as possible of a line that doesn't fit on screen
set display=lastline

" Better autoformat
set formatoptions+=j	" Remove comment leader when joining lines
set formatoptions-=o	" Don't automatically assume next line after comment is also comment

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
syntax on
set hlsearch

" Reread changed files
set autoread

" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on

" Put these in an autocmd group, so that we can delete them easily.
augroup vimrcEx
	au!

	" For all text files set 'textwidth' to 78 characters.
	autocmd FileType text,markdown setlocal textwidth=78

	" When editing a file, always jump to the last known cursor position.
	" Don't do it when the position is invalid or when inside an event handler
	" (happens when dropping a file on gvim).
	" Also don't do it when the mark is in the first line, that is the default
	" position when opening a file.
	autocmd BufReadPost *
		\ if line("'\"") > 1 && line("'\"") <= line("$") |
		\   exe "normal! g`\"" |
		\ endif

augroup END

" Where to look for tags files
set tags=.git/tags;,./tags,~/.vimtags;

" Powerline-ish specific settings
set laststatus=2 " Always display the statusline in all windows
set showtabline=2 " Always display the tabline, even if there is only one tab
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)

" Persistent undo
let vimDir = '$HOME/.vim'
if has('persistent_undo')
	let myUndoDir = expand(vimDir . '/undo')
	" Create dirs
	call system('mkdir ' . myUndoDir)
	let &undodir = myUndoDir
	set undofile
endif

" Faster update for Git Gutter
set updatetime=750

" Set comments to be italic
highlight Comment gui=italic cterm=italic
augroup italiccomments
	autocmd!
	autocmd ColorScheme * highlight Comment gui=italic cterm=italic
augroup END

" Plugins {{{1

" Install vim-plug if necessary
if empty(glob('~/.vim/autoload/plug.vim'))
	silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
		\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

call plug#begin('~/.vim/plugged')

" Plugin list {{{2

" General Vim tweaks {{{3
Plug 'tpope/vim-sensible' " Sensible default settings we can all agree on
Plug 'tpope/vim-repeat' " Plugin mappings can be repeated with .
Plug 'tpope/vim-speeddating' " Use CTRL-A/CTRL-X to increment dates, times, and more
Plug 'tpope/vim-sleuth' " Heuristically set buffer options, like tabs/spaces
Plug 'tpope/vim-unimpaired' " Pairs of handy bracket mappings
Plug 'tpope/vim-rsi' " Readline style insertion
Plug 'tpope/vim-commentary' " Comment stuff out
Plug 'tpope/vim-surround' " Quoting/parenthesizing made simple
Plug 'tpope/vim-abolish' " Easily search for, substitute, and abbreviate multiple variants of a word
Plug 'matchit.zip' " (Possibly) updated matchit
Plug 'sickill/vim-pasta' " Better indentation when pasting
Plug 'editorconfig/editorconfig-vim' " EditorConfig support
Plug 'sjl/gundo.vim' " Visualize Vim's undo tree
Plug 'scrooloose/syntastic' " Syntax checking hacks
Plug 'scrooloose/nerdtree' " File tree explorer
Plug 'janlay/NERD-tree-project' " Try to find project dir
Plug 'airblade/vim-rooter' " Working directory is always project root
Plug 'svermeulen/vim-easyclip' " Better clipboard functionality
Plug 'wikitopian/hardmode' " Hard mode
Plug 'kbarrette/mediummode' " Less… hard

" Searching, finding, tagging {{{3
Plug 'ctrlpvim/ctrlp.vim' " Fuzzy file, buffer, mru, tag, etc finder
Plug 'mileszs/ack.vim' " Search code using Ag or Ack
Plug 'xolox/vim-misc' " Needed for Easytags
Plug 'xolox/vim-easytags' " Automated tag file generation and syntax highlighting of tags
Plug 'majutsushi/tagbar' " Display tags, ordered by scope

" Git {{{3
Plug 'tpope/vim-fugitive' " A Git wrapper so awesome, it should be illegal
Plug 'airblade/vim-gitgutter' " Git diff in the gutter (sign column) and stage/undo hunks
Plug 'Xuyuanp/nerdtree-git-plugin' " NERDTree showing git status

" Code completion {{{3
Plug 'tpope/vim-endwise' " Wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
Plug 'Raimondi/delimitMate' " Insert mode auto-completion for quotes, parens, brackets, etc.
Plug 'Valloric/YouCompleteMe' " A code-completion engine for Vim
Plug 'sirver/ultisnips' " The ultimate snippet solution for Vim
Plug 'honza/vim-snippets' " Community-maintained default snippets
Plug 'mattn/emmet-vim' " Emmet support

" Appearance {{{3
Plug 'altercation/vim-colors-solarized' " Precision colors for machines and people
Plug 'vim-airline/vim-airline' " Powerline-style status- and tab/buffer-line
Plug 'vim-airline/vim-airline-themes' " Collection of airline themes
Plug 'edkolev/tmuxline.vim' " Set tmux theme to airline theme
Plug 'edkolev/promptline.vim' " Set shell theme to airline theme
Plug 'ryanoasis/vim-devicons' " Pretty font icons like Seti-UI
Plug 'zeorin/vim-startify', { 'branch': 'devicons-tweak'} " Fancy start screen

" Tmux {{{3
Plug 'christoomey/vim-tmux-navigator' " Seamless navigation between tmux panes and vim splits

" Filetype {{{3

Plug 'sheerun/vim-polyglot' " A solid language pack (HTML5, CSS3, SASS, PHP, & about 74 others)

" PHP {{{4
Plug 'shawncplus/phpcomplete.vim', { 'for': 'php' } " Improved PHP omnicompletion
Plug '2072/php-indenting-for-vim', { 'for': 'php' } " Updated official PHP indent

" Text-like {{{4
" Define text-like file types
let markdownft = ['markdown', 'mkd']
let textlikeft = markdownft + ['text', 'mail', 'gitcommit']

Plug 'reedes/vim-pencil', { 'on': [] } " Rethinking Vim as a tool for writers;
Plug 'junegunn/goyo.vim', { 'on': [] } " Distraction-free writing
Plug 'junegunn/limelight.vim', { 'on': [] } " Hyper-focus writing
" Plug 'reedes/vim-lexical', { 'for': textlikeft } " Build on Vim’s spell/thes/dict completion
Plug 'reedes/vim-litecorrect' " Light-weight auto-correction
Plug 'kana/vim-textobj-user' " Create your own text objects
Plug 'reedes/vim-textobj-quote' " Use ‘curly’ quote characters
Plug 'reedes/vim-textobj-sentence', { 'on': [] } " Improved native sentence text object and motion;
Plug 'reedes/vim-wordy', { 'for': textlikeft } " Uncover usage problems in your writing
Plug 'mattly/vim-markdown-enhancements', { 'for': markdownft } " Support for MultiMarkdown, CriticMark, etc.

" Plugin settings & tweaks {{{2

" TODO: Figure out how to set buffer settings with both
" vim-sleuth and editorconfig settings enabled. Editorconfig
" settings should trump vim-sleuth settings for any given buffer.

" General Vim tweaks {{{3

" Rooter {{{4
let g:rooter_patterns = ['.git/']

" Syntastic {{{4
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_quiet_messages = { "type": "style" }
let g:syntastic_html_tidy_exec = '/usr/local/bin/tidy'

" Gundo {{{4
nnoremap <Leader>u :GundoToggle<CR>

" NERDTree {{{4
nnoremap <F8> :NERDTreeToggle<CR>
let g:NTPNamesDirs = ['.git']

" HardMode {{{4
nnoremap <Leader>hm :call ToggleHardMode()<CR>

" MediumMode {{{4
let g:mediummode_enabled = 0
nnoremap <Leader>mm :MediumModeToggle<CR>

" Searching, finding, tagging {{{3

" Easytags {{{4
let g:easytags_languages = {
	\'javascript': {
		\'cmd': '/usr/bin/jsctags',
		\'args': [],
		\'fileoutput_opt': '-f',
		\'stdout_opt': '-f-',
		\'recurse_flag': '-R'
	\}
\}
let g:easytags_dynamic_files = 2
let g:easytags_async = 1

" CtrlP {{{4
let g:ctrlp_match_window = 'bottom,order:ttb'
let g:ctrlp_switch_buffer = 0
let g:ctrlp_working_path_mode = 0
let g:ctrlp_use_caching = 0
if executable('ag')
	" If the silver searcher is installed
	let g:ctrlp_user_command = 'ag %s -l --nocolor --hidden -g ""'
elseif executable('find')
	" If unix OS
	let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'find %s -type f']
elseif executable('dir')
	" If windows
	let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files . -co --exclude-standard', 'dir %s /-n /b /s /a-d']
endif

" Ack {{{4
if executable('ag')
	let g:ackprg = "ag --nogroup --nocolor --column"
	nnoremap <Leader>a :Ack |
elseif executable('ack') || executable ('ack-grep')
	nnoremap <Leader>a :Ack |
else
	nnoremap <Leader>a :grep |
endif

" Tagbar {{{4
nnoremap <F9> :TagbarToggle<CR>

" Code completion {{{3

" YouCompleteMe {{{4
let g:ycm_key_list_select_completion = ['<C-n>']
let g:ycm_key_list_previous_completion = ['<C-p>']

" UltiSnips {{{4
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsListSnippets="<C-a>"
let g:UltiSnipsJumpForwardTrigger="<C-b>"
let g:UltiSnipsJumpBackwardTrigger="<C-x>"
let g:UltiSnipsEditSplit="vertical"

" Appearance {{{3

" Airline {{{4
let g:airline_powerline_fonts = 1 " Use powerline glyphs
let g:airline#extensions#tabline#enabled = 1 " Use tabline
let g:airline#extensions#tabline#show_tabs = 1 " Always show tabline
let g:airline#extensions#tabline#show_buffers = 1 " Show buffers when no tabs

" Startify no spell check {{{4
augroup startify
	autocmd!
	autocmd FileType startify setlocal nospell
augroup END

" Solarized color dictionaries {{{4
let g:sol = {
	\"gui": {
		\"base03": "#002b36",
		\"base02": "#073642",
		\"base01": "#586e75",
		\"base00": "#657b83",
		\"base0": "#839496",
		\"base1": "#93a1a1",
		\"base2": "#eee8d5",
		\"base3": "#fdf6e3",
		\"yellow": "#b58900",
		\"orange": "#cb4b16",
		\"red": "#dc322f",
		\"magenta": "#d33682",
		\"violet": "#6c71c4",
		\"blue": "#268bd2",
		\"cyan": "#2aa198",
		\"green": "#719e07"
	\},
	\"cterm": {
		\"base03": 8,
		\"base02": 0,
		\"base01": 10,
		\"base00": 11,
		\"base0": 12,
		\"base1": 14,
		\"base2": 7,
		\"base3": 15,
		\"yellow": 3,
		\"orange": 9,
		\"red": 1,
		\"magenta": 5,
		\"violet": 13,
		\"blue": 4,
		\"cyan": 6,
		\"green": 2
	\}
\}

" Set white space colors {{{4
function! SetWhiteSpaceColor()
	if &background == "dark"
		exec 'highlight SpecialKey gui=NONE cterm=NONE guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg=NONE ctermbg=NONE'
	elseif &background == "light"
		exec 'highlight SpecialKey gui=NONE cterm=NONE guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg=NONE ctermbg=NONE'
	endif
endfunction
augroup whitespace
	autocmd!
	autocmd ColorScheme solarized call SetWhiteSpaceColor()
	" Highlight trailing white space
	exec 'autocmd ColorScheme solarized highlight ExtraWhitespace gui=NONE cterm=NONE guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg=NONE ctermbg=NONE'
	autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
	autocmd InsertLeave * match ExtraWhitespace /\s\+$/
augroup END

" Solarized bug fixes {{{4
function! SetMarginColors()
	if &background == "dark"
		exec 'highlight CursorLineNr gui=NONE cterm=NONE guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		exec 'highlight SignColumn gui=NONE cterm=NONE guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		" Better Syntastic styles
		exec 'highlight SyntasticWarningSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.violet.' ctermfg='.g:sol.cterm.violet.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		exec 'highlight SyntasticErrorSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		" Better git-gutter styles
		exec 'highlight lineAdded gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.green.' ctermfg='.g:sol.cterm.green.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		exec 'highlight lineModified gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
		exec 'highlight lineRemoved gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
	elseif &background == "light"
		exec 'highlight CursorLineNr gui=NONE cterm=NONE guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
		exec 'highlight SignColumn gui=NONE cterm=NONE guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
		" Better Syntastic styles
		exec 'highlight SyntasticWarningSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.violet.' ctermfg='.g:sol.cterm.violet.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
		exec 'highlight SyntasticErrorSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base1.' ctermbg='.g:sol.cterm.base2
		" Better git-gutter styles
		exec 'highlight lineAdded gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.green.' ctermfg='.g:sol.cterm.green.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
		exec 'highlight lineModified gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base1.' ctermbg='.g:sol.cterm.base2
		exec 'highlight lineRemoved gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
	endif
endfunction
augroup margincolor
	autocmd!
	autocmd ColorScheme solarized call SetMarginColors()
augroup END

" Remember background style {{{4
if !exists('g:background_style')
	let g:background_style = "dark"
endif
let &background = g:background_style
augroup backgroundswitch
	autocmd!
	autocmd ColorScheme solarized let g:background_style = &background
augroup END


" Devicons {{{4
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1
if exists("g:loaded_webdevicons")
	call webdevicons#refresh()
endif
augroup devicons
	autocmd!
	autocmd FileType nerdtree setlocal nolist
augroup END
" Devicons Icon colors {{{5
function! DeviconsColors(config)
	let colors = keys(a:config)
	for color in colors
		if color == 'normal'
			if &background == 'dark'
				let normalcolor = 'base01'
			elseif &background == 'light'
				let normalcolor = 'base1'
			endif
			exec 'augroup devicons_'.color
			exec 'autocmd!'
			exec 'autocmd FileType nerdtree,startify highlight devicons_'.color.' guifg='.g:sol.gui[normalcolor].' ctermfg='.g:sol.cterm[normalcolor]
			exec 'autocmd FileType nerdtree,startify syn match devicons_'.color.' /\v'.join(a:config[color], '|').'/ containedin=ALL'
			exec 'augroup END'
			" When the background changes, we need to change these colors
			if !exists('g:devicons_colored')
				exec 'autocmd ColorScheme solarized call DeviconsColors({''normal'': ['''.join(a:config[color], ''',''').''']})'
			endif
		elseif color == 'emphasize'
			if &background == 'dark'
				let emcolor = 'base1'
			elseif &background == 'light'
				let emcolor = 'base01'
			endif
			exec 'augroup devicons_'.color
			exec 'autocmd!'
			exec 'autocmd FileType nerdtree,startify highlight devicons_'.color.' guifg='.g:sol.gui[emcolor].' ctermfg='.g:sol.cterm[emcolor]
			exec 'autocmd FileType nerdtree,startify syn match devicons_'.color.' /\v'.join(a:config[color], '|').'/ containedin=ALL'
			exec 'augroup END'
			" When the background changes, we need to change these colors
			if !exists('g:devicons_colored')
				exec 'autocmd ColorScheme solarized call DeviconsColors({''emphasize'': ['''.join(a:config[color], ''',''').''']})'
			endif
		else
			exec 'augroup devicons_'.color
			exec 'autocmd!'
			exec 'autocmd FileType nerdtree,startify highlight devicons_'.color.' guifg='.g:sol.gui[color].' ctermfg='.g:sol.cterm[color]
			exec 'autocmd FileType nerdtree,startify syn match devicons_'.color.' /\v'.join(a:config[color], '|').'/ containedin=ALL'
			exec 'augroup END'
		endif
	endfor
	let g:devicons_colored = 1
endfunction
if !exists('g:devicons_colored')
	call DeviconsColors({
		\'normal': ['', '', '', '', ''],
		\'emphasize': ['', '', '', '', '', '', '', '', '', '', ''],
		\'yellow': ['', '', ''],
		\'orange': ['', '', '', 'λ', '', ''],
		\'red': ['', '', '', '', '', '', '', '', ''],
		\'magenta': [''],
		\'violet': ['', '', '', ''],
		\'blue': ['', '', '', '', '', '', '', '', '', '', '', '', ''],
		\'cyan': ['', '', '', ''],
		\'green': ['', '', '', '']
	\})
endif

" Filetype {{{3

" Text-like lazy-loading {{{4
let s:textlikeft_plugins_loaded = 0
augroup textlike
	autocmd!
	" Init for all file types
	autocmd FileType *
		\   call litecorrect#init()
	" Init for text-like file types
	autocmd FileType * if index(textlikeft, &filetype) >= 0 |
		\   if !s:textlikeft_plugins_loaded
			\ | let s:textlikeft_plugins_loaded = 1
			\ | call plug#load('vim-pencil')
			\ | call plug#load('goyo.vim')
			\ | call plug#load('limelight.vim')
			\ | call plug#load('vim-textobj-sentence')
		\ | endif
		\ | call pencil#init()
		\ | call textobj#quote#init()
		\ | call textobj#sentence()
		\ | silent let g:textobj#quote#educate = 1 " For smart quotes toggling
	\ | endif
	" Init for non-text-like file types
	autocmd FileType * if index(textlikeft, &filetype) < 0 |
		\   call textobj#quote#init({'educate': 0})
		\ | silent let g:textobj#quote#educate = 1 " For smart quotes in comments & for toggling
		\ | endif
augroup END

" Smart quotes toggle {{{4
function! s:ToggleEducate()
	if g:textobj#quote#educate
		silent NoEducate
		silent let g:textobj#quote#educate = 0 " For smart quotes in comments
		echom "Smart quotes off"
	else
		silent Educate
		silent let g:textobj#quote#educate = 1 " For smart quotes in comments
		echom "Smart quotes on"
	endif
endfunction
nnoremap <Leader>' :call <SID>ToggleEducate()<Cr>

" Smart quotes in comments {{{4
function! s:SmartQuotesInComments()
	" Respect the setting above, only do smart quotes in comments
	" If the educate variable is truthy
	if g:textobj#quote#educate
		if synIDattr(synID(line('.'),col('.')-1,1),'name') =~? 'comment'
			exec 'silent Educate'
		else
			exec 'silent NoEducate'
		endif
	endif
endfunction
augroup smartquotes
	autocmd!
	autocmd InsertCharPre * if index(textlikeft, &filetype) < 0 |
		\   call <SID>SmartQuotesInComments()
	\ | endif
	autocmd InsertLeave * if index(textlikeft, &filetype) < 0 |
		\   exec 'silent NoEducate'
	\ | endif
augroup END

" Limelight & Goyo {{{4
let g:limelight_conceal_ctermfg = 10
let g:limelight_conceal_guifg = '#586e75'
function! s:goyo_enter()
	silent !tmux set status off
	set noshowcmd
	set scrolloff=999
	Limelight
	GitGutterDisable
	SyntasticToggleMode
endfunction
function! s:goyo_leave()
	silent !tmux set status on
	set showcmd
	set scrolloff=1
	Limelight!
	GitGutterEnable
	SyntasticToggleMode
endfunction
augroup goyo_limelight
	autocmd!
	autocmd User GoyoEnter nested call <SID>goyo_enter()
	autocmd User GoyoLeave nested call <SID>goyo_leave()
augroup END
nnoremap <Leader>g :Goyo<CR>

" }}}2

call plug#end()

" Set colorscheme
colorscheme solarized

" Mappings {{{1

" Open empty buffer
nnoremap <Leader>T :enew<Cr>
" Move to next buffer
nnoremap <Leader>l :bnext<Cr>
" Move to previous buffer
nnoremap <Leader>h :bprevious<Cr>
" Close buffer and show previous
nnoremap <Leader>bq :bprevious <Bar> :bdelete #<Cr>
" Show open buffers
nnoremap <Leader>bl :buffers<Cr>

" recall newer command-line using current characters as search pattern
cnoremap <C-N> <Down>
" recall previous (older) command-line using current characters as search pattern
cnoremap <C-P> <Up>

" Let brace movement work even when braces aren't at col 0
map [[ ?{<CR>w99[{
map ][ /}<CR>b99]}
map ]] j0[[%/{<CR>
map [] k$][%?}<CR>

" Don't use Ex mode, use Q for formatting
map Q gq

" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>
nnoremap <Leader><Space> :nohlsearch<Cr>

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
	command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		\ | wincmd p | diffthis
endif

" edit and source the vimrc file quickly
nnoremap <Leader>ev :vsplit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC<cr>
" edit the zshrc file quickly
nnoremap <Leader>ez :vsplit ~/.zshrc<cr>

" change ESC to jk
inoremap jk <esc>

" easy semicolon at end of line in insert mode
inoremap <Leader>; <C-o>m`<C-o>A;<C-o>``
" easy comma at end of line in insert mode
inoremap <Leader>, <C-o>m`<C-o>A,<C-o>``

" save a vim session
nnoremap <Leader>s :mksession<Cr>

" Easier system clipboard usage
vnoremap <Leader>y "+y
vnoremap <Leader>d "+d
nnoremap <Leader>p "+p
nnoremap <Leader>P "+P
vnoremap <Leader>p "+p
vnoremap <Leader>P "+P

" Automatically go to end of paste
vnoremap <silent> p p`]
nnoremap <silent> p p`]
" vnoremap <silent> y y`] |" same for selection

" unmap keys I shouldn't be using
inoremap <esc> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>

" }}}1

" vim: set foldmethod=marker foldlevel=0:
