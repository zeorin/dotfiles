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
	\'sensible',
	\'YouCompleteMe',
	\'Solarized',
	\'editorconfig-vim',
	\'fugitive',
	\'github:airblade/vim-gitgutter',
	\'unimpaired',
	\'Gundo',
	\'The_NERD_tree',
	\'github:Xuyuanp/nerdtree-git-plugin',
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

if !has('nvim')
	set encoding=utf-8
endif

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

" use visual terminal bell
set vb

" line numbers
set relativenumber

" Don't break words when wrapping lines
set linebreak

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

" Switch buffers even if modified
set hidden
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

" For Emacs-style editing on the command-line:
" start of line
cnoremap <C-A> <Home>
" back one character
cnoremap <C-B> <Left>
" delete character under cursor
cnoremap <C-D> <Del>
" end of line
cnoremap <C-E> <End>
" forward one character
cnoremap <C-F> <Right>
" recall newer command-line using current characters as search pattern
cnoremap <C-N> <Down>
" recall previous (older) command-line using current characters as search pattern
cnoremap <C-P> <Up>
" back one word
cnoremap <Esc><C-B> <S-Left>
" forward one word
cnoremap <Esc><C-F> <S-Right>

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
else
	set backup		" keep a backup file
endif

" Create gui and cterm dictionaries for Solarized colors
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

" Make tabs, non-breaking spaces and trailing white space visible
set list
" Use a Musical Symbol Single Barline (0x1d100) to show a Tab, and
" a Middle Dot (0x00B7) for trailing spaces
set listchars=tab:\𝄀\ ,trail:·,extends:>,precedes:<,nbsp:+
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
" Fix some Solarized bugs
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

" Spell check & word completion
set spell spelllang=en_gb
set complete+=kspell
set complete-=i
augroup startify
	autocmd!
	autocmd FileType startify setlocal nospell
augroup END

" Display as much as possible of a line that doesn't fit on screen
set display=lastline

" Better autoformat
set formatoptions+=j	" Remove comment leader when joining lines
set formatoptions-=o	" Don't automatically assume next line after comment is also comment

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
syntax on
set hlsearch
nnoremap <Leader><Space> :nohlsearch<Cr>
colorscheme solarized
if !exists('g:background_style')
	let g:background_style = "dark"
endif
let &background = g:background_style
augroup backgroundswitch
	autocmd!
	autocmd ColorScheme solarized let g:background_style = &background
augroup END

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

" Map NERDTreeToggle to a key combination
nnoremap <F8> :NERDTreeToggle<CR>
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
nnoremap <Leader>ev :vsplit $MYVIMRC<cr>
nnoremap <Leader>sv :source $MYVIMRC<cr>

" change ESC to jk
inoremap jk <esc>

" easy semicolon insertion
inoremap <Leader>; <C-o>m`<C-o>A;<C-o>``
inoremap <Leader>: <C-o>A;

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
augroup goyo
	autocmd!
	autocmd User GoyoEnter Limelight
	autocmd User GoyoLeave Limelight!
	autocmd User GoyoEnter nested call <SID>goyo_enter()
	autocmd User GoyoLeave nested call <SID>goyo_leave()
augroup END
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
nnoremap <Leader>hm :call ToggleHardMode()<CR>

" Faster update for Git Gutter
set updatetime=750

" Command-T settings
let g:CommandTAlwaysShowDotFiles = 1
let g:CommandTScanDotDirectories = 1

" Fix some devicons issues
let g:WebDevIconsUnicodeDecorateFolderNodes = 1
let g:DevIconsEnableFoldersOpenClose = 1
if exists("g:loaded_webdevicons")
	call webdevicons#refresh()
endif
augroup devicons
	autocmd!
	autocmd FileType nerdtree setlocal nolist
augroup END
" NERDTree Devicons Icon highlighting
function! NERDTreeHighlightIcons(icons)
	for icon in a:icons
		exec 'augroup '.icon[0].'_icon'
		exec 'autocmd!'
		exec 'autocmd FileType nerdtree,startify highlight '.icon[0].'_icon guifg='.icon[2].' ctermfg='.icon[3]
		exec 'autocmd FileType nerdtree,startify syn match '.icon[0].'_icon #'.icon[1].'# containedin=NERDTreeFile,NERDTreeDir,StartifyFile'
		exec 'augroup END'
	endfor
endfunction
if !exists('g:nerdtree_icons_highlighted')
	let g:nerdtree_icons_hightlighted = 1
	call NERDTreeHighlightIcons([
		\['text', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['folder', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['closedfolder', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['openfolder', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['stylus', '', g:sol.gui.orange, g:sol.cterm.orange],
		\['sass', '', g:sol.gui.magenta, g:sol.cterm.magenta],
		\['html', '', g:sol.gui.orange, g:sol.cterm.orange],
		\['css', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['markdown', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['json', '', g:sol.gui.base01, g:sol.cterm.yellow],
		\['javascript', '', g:sol.gui.yellow, g:sol.cterm.yellow],
		\['ruby', '', g:sol.gui.red, g:sol.cterm.red],
		\['php', '', g:sol.gui.violet, g:sol.cterm.violet],
		\['python', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['coffee', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['mustache', '', g:sol.gui.orange, g:sol.cterm.orange],
		\['conf', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['picture', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['twig', '', g:sol.gui.green, g:sol.cterm.green],
		\['c', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['haskell', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['lua', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['java', '', g:sol.gui.red, g:sol.cterm.red],
		\['shell', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['ocaml', 'λ', g:sol.gui.orange, g:sol.cterm.orange],
		\['diff', '', g:sol.gui.orange, g:sol.cterm.orange],
		\['database', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['clojure', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['clojurejs', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['scala', '', g:sol.gui.red, g:sol.cterm.red],
		\['go', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['dart', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['xul', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['visualstudio', '', g:sol.gui.violet, g:sol.cterm.violet],
		\['perl', '', g:sol.gui.violet, g:sol.cterm.violet],
		\['rss', '', g:sol.gui.orange, g:sol.cterm.orange],
		\['fsharp', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['rust', '', g:sol.gui.base01, g:sol.cterm.base01],
		\['d', '', g:sol.gui.red, g:sol.cterm.red],
		\['erlang', '', g:sol.gui.red, g:sol.cterm.red],
		\['vim', '', g:sol.gui.green, g:sol.cterm.green],
		\['illustrator', '', g:sol.gui.red, g:sol.cterm.red],
		\['photoshop', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['typescript', '', g:sol.gui.blue, g:sol.cterm.blue],
		\['julia', '', g:sol.gui.green, g:sol.cterm.green]
	\])
endif

" Fix a sass issue
" https://github.com/tpope/vim-haml/issues/66
augroup sass
	autocmd!
	autocmd BufRead,BufNewFile *.sass set filetype=css
augroup END

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
