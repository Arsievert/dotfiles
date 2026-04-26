set nocompatible
set encoding=utf-8
set backspace=indent,eol,start
set hidden
set number
set laststatus=2
set ruler
set showcmd
set showmode
set wildmenu
set wildmode=longest:full,full
set incsearch
set hlsearch
set ignorecase
set smartcase
set scrolloff=5
set mouse=a
set clipboard=unnamed
set timeoutlen=1000
set ttimeoutlen=50

set autoindent
set smartindent
set expandtab
set tabstop=4
set shiftwidth=4
set softtabstop=4
filetype plugin indent on
syntax enable

set background=dark

if has('persistent_undo')
    set undofile
    set undodir=~/.vim/undo//
endif
set noswapfile
set nobackup
for s:dir in [expand('~/.vim/undo')]
    if !isdirectory(s:dir)
        call mkdir(s:dir, 'p')
    endif
endfor

set path+=**

let mapleader = " "
nnoremap <leader><Space> :nohlsearch<CR>

let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25

set statusline=%f\ %m%r%h%w\ %=%l/%L\ (%p%%)\ col:%c

nnoremap <C-x>o <C-w>w
nnoremap <C-x>2 :split<CR>
nnoremap <C-x>3 :vsplit<CR>
nnoremap <C-x>0 :close<CR>
nnoremap <C-x>1 :only<CR>
nnoremap <C-x>= <C-w>=
nnoremap <C-x>b :ls<CR>:buffer<Space>
nnoremap <C-x>k :bdelete<CR>
nnoremap <C-x><C-f> :find<Space>

