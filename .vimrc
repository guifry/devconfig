syntax on

set belloff=all
set number
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set nu
set nowrap
set smartcase
set noswapfile
set nobackup
set undodir=~/.vim/undodir
set undofile
set incsearch
set ttimeoutlen=80

" Relative line numbers except current line
set number
set relativenumber

nmap <M-p> <Plug>yankstack_substitute_older_paste
nmap <M-n> <Plug>yankstack_substitute_newer_paste

" Show status bar at the bottom, to know what file it is etc.
set statusline=%f\ %m\ %=\ %l:%c

set colorcolumn=80
highlight ColorColumn ctermbg=0 guibg=lightgrey

call plug#begin('~/.vim/plugged')

Plug 'morhetz/gruvbox'
Plug 'jremmen/vim-ripgrep'
Plug 'tpope/vim-fugitive'
Plug 'leafgarland/typescript-vim'
Plug 'vim-utils/vim-man'
Plug 'git@github.com:kien/ctrlp.vim.git'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'mbbill/undotree'
Plug 'JamshedVesuna/vim-markdown-preview'
" JSX, ts, js
Plug 'yuezk/vim-js'
Plug 'HerringtonDarkholme/yats.vim'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'maxbrunsfeld/vim-yankstack'


call plug#end()

colorscheme gruvbox
set background=dark

" Able to paste multiple times
xnoremap p pgvy
" Share clipboard with system
set clipboard=unnamed

let g:ctrlp_custom_ignore = 'node_modules'


