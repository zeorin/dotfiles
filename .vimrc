"                     _       _             _
"  _______  ___  _ __(_)_ __ ( )___  __   _(_)_ __ ___  _ __ ___
" |_  / _ \/ _ \| '__| | '_ \|// __| \ \ / / | '_ ` _ \| '__/ __|
"  / /  __/ (_) | |  | | | | | \__ \  \ V /| | | | | | | | | (__
" /___\___|\___/|_|  |_|_| |_| |___/ (_)_/ |_|_| |_| |_|_|  \___|
"

" This is the personal .vimrc of Xandor Schiefer.

" Goals are:
" * ease of use, mostly extending Vim whilst not changing built-in
"   functionality (except in a few cases, e.g. clipboard registers);
" * extend vanilla Vim to include more IDE-like features, like auto-
"   completion, git integration, linting, snippets, etc., that one might
"   expect from a modern editor;
" * some writing-focused tweaks & plugins. Text editors aren’t just for code;
" * tmux integration: because tmux is awesome;
" * performance: adding lots of plugins and functionality can make Vim slow—
"   this is not Emacs—utilize lazy-loading to keep it snappy;
" * Linux, Mac, Windows, and NeoVim compatibility; one .vimrc to rule
"   them all;
" * support for local modification with .vimrc.before and .vimrc.after;
" * making it look attractive—default Vim is ugly.

" This file is licensed under the MIT License. The various plugins are
" licensed under their own licenses. Please see their documentation for more
" information.

" The MIT License (MIT) {{{

" Copyright ⓒ 2016 Xandor Schiefer

" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to
" deal in the Software without restriction, including without limitation the
" rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
" sell copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:

" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.

" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
" FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
" IN THE SOFTWARE.

" }}}

" Very basic defaults (in line with NeoVim defaults) {{{
	if !has('nvim')
		set nocompatible " Don’t try to be just Vi
		filetype indent plugin on " Turn on file type detection
		set autoindent " Keep current indent if no other indent rule
		set autoread " Reload file if it’s changed on the file system
		set backspace=indent,eol,start " Allow backspacing over everything
		set complete=.,w,b,u,t " Scan all buffers and include tags
		set display=lastline " Display as much as possible of a line
		set encoding=utf-8 " UTF-8 encoding
		set formatoptions=tcqj " Auto-wrap text, better comment formatting
		set history=10000 " Maximum command and search history
		set hlsearch " Highlight search results
		set incsearch " Jump to results as you type
		set langnoremap " 'langmap' doesn’t mess with mappings
		set laststatus=2 " Status line is always shown
		set listchars=tab:>\ ,trail:-,nbsp:+ " Default white space characters
		set nrformats=hex " Recognize hexadecimal numbers
		" For sessions, save & restore the following:
		set sessionoptions=blank,buffers,curdir,folds,help,tabpages,winsize
		set smarttab " Respect shiftwidth setting
		set tabpagemax=50 " Maximum number of tabs to be opened
		set tags=./tags;,tags " Default locations for tags files
		set ttyfast " Assume a modern terminal, fast ‘connection’
		set viminfo+=! " Keep all-caps global variables
		set wildmenu " List possible completions on status line
	endif
	syntax on " Turn on syntax highlighting
" }}}

" Platform detection {{{
	silent function! OSX()
		return has('macunix')
	endfunction
	silent function! LINUX()
		return has('unix') && !has('macunix') && !has('win32unix')
	endfunction
	silent function! WINDOWS()
		return  (has('win32') || has('win64'))
	endfunction
" }}}

" Some useful variables {{{
	if OSX() || LINUX()
		if has('nvim')
			let vimDir = '$HOME/.config/nvim/'
			let vimRc = '$HOME/.config/nvim/init.vim'
		else
			let vimDir = '$HOME/.vim/'
			let vimRc = '$HOME/.vimrc'
		endif
	elseif WINDOWS()
		let vimDir = '$HOME/vimfiles/'
		let vimRc = '$HOME/_vimrc'
	endif
" }}}

" Load local ‘before’ settings {{{

	if filereadable(expand(vimRc . '.before'))
		source expand(vimRc . '.before')
	endif

" }}}

" Start plugin manager {{{

	" TODO: make this platform-independent

	" Install vim-plug if necessary
	if empty(glob('~/.vim/autoload/plug.vim'))
		silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
			\ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
		autocmd! VimEnter * PlugInstall | source $MYVIMRC
	endif

	call plug#begin('~/.vim/plugged')

" }}}

" Appearance {{{

	" use visual terminal bell
	set vb

	" line numbers
	set relativenumber
	set number

	" Don't break words when wrapping lines
	set linebreak

	" make wrapped lines more obvious
	let &showbreak="↳ "
	set cpoptions+=n

	" Make tabs, non-breaking spaces and trailing white space visible
	set list
	" Use a Box Drawings Light Quadruple Dash Vertical (0x250A) + Space to
	" show a Tab, a Middle Dot (0x00B7) for trailing spaces, and the negation
	" symbol (0x00AC) for non-breaking spaces
	set listchars=tab:│\ ,trail:·,extends:→,precedes:←,nbsp:¬

	" Highlight the line I'm on
	set cursorline

	" Set cursor depending on mode
	if !has('gui')
		if has('nvim')
			set guicursor=n-v-c:block-Cursor/lCursor-blinkon0,i-ci:ver25-Cursor/lCursor,r-cr:hor20-Cursor/lCursor
		else
			let &t_SI = "\<Esc>[5 q"	" DECSCUSR Blink Bar
			let &t_EI = "\<Esc>[2 q"	" DECSCUSR Steady Block
		endif
	endif

	" Show the textwidth visually
	set colorcolumn=+1,+2

	" Highlight matching paired delimiter
	set showmatch

	" display incomplete commands
	set showcmd

	" Set comments to be italic
	highlight Comment gui=italic cterm=italic
	autocmd! ColorScheme * highlight Comment gui=italic cterm=italic

	" Git diff in the gutter (sign column) and stage/undo hunks
	Plug 'airblade/vim-gitgutter'
	let g:gitgutter_map_keys = 0

	" Concealing
	set conceallevel=1
	set concealcursor=

	" Solarized color scheme {{{
		" Precision colors for machines and people
		Plug 'altercation/vim-colors-solarized'
		" Create a dictionary of the colors for later use
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
		" Solarized bug fixes
		function! FixSolarized()
			exec 'highlight SpecialKey gui=NONE cterm=NONE guifg='.g:sol.gui.blue.' ctermfg='.g:sol.cterm.blue
			if &background ==# 'dark'
				exec 'highlight CursorLineNr gui=NONE cterm=NONE guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				exec 'highlight SignColumn gui=NONE cterm=NONE guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				" Better ALE styles
				exec 'highlight ALEWarningSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				exec 'highlight ALEErrorSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				" Better git-gutter styles
				exec 'highlight lineAdded gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.green.' ctermfg='.g:sol.cterm.green.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				exec 'highlight lineModified gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				exec 'highlight lineRemoved gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				" Better fold styling
				exec 'highlight Folded gui=NONE,underline cterm=NONE,underline guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
				exec 'highlight FoldColumn gui=NONE cterm=NONE guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg='.g:sol.gui.base02.' ctermbg='.g:sol.cterm.base02
			elseif &background ==# 'light'
				exec 'highlight CursorLineNr gui=NONE cterm=NONE guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				exec 'highlight SignColumn gui=NONE cterm=NONE guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				" Better Syntastic styles
				exec 'highlight ALEWarningSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				exec 'highlight ALEErrorSign gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base1.' ctermbg='.g:sol.cterm.base2
				" Better git-gutter styles
				exec 'highlight lineAdded gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.green.' ctermfg='.g:sol.cterm.green.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				exec 'highlight lineModified gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow.' guibg='.g:sol.gui.base1.' ctermbg='.g:sol.cterm.base2
				exec 'highlight lineRemoved gui=NONE,bold cterm=NONE,bold guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				" Better fold styling
				exec 'highlight Folded gui=NONE,underline cterm=NONE,underline guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
				exec 'highlight FoldColumn gui=NONE cterm=NONE guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg='.g:sol.gui.base2.' ctermbg='.g:sol.cterm.base2
			endif
		endfunction
		autocmd! ColorScheme solarized call FixSolarized()
	" }}}

	" Remember background style {{{
		if !exists('g:background_style')
			let g:background_style = "dark"
		endif
		let &background = g:background_style
		autocmd! ColorScheme * let g:background_style = &background
	" }}}

	" Powerline-style status- and tab/buffer-line {{{
		set showtabline=2 " Always display the tabline, even if there is only one tab
		set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)
		Plug 'vim-airline/vim-airline'
		Plug 'vim-airline/vim-airline-themes' " Collection of airline themes
		let g:airline_powerline_fonts = 1 " Use powerline glyphs
		let g:airline#extensions#tabline#enabled = 1 " Use tabline
		let g:airline#extensions#tabline#show_tabs = 1 " Always show tabline
		let g:airline#extensions#tabline#show_buffers = 1 " Show buffers when no tabs
		let g:airline#extensions#whitespace#mixed_indent_algo = 2 " Allow spaces after tabs for alignment
		let g:airline#extensions#c_like_langs = ['c', 'cpp', 'cuda', 'go', 'javascript', 'javascript.jsx', 'ld', 'php']
	" }}}

	" Fancy start screen {{{
		Plug 'mhinz/vim-startify'
		let g:startify_list_order = [
			\ ['   Bookmarks'],      'bookmarks',
			\ ['   Sessions'],       'sessions',
			\ ['   MRU '. getcwd()], 'dir',
			\ ['   MRU'],            'files',
			\ ['   Commands'],       'commands',
			\ ]
		" Better header colour
		if &background ==# 'dark'
			exec 'highlight StartifyHeader guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1
		elseif &background ==# 'light'
			exec 'highlight StartifyHeader guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01
		endif
		" Better section colour
		exec 'highlight StartifySection guifg='.g:sol.gui.blue.' ctermfg='.g:sol.cterm.blue
		" Better file colour
		if &background ==# 'dark'
			exec 'highlight StartifyFile guifg='.g:sol.gui.base0.' ctermfg='.g:sol.cterm.base0
		elseif &background ==# 'light'
			exec 'highlight StartifyFile guifg='.g:sol.gui.base00.' ctermfg='.g:sol.cterm.base00
		endif
		" Better special colour
		exec 'highlight StartifySpecial gui=italic cterm=italic guifg='.g:sol.gui.yellow.' ctermfg='.g:sol.cterm.yellow
		" Hide those ugly brackets
		if &background ==# 'dark'
			exec 'highlight StartifyBracket guifg='.g:sol.gui.base03.' ctermfg='.g:sol.cterm.base03
		elseif &background ==# 'light'
			exec 'highlight StartifyBracket guifg='.g:sol.gui.base3.' ctermfg='.g:sol.cterm.base3
		endif
		" Open NERDTree at the same time
		autocmd! VimEnter *
			\   if !argc()
			\ |   Startify
			\ |   NERDTree
			\ |   wincmd w
			\ | endif
	" }}}

	" Set white space colours {{{
		augroup whitespace
			autocmd!
			exec 'autocmd ColorScheme solarized if &background ==# ''dark'' | '.
				\ 'highlight Whitespace gui=NONE cterm=NONE guifg='.g:sol.gui.base02.' ctermfg='.g:sol.cterm.base02.' guibg=NONE ctermbg=NONE | '.
				\ 'highlight NonText gui=NONE cterm=NONE guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' guibg=NONE ctermbg=NONE | '.
				\ 'else | '.
				\ 'highlight Whitespace gui=NONE cterm=NONE guifg='.g:sol.gui.base2.' ctermfg='.g:sol.cterm.base2.' guibg=NONE ctermbg=NONE | '.
				\ 'highlight NonText gui=NONE cterm=NONE guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' guibg=NONE ctermbg=NONE | '.
				\ 'endif'
			" Highlight trailing white space
			exec 'autocmd ColorScheme solarized highlight ExtraWhitespace gui=NONE cterm=NONE guifg='.g:sol.gui.red.' ctermfg='.g:sol.cterm.red.' guibg=NONE ctermbg=NONE'
			autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
			autocmd InsertLeave * match ExtraWhitespace /\s\+$/
		augroup END
	" }}}

	" Use undercurl for spelling error highlight {{{
		let &t_Cs = "\e[4:3m"
		let &t_Ce = "\e[4:0m"
		hi SpellBad gui=undercurl guisp=g:sol.cterm.red term=undercurl cterm=undercurl
	" }}}

	" Show hex, rgb, and hsl colors
	Plug 'ap/vim-css-color'

" }}}

" General Mappings {{{

	" Set the leader needs to be done early, because any mappings that use
	" <Leader> will use the value of <Leader> that was defined when they’re
	" defined.
	let mapleader="\<Space>"
	let maplocalleader="-"

	Plug 'tpope/vim-repeat' " Plugin mappings can be repeated with .

	" Copy current file path to clipboard
	nnoremap <Leader>f :let @+ = expand("%")<cr>

	" Make it easier to work with buffers
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

	" Emacs-style keybindings when in insert or command mode
	Plug 'tpope/vim-rsi' " Readline style insertion
	" recall newer command-line using current characters as search pattern
	cnoremap <C-N> <Down>
	" recall previous (older) command-line using current characters as search pattern
	cnoremap <C-P> <Up>

	" Let brace movement work even when braces aren’t at col 0
	map [[ ?{<CR>w99[{
	map ][ /}<CR>b99]}
	map ]] j0[[%/{<CR>
	map [] k$][%?}<CR>

	" Don't use Ex mode, use Q for formatting
	map Q gq

	" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
	" so that you can undo CTRL-U after inserting a line break.
	inoremap <C-U> <C-G>u<C-U>

	" Quickly clear search highlight
	nnoremap <Leader><Space> :nohlsearch<Cr>

	" Convenient command to see the difference between the current buffer and the
	" file it was loaded from, thus the changes you made.
	if !exists(":DiffOrig")
		command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
			\ | wincmd p | diffthis
	endif

	" edit and source the vimrc file quickly
	nnoremap <Leader>ev :edit $MYVIMRC<cr>
	nnoremap <Leader>sv :source $MYVIMRC<cr>

	" edit the zshrc file quickly
	nnoremap <Leader>ez :vsplit ~/.zshrc<cr>

	" change ESC to jk
	inoremap jk <esc>

	" easy semicolon at end of line in insert mode
	inoremap <Leader>; <C-o>m`<C-o>A;<C-o>``
	" easy comma at end of line in insert mode
	inoremap <Leader>, <C-o>m`<C-o>A,<C-o>``

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

	" Easier split windows
	nnoremap <Leader>- :split<cr>
	nnoremap <Leader>\| :vsplit<cr>

	" Toggle conceallevel
	map <Leader>c :exec &conceallevel ? "set conceallevel=0" : "set conceallevel=1"<cr>

	" Write with root permissions
	cmap w!! w !sudo tee > /dev/null %

" }}}

" General functionality {{{

	" Restore FocusGained and FocusLost events
	Plug 'tmux-plugins/vim-tmux-focus-events'

	" Match paired characters
	Plug 'vim-scripts/matchit.zip' " Updated matchit
	Plug 'tpope/vim-unimpaired' " Pairs of handy bracket mappings

	" Sensible default settings we can all agree on See
	" vim-sensible/plugin/sensible.vim for the actual settings. Although the
	" plugin is defined here, it’s only loaded near the end of the script.
	Plug 'tpope/vim-sensible'

	" Enable mouse
	set mouse=a

	" Set ttymouse correctly when in Vim in Tmux, so that mouse events are
	" correctly handled.
	if !has('nvim') && $TERM =~# 'tmux.*'
		set ttymouse=xterm
	endif

	" set tabs to display as 4 spaces wide (might be overwritten by
	" .editorconfig files)
	set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
	set shiftround
	Plug 'tpope/vim-sleuth' " Heuristically set buffer options, like tabs/spaces
	Plug 'editorconfig/editorconfig-vim' " EditorConfig support
	" TODO: Figure out how to set buffer settings with both
	" vim-sleuth and editorconfig settings enabled. Editorconfig
	" settings should trump vim-sleuth settings for any given buffer.

	" When wrap is off, horizontally scroll a decent amount.
	set sidescroll=16

	" check final line for Vim settings
	set modelines=1

	" ignore case sensitivity in searching
	set ignorecase

	" smart case sensitivity in searching
	set smartcase

	" better command line completion
	set wildmode=longest,full
	set fileignorecase
	set wildignorecase

	" Ingore backup files & git directories
	set wildignore+=*~,.git

	" Enable code folding
	set foldenable
	set foldlevelstart=10
	set foldnestmax=10
	set foldmethod=indent
	set foldcolumn=2
	Plug 'Konfekt/FastFold' " Make folding faster

	" Switch buffers even if modified
	set hidden

	" better split window locations
	set splitright
	set splitbelow

	" Stop backup files from littering all over the system
	let myBackupDir = expand(vimDir . 'tmp/backup/')
	call system('mkdir -p ' . myBackupDir)
	let &backupdir = myBackupDir . ',' . &backupdir
	" Keep backup files
	set backup
	" Do it in a way that is compatible with file-watchers
	set backupcopy=yes

	" Stop swap files from littering all over the system
	let mySwapDir = expand(vimDir . 'tmp/swap//')
	call system('mkdir -p ' . mySwapDir)
	let &directory = mySwapDir . ',' . &directory

	" Spell check & word completion
	set spell spelllang=en_gb
	set complete+=kspell

	" Open file at last cursor position {{{
		augroup cursorpos
			autocmd!
			" When editing a file, always jump to the last known cursor position.
			" Don't do it when the position is invalid or when inside an event
			" handler (happens when dropping a file on gvim). Also don't do it
			" when the mark is in the first line, that is the default position
			" when opening a file.
			autocmd BufReadPost *
				\ if line("'\"") > 1 && line("'\"") <= line("$") |
				\   exe "normal! g`\"" |
				\ endif
		augroup END
	" }}}

	" Persistent undo {{{
		if has('persistent_undo')
			let myUndoDir = expand(vimDir . 'tmp/undo//')
			" Create dirs
			call system('mkdir -p ' . myUndoDir)
			let &undodir = myUndoDir
			set undofile
		endif
	" }}}

	" Faster update for Git Gutter
	set updatetime=750

	" Set window title {{{
		autocmd! BufEnter * let &titlestring = system('"$HOME"/.dotfiles/scripts/short_path "' . expand('%:p:.').'"')[:-2]
		if $TERM =~# '\(screen\|tmux\).*'
			set t_ts=k
			set t_fs=\
		endif
		if has('nvim') && ($TERM =~# '\(screen\|tmux\).*' || $TERM =~# '.*xterm.*')
			set title
		endif
	" }}}

	" Tabulate columns
	Plug 'godlygeek/tabular'

	" Better movement targets
	Plug 'wellle/targets.vim'

	" Make it easy to comment
	Plug 'tpope/vim-commentary' " Comment stuff out

	" Use CTRL-A/CTRL-X to increment dates, times, and more
	Plug 'tpope/vim-speeddating'

	" Send buffer contents to other tmux panes {{{
		if exists('$TMUX')
			Plug 'jpalardy/vim-slime'
			let g:slime_target = 'tmux'
			let g:slime_default_config = {'socket_name': split($TMUX, ',')[0], 'target_pane': ':.2'}
			let g:slime_dont_ask_default = 1
			let g:slime_paste_file = tempname()
			autocmd! VimLeave * call system('rm ' . mySlimeFile)
		endif
	" }}}

	" Display tags, ordered by scope
	Plug 'majutsushi/tagbar'
	nnoremap <F9> :TagbarToggle<CR>

	" Quoting/parenthesizing made simple
	Plug 'tpope/vim-surround'

	" Easily search for, substitute, and abbreviate multiple variants of a
	" word
	Plug 'tpope/vim-abolish'

	" Better indentation when pasting
	Plug 'sickill/vim-pasta'
	let g:pasta_disabled_filetypes = ['pug', 'yaml', 'ctrlp']

	" Visualize Vim's undo tree
	Plug 'sjl/gundo.vim'
	nnoremap <Leader>u :GundoToggle<CR>

	" Don’t include quickfix list in buffer list
	autocmd! FileType qf set nobuflisted


	" Linting {{{
		Plug 'w0rp/ale'
		let g:ale_command_wrapper = 'env NODE_ENV=development'
		let g:airline#extensions#ale#enabled = 1
		" let g:ale_sign_warning = "⚠️"
		let g:ale_sign_warning = "💡"
		let g:ale_sign_error = "🚨"
		let g:ale_echo_msg_error_str = "🚨"
		" let g:ale_echo_msg_warning_str = "⚠️"
		let g:ale_echo_msg_warning_str = "💡"
		let g:ale_echo_msg_format = '%severity%  %s [%linter%] %code%'
		let g:ale_fix_on_save = 1
		let g:ale_fixers = {}
		let g:ale_fixers['javascript'] = ['eslint', 'prettier']
		let g:ale_fixers['scss'] = ['prettier']
		let g:ale_fixers['css'] = ['prettier']
		let g:ale_fixers['json'] = ['prettier']
		let g:ale_javascript_eslint_suppress_eslintignore = 1
		let g:ale_linters_ignore = {
			\'javascript': ['flow', 'tsserver'],
		\}
	" }}}

	" File tree explorer {{{
		Plug 'scrooloose/nerdtree'
		let g:NERDTreeShowHidden = 1
		let g:NERDTreeMinimalUI = 1
		nnoremap <F8> :NERDTreeToggle<CR>
		Plug 'janlay/NERD-tree-project' " Try to find project dir
		Plug 'Xuyuanp/nerdtree-git-plugin' " NERDTree showing git status
		let g:NTPNames = ['.git*', 'package.json', 'Gemfile', 'Gulpfile.js', 'Gruntfile.js']
		let g:NTPNamesDirs = ['.git']
	" }}}

	" Working directory is always project root {{{
		Plug 'airblade/vim-rooter'
		let g:rooter_patterns = ['.git', '.git/', 'package.json', 'Gemfile', 'Gulpfile.js', 'Gruntfile.js', 'config.rb']
		let g:rooter_silent_chdir = 1
	" }}}

	" Better clipboard functionality {{{
		Plug 'svermeulen/vim-easyclip'
		" Easyclip remaps the mark mapping, remap mark to gm
		nnoremap gm m
		let g:EasyClipUseSubstituteDefaults = 1 " s is the substitution mapping
	" }}}

	" Learn Vim’s movement commands better {{{
		Plug 'wikitopian/hardmode' " Hard mode
		Plug 'kbarrette/mediummode' " Less… hard
		let g:mediummode_enabled = 0
		nnoremap <Leader>mm :MediumModeToggle<CR>
	" }}}

	" Fuzzy file, buffer, mru, tag, etc finder {{{
		Plug 'ctrlpvim/ctrlp.vim'
		let g:ctrlp_match_window = 'bottom,order:ttb'
		let g:ctrlp_switch_buffer = 0
		let g:ctrlp_working_path_mode = 0
		let g:ctrlp_use_caching = 0
		let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
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
	" }}}

	" Search code using Ag or Ack {{{
		Plug 'mileszs/ack.vim'
		if executable('ag')
			let g:ackprg = "ag --nogroup --nocolor --column --hidden"
			nnoremap <Leader>a :Ack! |
		elseif executable('ack') || executable ('ack-grep')
			nnoremap <Leader>a :Ack! |
		else
			nnoremap <Leader>a :grep |
		endif
	" }}}

	" Automated tag file generation and syntax highlighting of tags {{{

		" Where to look for tags files
		set tags=.git/tags,tags,./tags

		Plug 'xolox/vim-misc' " Needed for Easytags
		Plug 'Wraul/vim-easytags', { 'commit': 'f5746bdfd9942b00c349e53f3f4917ae73bb6797' }
		let g:easytags_languages = {
			\'javascript': {
				\'cmd': 'jsctags',
				\'args': [],
				\'fileoutput_opt': '-f',
				\'stdout_opt': '-f-',
				\'recurse_flag': '-R'
			\}
		\}
		let g:easytags_auto_highlight = 0
		set cpoptions+=d
		let g:easytags_dynamic_files = 2
		let g:easytags_async = 1
	" }}}

	" A Git wrapper so awesome, it should be illegal
	Plug 'tpope/vim-fugitive'

	" Insert mode auto-completion for quotes, parens, brackets, etc. {{{
		Plug 'Raimondi/delimitMate'
		let delimitMate_expand_space = 1
		let delimitMate_expand_cr = 2
		let delimitMate_balance_matchpairs = 1
		let delimitMate_nesting_quotes = ['`']
	" }}}

	" Wisely add 'end' in ruby, endfunction/endif/more in vim script, etc
	Plug 'tpope/vim-endwise'

	" A code-completion engine for Vim {{{
		Plug 'Valloric/YouCompleteMe'
		let g:ycm_key_list_select_completion = ['<C-n>']
		let g:ycm_key_list_previous_completion = ['<C-p>']
		let g:ycm_collect_identifiers_from_tags_files = 1
		let g:ycm_add_preview_to_completeopt = 1
		let g:ycm_autoclose_preview_window_after_completion = 1
		let g:ycm_autoclose_preview_window_after_insertion = 1
		let g:ycm_cache_omnifunc = 0
		imap <silent> <BS> <C-R>=YcmOnDeleteChar()<CR><Plug>delimitMateBS

		function! YcmOnDeleteChar()
			if pumvisible()
				return "\<C-y>"
			endif
			return ""
		endfunction
	" }}}

	" The ultimate snippet solution for Vim {{{
		Plug 'sirver/ultisnips'
		Plug 'honza/vim-snippets' " Community-maintained default snippets
		let g:UltiSnipsExpandTrigger="<Tab>"
		let g:UltiSnipsListSnippets="<C-a>"
		let g:UltiSnipsJumpForwardTrigger="<Tab>"
		let g:UltiSnipsJumpBackwardTrigger="<S-Tab>"
		let g:UltiSnipsEditSplit="vertical"
	" }}}

	" Emmet support
	Plug 'mattn/emmet-vim'

	" Seamless navigation between tmux panes and vim splits
	Plug 'christoomey/vim-tmux-navigator'
	let g:tmux_navigator_disable_when_zoomed = 1

	" Extended upport for .tmux.conf
	Plug 'tmux-plugins/vim-tmux'

	" A solid language pack (HTML5, CSS3, SASS, PHP, & about 74 others) {{{
		Plug 'sheerun/vim-polyglot'

		" JavaScript {{{
			let g:jsx_ext_required = 0
			let g:javascript_plugin_jsdoc = 1
			let g:javascript_plugin_flow = 1
			let g:javascript_conceal_function             = "ƒ"
			let g:javascript_conceal_null                 = "ø"
			let g:javascript_conceal_this                 = "@"
			let g:javascript_conceal_return               = "⇚"
			let g:javascript_conceal_undefined            = "¿"
			let g:javascript_conceal_NaN                  = "ℕ"
			let g:javascript_conceal_prototype            = "¶"
			let g:javascript_conceal_static               = "•"
			let g:javascript_conceal_super                = "Ω"
			" let g:javascript_conceal_arrow_function       = "⇒"
			let g:javascript_conceal_noarg_arrow_function = "🞅"
			let g:javascript_conceal_underscore_arrow_function = "🞅"
		" }}}

	" }}}

	" ledger
	Plug 'ledger/vim-ledger'
	let g:ledger_bin = 'hledger'
	let g:ledger_maxwidth = 80
	let g:ledger_fillstring = '    -'
	let g:ledger_detailed_first = 1
	autocmd! BufNewFile,BufRead *.hledger,*.journal set filetype=ledger

	" Set filetypes for odd files {{{
		augroup filetypes
			autocmd!
			autocmd BufNewFile,BufRead .babelrc set filetype=json
			autocmd BufNewFile,BufRead .czrc set filetype=json
			autocmd BufNewFile,BufRead .lintstagedrc set filetype=json
		augroup END
	" }}}

	" Improved PHP omnicompletion
	Plug 'shawncplus/phpcomplete.vim', { 'for': 'php' }

	" Updated official PHP indent
	Plug '2072/php-indenting-for-vim', { 'for': 'php' }

	" Browse documentation {{{
		nnoremap gK :!zeal "<cword>"&<CR><CR>
	" }}}

	" Define text-like file types
	let markdownft = ['markdown', 'mkd', 'md']
	let vcsft = ['git', 'gitsendemail', '*commit*', '*COMMIT*']
	let textlikeft = markdownft + vcsft + ['text', 'mail']

	" Text & text-like filetype plugins {{{

		" Todo.txt
		Plug 'freitass/todo.txt-vim'

		" Distraction-free writing
		Plug 'junegunn/goyo.vim', { 'on': [] }

		" Hyper-focus writing
		Plug 'junegunn/limelight.vim', { 'on': [] }

		" Build on Vim’s spell/thes/dict completion
		" Plug 'reedes/vim-lexical', { 'for': textlikeft }

		" Light-weight auto-correction
		Plug 'reedes/vim-litecorrect'

		" Create your own text objects
		Plug 'kana/vim-textobj-user'

		" Use ‘curly’ quote characters
		Plug 'reedes/vim-textobj-quote'

		" Improved native sentence text object and motion
		Plug 'reedes/vim-textobj-sentence', { 'on': [] }

		" Uncover usage problems in your writing
		Plug 'reedes/vim-wordy', { 'for': textlikeft }

		" For all text files set 'textwidth' to 78 characters.
		autocmd! FileType text,markdownft set textwidth=78

		" Text-like plugins lazy-loading {{{
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
						\ | call plug#load('goyo.vim')
						\ | call plug#load('limelight.vim')
						\ | call plug#load('vim-textobj-sentence')
					\ | endif
					\ | call textobj#quote#init({'educate': 1})
				\ | endif
				" Init for non-text-like file types
				autocmd FileType * if index(textlikeft, &filetype) < 0 |
					\   call textobj#quote#init({'educate': 0})
					\ | silent let g:textobj#quote#educate = 1 " For smart quotes in comments & for toggling
				\ | endif
			augroup END
		" }}}

	" }}}

	" Typographic smart quotes {{{
		" Smart quotes toggle
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
		" Smart quotes in comments
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
				\   exec 'silent DelimitMateOff'
				\ | call <SID>SmartQuotesInComments()
				\ | exec 'silent DelimitMateOn'
			\ | endif
			autocmd InsertLeave * if index(textlikeft, &filetype) < 0 |
				\   exec 'silent NoEducate'
			\ | endif
		augroup END
	" }}}

	" Limelight & Goyo {{{
		let g:limelight_conceal_ctermfg = 10
		let g:limelight_conceal_guifg = '#586e75'
		function! s:goyo_enter()
			silent !tmux set status off
			set noshowcmd
			set scrolloff=999
			Limelight
			GitGutterDisable
		endfunction
		function! s:goyo_leave()
			silent !tmux set status on
			set showcmd
			set scrolloff=1
			Limelight!
			GitGutterEnable
		endfunction
		augroup goyo_limelight
			autocmd!
			autocmd User GoyoEnter nested call <SID>goyo_enter()
			autocmd User GoyoLeave nested call <SID>goyo_leave()
		augroup END
		nnoremap <Leader>g :Goyo<CR>
	" }}}

	" Session management {{{
		Plug 'tpope/vim-obsession'
		Plug 'dhruvasagar/vim-prosession'
		let g:prosession_dir = expand(vimDir . 'tmp/session/')
	" }}}

	" Add filename and line numbers to yank
	Plug 'AaronLasseigne/yank-code'
	map <leader>Y <plug>YankCode

" }}}

" Plugins that have to be last because of loading order {{{

	" Pretty font icons like Seti-UI {{{
		" Needs to be near the end because it changes the way some of the
		" other plugins like ctrl-p, startify, NERDTree, etc. work.
		Plug 'ryanoasis/vim-devicons'
		let g:WebDevIconsUnicodeDecorateFolderNodes = 1
		let g:DevIconsEnableFoldersOpenClose = 1
		if exists("g:loaded_webdevicons")
			call webdevicons#refresh()
		endif
		augroup devicons
			autocmd!
			autocmd FileType nerdtree setlocal nolist
			autocmd FileType nerdtree syntax match hideBracketsInNerdTree "\]" contained conceal containedin=ALL
			autocmd FileType nerdtree syntax match hideBracketsInNerdTree "\[" contained conceal containedin=ALL
			autocmd FileType nerdtree setlocal conceallevel=3
			autocmd FileType nerdtree setlocal concealcursor=nvic
		augroup END
		function! DeviconsColors(config)
			let colors = keys(a:config)
			augroup devicons_colors
				autocmd!
				for color in colors
					if color ==# 'normal'
						exec 'autocmd FileType nerdtree,startify if &background ==# ''dark'' | '.
							\ 'highlight devicons_'.color.' guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' | '.
							\ 'else | '.
							\ 'highlight devicons_'.color.' guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' | '.
							\ 'endif'
					elseif color ==# 'emphasize'
						exec 'autocmd FileType nerdtree,startify if &background ==# ''dark'' | '.
							\ 'highlight devicons_'.color.' guifg='.g:sol.gui.base1.' ctermfg='.g:sol.cterm.base1.' | '.
							\ 'else | '.
							\ 'highlight devicons_'.color.' guifg='.g:sol.gui.base01.' ctermfg='.g:sol.cterm.base01.' | '.
							\ 'endif'
					else
						exec 'autocmd FileType nerdtree,startify highlight devicons_'.color.' guifg='.g:sol.gui[color].' ctermfg='.g:sol.cterm[color]
					endif
					exec 'autocmd FileType nerdtree,startify syntax match devicons_'.color.' /\v'.join(a:config[color], '.|').'./ containedin=ALL'
				endfor
			augroup END
		endfunction
		let g:devicons_colors = {
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
		\}
		call DeviconsColors(g:devicons_colors)
	" }}}

" }}}

" Load plugins {{{

	call plug#end()

" }}}

" Set Colorscheme {{{

	colorscheme solarized

" }}}

" Load local ‘after’ settings {{{

	if filereadable(expand(vimRc . '.after'))
		source expand(vimRc . '.after')
	endif

" }}}

" vim: set foldmethod=marker foldlevel=0 foldcolumn=4 textwidth=78:
