""""""""""""""""""
"                "
" Set up plugins "
"                "
""""""""""""""""""

" VIm settings required for VAM
set nocompatible | filetype indent plugin on | syn on

fun! SetupVAM()
	let c = get(g:, 'vim_addon_manager', {})
	let g:vim_addon_manager = c
	let c.plugin_root_dir = expand('$HOME', 1) . '/.vim/vim-addons'

	" Force your ~/.vim/after directory to be last in &rtp always:
	" let g:vim_addon_manager.rtp_list_hook = 'vam#ForceUsersAfterDirectoriesToBeLast'

	" most used options you may want to use:
	" let c.log_to_buf = 1
	" let c.auto_install = 0
	let &rtp.=(empty(&rtp)?'':',').c.plugin_root_dir.'/vim-addon-manager'
	if !isdirectory(c.plugin_root_dir.'/vim-addon-manager/autoload')
		execute '!git clone --depth=1 git://github.com/MarcWeber/vim-addon-manager '
					\       shellescape(c.plugin_root_dir.'/vim-addon-manager', 1)
	endif

	" This provides the VAMActivate command, you could be passing plugin names, too
	call vam#ActivateAddons([], {})
endfun
call SetupVAM()

" Load plugins dynamically
let scripts = []

" General plugins
call add(scripts, {'names': [
	\'YouCompleteMe',
	\'Solarized',
	\'editorconfig-vim',
	\'fugitive',
	\'Gundo',
	\'The_NERD_tree',
	\'github:jistr/vim-nerdtree-tabs',
	\'NERD_tree_Project',
	\'Hardcore_Mode',
	\'Syntastic',
	\'Tagbar',
	\'commentary',
	\'ack',
	\'vim-airline',
	\'surround',
	\'delimitMate',
	\'easytags',
	\'UltiSnips',
	\'Command-T',
	\'vim-rooter',
	\'vim-multiple-cursors'
\], 'tag': 'general'})

" Filetype/language support
call add(scripts, {'name': 'haml.zip', 'ft_regex': '\(haml\|sass\|scss\)'}) " HAML, SASS, SCSS
call add(scripts, {'name': 'Better_CSS_Syntax_for_Vim', 'ft_regex': 'css'}) " CSS3
call add(scripts, {'name': 'html5', 'ft_regex': 'html'}) " HTML5
call add(scripts, {'name': 'github:marijnh/tern_for_vim', 'ft_regex': 'javascript'}) " JavaScript
call add(scripts, {'name': 'github:tpope/vim-markdown', 'ft_regex': 'markdown'}) " Markdown
call add(scripts, {'name': 'github:mustache/vim-mustache-handlebars', 'filename_regex': '\.hbs$'}) " Handlebars
call add(scripts, {'names': ['github:StanAngeloff/php.vim', 'phpcomplete', 'github:2072/PHP-Indenting-for-VIm'], 'ft_regex': 'php'}) " PHP

" tell VAM about all scripts, and immediately activate plugins having the general tag
call vam#Scripts(scripts, {'tag_regex': 'general'})

" YouCompleteMe options
let g:ycm_key_list_select_completion = ['<C-n>']
let g:ycm_key_list_previous_completion = ['<C-p>']

" Include matchit
source $VIMRUNTIME/macros/matchit.vim


""""""""""""""""""""""""
"                      "
" General VIm settings "
"                      "
""""""""""""""""""""""""

set encoding=utf-8

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" use visual terminal bell
set vb

" line numbers
set number

" Don't break words when wrapping lines
set linebreak

" make wrapped lines more obvious
let &showbreak="> "
set cpoptions+=n

" When turning wrap off, make it more obvious where we are on a line
set listchars+=precedes:<,extends:>

" When wrap is off, horizontally scroll a decent amount.
set sidescroll=16

" set tabs to display as 4 spaces wide (might be overwritten by .editorconfig
" files)
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set shiftround

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

" better command line completion
set wildmode=longest,list:full

" better split window locations
set splitright
set splitbelow

" easier navigation between split windows
nnoremap <c-j> <c-w>j
nnoremap <c-k> <c-w>k
nnoremap <c-h> <c-w>h
nnoremap <c-l> <c-w>l

" hyphens are typically part of function and variable names
set iskeyword+=-
" so are $ characters
set iskeyword+=$

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

" Highlight trailing white space
autocmd ColorScheme * highlight ExtraWhitespace ctermbg=red guibg=red
:au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
:au InsertLeave * match ExtraWhitespace /\s\+$/

" Spell check & word completion
set spell spelllang=en_gb
set complete+=kspell

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
	set t_Co=16
	syntax on
	set hlsearch
	set background=dark
	let g:solarized_termtrans=1
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
		autocmd FileType markdown setlocal textwidth=78

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

" Do not open NERDTree on start
let g:nerdtree_tabs_open_on_gui_startup = 0
" Map NERDTreeTabsToggle to a key combination
nnoremap <F8> :NERDTreeTabsToggle<CR>
" Nerd Tree to find root of project
let g:NTPNamesDirs = ['.git']

" Syntastic options
let g:syntastic_check_on_open = 1
let g:syntastic_check_on_wq = 0
let g:syntastic_quiet_messages = { "type": "style" }
let g:syntastic_html_tidy_exec = '/usr/local/bin/tidy'

" Set the leader
map <Space> <Leader>

" Map Gundo to F5
nnoremap <F5> :GundoToggle<CR>

" Map Tagbar to F9
nnoremap <F9> :TagbarToggle<CR>

" edit and source the vimrc file quickly
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

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

" Current directory ought to be project root
let g:rooter_patterns = ['.git/']

" Airline configuration
set laststatus=2
let g:airline_powerline_fonts=1
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#tab_nr_type = 2
let g:airline#extensions#tabline#left_sep = ''
let g:airline#extensions#tabline#left_alt_sep = ''
let g:airline#extensions#tabline#right_sep = ''
let g:airline#extensions#tabline#right_alt_sep = ''

" Easytags configuration
let g:easytags_languages = {
	\'javascript': {
		\'cmd': '/usr/bin/jsctags',
		\'args': [],
		\'fileoutput_opt': '-f',
		\'stdout_opt': '-f-',
		\'recurse_flag': '-R'
	\}
\}
set tags=.git/tags;,./tags,~/.vimtags;
let g:easytags_dynamic_files = 2
let g:easytags_async = 1
