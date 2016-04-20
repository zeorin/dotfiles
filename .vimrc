""""""""""""""""""
"                "
" Set up plugins "
"                "
""""""""""""""""""

" Vim settings required for VAM
set nocompatible | filetype indent plugin on | syn on

" Set the leader, needs to be done early
let g:mapleader = "\<Space>"

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
			\shellescape(c.plugin_root_dir.'/vim-addon-manager', 1)
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
	\'github:airblade/vim-gitgutter',
	\'unimpaired',
	\'Gundo',
	\'The_NERD_tree',
	\'github:Xuyuanp/nerdtree-git-plugin',
	\'github:jistr/vim-nerdtree-tabs',
	\'NERD_tree_Project',
	\'github:wikitopian/hardmode',
	\'Syntastic',
	\'Tagbar',
	\'commentary',
	\'ack',
	\'surround',
	\'delimitMate',
	\'easytags',
	\'UltiSnips',
	\'github:honza/vim-snippets',
	\'Command-T',
	\'vim-rooter',
	\'vim-multiple-cursors',
	\'vim-exchange',
	\'abolish',
	\'github:sickill/vim-pasta',
	\'github:christoomey/vim-tmux-navigator',
	\'vim-airline',
	\'github:vim-airline/vim-airline-themes',
	\'github:ryanoasis/vim-devicons',
	\'vim-startify',
	\'github:edkolev/tmuxline.vim',
	\'github:edkolev/promptline.vim'
\], 'tag': 'general'})

" Filetype/language support
call add(scripts, {'name': 'haml.zip', 'ft_regex': '\(haml\|sass\|scss\)'}) " HAML, SASS, SCSS
call add(scripts, {'name': 'Better_CSS_Syntax_for_Vim', 'ft_regex': 'css'}) " CSS3
call add(scripts, {'name': 'html5', 'ft_regex': 'html'}) " HTML5
call add(scripts, {'name': 'github:marijnh/tern_for_vim', 'ft_regex': 'javascript'}) " JavaScript
call add(scripts, {'name': 'github:tpope/vim-markdown', 'ft_regex': 'markdown'}) " Markdown
call add(scripts, {'name': 'github:mustache/vim-mustache-handlebars', 'filename_regex': '\.hbs$'}) " Handlebars
" PHP
call add(scripts, {'names': [
	\'github:StanAngeloff/php.vim',
	\'phpcomplete',
	\'github:2072/PHP-Indenting-for-VIm'
\], 'ft_regex': 'php'})
" Text/prose plugins
call add(scripts, {'names': [
	\'vim-pencil',
	\'github:junegunn/limelight.vim',
	\'github:junegunn/goyo.vim'
\], 'ft_regex': '\(markdown\|mkd\|text\|mail\)'})

" tell VAM about all scripts, and immediately activate plugins having the general tag
call vam#Scripts(scripts, {'tag_regex': 'general'})

" YouCompleteMe options
let g:ycm_key_list_select_completion = ['<C-n>']
let g:ycm_key_list_previous_completion = ['<C-p>']

" Include matchit
source $VIMRUNTIME/macros/matchit.vim

""""""""""""""""""""""""
"                      "
" General Vim settings "
"                      "
""""""""""""""""""""""""

set encoding=utf-8

" Blank this out for now
set listchars=

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" use visual terminal bell
set vb

" line numbers
set relativenumber

" Don't break words when wrapping lines
set linebreak

" make wrapped lines more obvious
let &showbreak="> "
set cpoptions+=n

" When turning wrap off, make it more obvious where we are on a line
set listchars+=precedes:<,extends:>

" When wrap is off, horizontally scroll a decent amount.
set sidescroll=16

" Ingore backup files & git directories
set wildignore+=*~,.git

" set tabs to display as 4 spaces wide (might be overwritten by .editorconfig
" files)
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab
set smarttab
set shiftround

" keep max lines of command line history
set history=10000

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
set wildmode=longest,full
set wildmenu
set fileignorecase
set wildignorecase

" better split window locations
set splitright
set splitbelow

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
	set nobackup		" do not keep a backup file, use versions instead
else
	set backup		" keep a backup file
endif

" Make tabs and trailing white space visible
set listchars+=tab:⏐\ ,trail:‧,nbsp:‧
set list
autocmd ColorScheme * highlight SpecialKey gui=NONE term=NONE guifg=#586e75 ctermfg=10 guibg=NONE ctermbg=NONE
" Highlight trailing white space
autocmd ColorScheme * highlight ExtraWhitespace gui=NONE cterm=NONE guifg=red ctermfg=red guibg=NONE ctermbg=NONE
:au InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
:au InsertLeave * match ExtraWhitespace /\s\+$/

" Spell check & word completion
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
if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
	set background=dark
	colorscheme solarized
	" Fix some Solarized bugs
	highlight CursorLineNr gui=NONE term=NONE guifg=#586e75 ctermfg=10 guibg=#073642 ctermbg=0
	highlight SignColumn gui=NONE term=NONE guibg=#073642 ctermbg=0
	" Better Syntastic styles
	highlight SyntasticWarningSign gui=NONE,bold term=NONE,bold guifg=#5f5faf ctermfg=13 guibg=#073642 ctermbg=0
	highlight SyntasticErrorSign gui=NONE,bold term=NONE,bold guifg=#af0000 ctermfg=1 guibg=#073642 ctermbg=0
	" Better git-gutter styles
	highlight lineAdded gui=NONE,bold term=NONE,bold guifg=#5f8700 ctermfg=2 guibg=#073642 ctermbg=0
	highlight lineModified gui=NONE,bold term=NONE,bold guifg=#af8700 ctermfg=3 guibg=#073642 ctermbg=0
	highlight lineRemoved gui=NONE,bold term=NONE,bold guifg=#af0000 ctermfg=1 guibg=#073642 ctermbg=0
endif

" More page tabs allowed
set tabpagemax=50

" Reread changed files
set autoread

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

" Map Gundo to F5
nnoremap <F5> :GundoToggle<CR>

" Map Tagbar to F9
nnoremap <F9> :TagbarToggle<CR>

" edit and source the vimrc file quickly
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>

" change ESC to jk
inoremap jk <esc>

" easy semicolon insertion
inoremap <leader>; <C-o>m`<C-o>A;<C-o>``
inoremap <leader>: <C-o>A;

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

" Powerline-ish specific settings
set laststatus=2 " Always display the statusline in all windows
set showtabline=2 " Always display the tabline, even if there is only one tab
set noshowmode " Hide the default mode text (e.g. -- INSERT -- below the statusline)

" Limelight & Goyo
let g:limelight_conceal_ctermfg = 10
let g:limelight_conceal_guifg = '#586e75'
autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!
function! s:goyo_enter()
	silent !tmux set status off
	set noshowmode
	set noshowcmd
	set scrolloff=999
	Limelight
endfunction
function! s:goyo_leave()
	silent !tmux set status on
	set showmode
	set showcmd
	set scrolloff=5
	Limelight!
endfunction
autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()
nnoremap <Leader>g :Goyo<CR>

" UltiSnips configuration
let g:UltiSnipsExpandTrigger="<Tab>"
let g:UltiSnipsListSnippets="<C-a>"
let g:UltiSnipsJumpForwardTrigger="<C-b>"
let g:UltiSnipsJumpBackwardTrigger="<C-x>"
let g:UltiSnipsEditSplit="vertical"

" Persistent undo
let vimDir = '$HOME/.vim'
if has('persistent_undo')
	let myUndoDir = expand(vimDir . '/undo')
	" Create dirs
	call system('mkdir ' . myUndoDir)
	let &undodir = myUndoDir
	set undofile
endif

" Map HardMode
nnoremap <Leader>h :call ToggleHardMode()<CR>

" Faster update for Git Gutter
set updatetime=750

" Command-T settings
let g:CommandTAlwaysShowDotFiles = 1
let g:CommandTScanDotDirectories = 1

" Fix some devicons issues
autocmd FileType nerdtree setlocal nolist
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1

" Fix a sass issue
" https://github.com/tpope/vim-haml/issues/66
autocmd BufRead,BufNewFile *.sass set filetype=css

" Set Airline configuration
" Use powerline glyphs
let g:airline_powerline_fonts = 1
" Use tabline
let g:airline#extensions#tabline#enabled = 1
" Show buffers when no tabs
let g:airline#extensions#tabline#show_buffers = 1
" Always show tabline
let g:airline#extensions#tabline#show_tabs = 1

" Set comments to be italic
highlight Comment cterm=italic
