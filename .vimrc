""""""""""""""""""
"                "
" Set up plugins "
"                "
""""""""""""""""""

" initialise pathogen
call pathogen#infect()
" Create help tags for pathogen plugins automatically
call pathogen#helptags()

" Include matchit
source $VIMRUNTIME/macros/matchit.vim


""""""""""""""""""""""""
"                      "
" General VIm settings "
"                      "
""""""""""""""""""""""""

" Use VIm, and not VI
set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start
" use visual terminal bell
set vb
" line numbers
set number
" Don't break words when wrapping lines
set linebreak
" set tabs to display as 4 spaces wide (might be overwritten by .editorconfig
" files)
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
" keep 999 lines of command line history
set history=999
" show the cursor position all the time
set ruler
" display incomplete commands
set showcmd
" do incremental searching
set incsearch
" ignore case sensitivity in searching
set ignorecase
" smart case sensitivity in searching
set smartcase
" Don't use Ex mode, use Q for formatting
map Q gq
" CTRL-U in insert mode deletes a lot.  Use CTRL-G u to first break undo,
" so that you can undo CTRL-U after inserting a line break.
inoremap <C-U> <C-G>u<C-U>

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

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
	set background=dark
	colorscheme solarized
endif

" Practically unlimited tabs
set tabpagemax=999

" Only do this part when compiled with support for autocommands.
if has("autocmd")

	" Enable file type detection.
	" Use the default filetype settings, so that mail gets 'tw' set to 72,
	" 'cindent' is on in C files, etc.
	" Also load indent files, to automatically do language-dependent indenting.
	filetype plugin indent on

	" Put these in an autocmd group, so that we can delete them easily.
	augroup vimrcEx
		au!

		" For all text files set 'textwidth' to 78 characters.
		autocmd FileType text setlocal textwidth=78
		autocmd FileType mkd setlocal textwidth=78
		autocmd FileType md setlocal textwidth=78

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

else

	set autoindent		" always set autoindenting on

endif " has("autocmd")

" Convenient command to see the difference between the current buffer and the
" file it was loaded from, thus the changes you made.
" Only define it when not defined already.
if !exists(":DiffOrig")
  command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
		  \ | wincmd p | diffthis
endif

" Open each file (buffer) in it's own tab on first open
augroup tabopen
   autocmd!
   autocmd VimEnter * nested if &buftype != "help" | tab sball | endif
augroup END

" Set working directory to current file on initial vim start
cd %:p:h

" automatically compile coffee-script files into javascript
au BufWritePost *.coffee silent CoffeeMake!

" set filetype for tpl files
autocmd BufNewFile,BufRead *.tpl set filetype=php

" set filetype for scss files
autocmd BufNewFile,BufRead *.scss set filetype=scss

" set indentation for CSS files
autocmd BufNewFile,BufRead *.css set shiftwidth=4

" Do not open NERDTree on start
let g:nerdtree_tabs_open_on_gui_startup = 0

" allow autocomplpop to access snippets
let g:acp_behaviorSnipmateLength=-1

" Options for project.vim
let g:proj_flags="imstg"

" Options for Zen Coding
let g:user_zen_settings = {
			\	'indentation' : "\t",
			\	'lang' : 'en',
			\	'html' : {
			\		'filters' : 'html'
			\	},
			\	'php' : {
			\		'extends' : 'html',
			\		'filters' : 'html,c',
			\	},
			\	'css' : {
			\		'filters' : 'fc',
			\	},
			\	'javascript' : {
			\		'snippets' : {
			\			'jq' : "$(function() {\n\t${cursor}${child}\n});",
			\			'jq:each' : "$.each(arr, function(index, item)\n\t${child}\n});",
			\			'fn' : "(function() {\n\t${cursor}\n})();",
			\			'tm' : "setTimeout(function() {\n\t${cursor}\n}, 100);",
			\		},
			\	},
			\}

" SLIME settings
" I use tmux, not screen
let g:slime_target = "tmux"
" default current window, pane 1
let g:slime_default_config = {"socket_name": "default", "target_pane": ":.1"}

" Useful abbreviations
iabbrev @@ zeorin@gmail.com
iabbrev ssig Kind regards,<cr><cr>Xandor Schiefer<cr>079 706 5620<cr>zeorin@gmail.com

" Set the leader
let mapleader = ','
let maplocalleader = '/'

" Map NERDTreeTabsToggle to a key combination
nnoremap <F8> :NERDTreeTabsToggle<CR>

" Map Gundo to F5
nnoremap <F5> :GundoToggle<CR>

" edit and source the vimrc file quickly
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" move the current line down
nnoremap <leader>- ddp

" move the current line up
nnoremap <leader>_ ddkP

" make the CURRENT word uppercase
inoremap <leader><c-u> <esc>viwUea
nnoremap <leader><c-u> viwUe

" wrap current selection in quotes
vnoremap <leader>" <esc>`<i"<esc>`>la"<esc>
vnoremap <leader>' <esc>`<i'<esc>`>la'<esc>

" change ESC to jk
inoremap jk <esc>

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
