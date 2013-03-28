" Better comportement
set nocompatible

" Better colors
set background=dark
syntax enable

" Show/Unshow line with F2
nnoremap \tn :set invnumber number?<CR>
nmap <F2> \tn
imap <F2> <C-O>\tn

" Always show current position
set ruler

" Use spaces instead of tabs
set expandtab

" Be smart when using tabs ;)
set smarttab

" 1 tab == 2 spaces
set tabstop=2
set shiftwidth=2

" Sets how many lines of history VIM has to remember
set history=700

" Set to auto read when a file is changed from the outside
set autoread

" Configure backspace so it acts as it should act
set backspace=eol,start,indent
set whichwrap+=<,>,h,l

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases 
set smartcase

" Highlight search results
set hlsearch

" Show/Unshow highlight
nnoremap <F3> :set hlsearch!<CR>

" Makes search act like search in modern browsers
set incsearch

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500



