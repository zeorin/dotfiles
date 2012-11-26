set nocompatible
source $VIMRUNTIME/vimrc_example.vim

" use visual terminal bell
set vb

" initialise pathogen
call pathogen#infect()

" no write backup
"set nowb
" no backup files
"set nobk
" line numbers
set number

" Don't break words when wrapping lines
set linebreak

" Set colors
colorscheme twilight

" Include matchit
source $VIMRUNTIME/macros/matchit.vim

" set tabs to display as 4 spaces wide
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab

" set filetype plugins and indent ON (needed for sparkup)
filetype indent plugin on

" Nearly unlimited tabs
set tabpagemax=99

" automatically compile coffee-script files into javascript
au BufWritePost *.coffee silent CoffeeMake!

" set filetype for tpl files
au BufNewFile,BufRead *.tpl set filetype=html

" set filetype for scss files
au BufNewFile,BufRead *.scss set filetype=scss

" Set working directory to current file on initial vim start
cd %:p:h

" Map - to move a line down
nmap - ddp

" Map NERDTreeTabsToggle to a key combination
nmap <F8> :NERDTreeTabsToggle<CR>

" Map Gundo to F5
nnoremap <F5> :GundoToggle<CR>

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
