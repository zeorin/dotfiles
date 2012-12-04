""""""""""""""""""""""""
"                      "
" General VIm settings "
"                      "
""""""""""""""""""""""""

" Use VIm, and not VI
set nocompatible

" use visual terminal bell
set vb
" line numbers
set number
" Don't break words when wrapping lines
set linebreak
" set tabs to display as 4 spaces wide (might be overwritten by .editorconfig
" files)
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab

" Set colors
colorscheme twilight

" Nearly unlimited tabs
set tabpagemax=99

" Open each file (buffer) in it's own tab on first open
augroup tabopen
   autocmd!
   autocmd VimEnter * nested if &buftype != "help" | tab sball | endif
augroup END

" Set working directory to current file on initial vim start
cd %:p:h




""""""""""""""""""
"                "
" Set up plugins "
"                "
""""""""""""""""""

" set filetype plugins and indent ON (needed for sparkup)
filetype indent plugin on

" Include matchit
source $VIMRUNTIME/macros/matchit.vim

" initialise pathogen
call pathogen#infect()
" Create help tags for pathogen plugins automatically
:Helptags


" automatically compile coffee-script files into javascript
au BufWritePost *.coffee silent CoffeeMake!

" set filetype for tpl files
autocmd BufNewFile,BufRead *.tpl set filetype=html

" set filetype for scss files
autocmd BufNewFile,BufRead *.scss set filetype=scss

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
inoremap <esc> <nop>

" unmap keys I shouldn't be using
nnoremap <up> <nop>
nnoremap <down> <nop>
nnoremap <left> <nop>
nnoremap <right> <nop>
inoremap <up> <nop>
inoremap <down> <nop>
inoremap <left> <nop>
inoremap <right> <nop>
