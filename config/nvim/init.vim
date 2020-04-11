"""""""""""""""""""""""""""""""""""""""""""""""""""
" Vim Basic Settings
"""""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
set noerrorbells
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set noswapfile
set nobackup
set undodir=~/.config/nvim/undodir
set undofile
set t_Co=256
set noshowmode

set colorcolumn=120
highlight ColorColumn ctermbg=0 guibg=lightgrey
set cursorline
hi cursorline cterm=none term=none
highlight CursorLine ctermbg=234 guibg=#303000

set encoding=utf-8
set fileencoding=utf-8
set fileencodings=utf-8

set backspace=2
set hidden
set hlsearch
set incsearch
set ignorecase
set smartcase
set fileformats=unix,dos,mac

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Plug settings
"""""""""""""""""""""""""""""""""""""""""""""""""""

let vimplug_exists=expand('~/.config/nvim/autoload/plug.vim')

if !filereadable(vimplug_exists)
    if !executable("curl")
        echoerr "You have to install curl or install vim-plug by yourself!"
        execute "q!"
    endif
    echo "Installing vim-plug..."
    echo ""
    silent exec "!\curl -fLo " . vimplug_exists . " --create-dirs https://raw.github.com/junegunn/vim-plug/master/plug.vim"
    let g:not_finish_vimplug = "yes"
    autocmd VimEnter * PlugInstall
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Install Plugins
"""""""""""""""""""""""""""""""""""""""""""""""""""
call plug#begin('~/.config/nvim/plugged')
Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'vim-utils/vim-man'
Plug 'lyuts/vim-rtags'
Plug 'ycm-core/YouCompleteMe'
Plug 'tpope/vim-surround'
Plug 'jiangmiao/auto-pairs'
Plug 'itchyny/lightline.vim'
Plug 'shinchu/lightline-gruvbox.vim'
Plug 'kien/ctrlp.vim'
Plug 'mbbill/undotree'
Plug 'majutsushi/tagbar'
Plug 'w0rp/ale'
Plug 'yggdroot/indentline'

Plug 'fatih/vim-go'
Plug 'arnaud-lb/vim-php-namespace'
Plug 'stanangeloff/php.vim'
Plug 'hail2u/vim-css3-syntax'
Plug 'ap/vim-css-color'
Plug 'tpope/vim-haml'
Plug 'mattn/emmet-vim'
call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Colors
"""""""""""""""""""""""""""""""""""""""""""""""""""
colorscheme gruvbox
set background=dark

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Ripgrep
"""""""""""""""""""""""""""""""""""""""""""""""""""
if executable('rg')
    let g:rg_derive_root='true'
endif

"""""""""""""""""""""""""""""""""""""""""""""""""""
" CtrlP
"""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ctrlp_user_command = ['.git/', 'git --git-dir=%s/.git ls-files -oc --exclude-standard']
let g:netrw_browse_split=2
let g:netrw_banner = 0
let g:netrw_winsize = 25
let g:ctrlp_use_caching = 0

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Mappings
"""""""""""""""""""""""""""""""""""""""""""""""""""
let mapleader=" "
nnoremap <leader>h :wincmd h<CR>
nnoremap <leader>j :wincmd j<CR>
nnoremap <leader>k :wincmd k<CR>
nnoremap <leader>l :wincmd l<CR>
nnoremap <leader>u :UndotreeShow<CR>
nnoremap <leader>pv :wincmd v<bar> :Ex <bar> :vertical resize 30<CR>
nnoremap <Leader>ps :Rg<SPACE>
nnoremap <silent> <Leader>+ :vertical resize +5<CR>
nnoremap <silent> <Leader>- :vertical resize -5<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""""
" YCM
"""""""""""""""""""""""""""""""""""""""""""""""""""
nnoremap <silent> <Leader>gd :YcmCompleter GoTo<CR>
nnoremap <silent> <Leader>gf :YcmCompleter FixIt<CR>
let g:ycm_autoclose_preview_window_after_completion = 1
let g:ycm_autoclose_preview_window_after_insertion = 1

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Netrw
"""""""""""""""""""""""""""""""""""""""""""""""""""
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_browse_split = 4
let g:netrw_winsize = 20
autocmd WinEnter * if winnr('$') == 1 && getbufvar(winbufnr(winnr()), "&filetype") == "netrw" || &buftype == 'quickfix' |q|endif

"""""""""""""""""""""""""""""""""""""""""""""""""""
" LightLine
"""""""""""""""""""""""""""""""""""""""""""""""""""
let g:lightline = {
            \ 'colorscheme': 'gruvbox',
            \ 'active': {
            \   'left': [ ['mode', 'paste'],
            \               [ 'gitbranch','readonly', 'filename', 'modified'],
            \           ],
            \ },
            \ 'component_function': {
            \   'gitbranch': 'FugitiveHead'
            \ },
            \}

"""""""""""""""""""""""""""""""""""""""""""""""""""
" Fix Trailing whitespaces
"""""""""""""""""""""""""""""""""""""""""""""""""""
command! FixWhitespace :%s/\s\+$//e
