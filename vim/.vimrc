" Until I get a 6.x version of readfile
"if v:version >= 700
"so ~/.dotFiles/vim/perforce.vim
"call InitPerforce()
"endif

filetype off
set rtp^=~/.dotFiles/vim/bundle/vundle
call vundle#rc()
Bundle 'gmarik/vundle'
"Bundle 'bling/vim-bufferline'
filetype plugin on
filetype plugin indent on

let Tlist_Show_Menu=1
if has("win32")
  let $PATH = $PATH . ";C:/Program Files/Git/bin"
  let $PATH = $PATH . ";C:/cygwin/bin"
endif

set nocompatible

set history=100
set visualbell
set hls
set suffixes+=.pyc
set wildignore+=*.pyc
set wildignore+=*.o
set incsearch
set makeprg=gmake
set colorcolumn=100
set mouse=a
let g:netrw_cygwin=1

if !exists("path_grown")
  let path_grown = 1
  if has("unix")
    set path-=/usr/include
    set path+=/usr/include/**
    "set path+=~/dist/shell
    "set path+=~/dist/perl,~/.dotFiles/**
    "set path+=~/.dotFiles/**
  endif

set ai
map <silent> <Leader>/ :let @/=""<CR>
set diffopt+=context:9999
set showtabline=2

"  if has("win32")
"    set path^=Y:\asterisk\Limits_Exposure\,Y:\asterisk\Limits_Exposure\Frameworks,Y:\NTLibs\iona\include,Y:\NTLibs\Rogue
"  endif
endif
set smartindent
set tabstop=8
let g:default_shiftwidth=4
exec "set shiftwidth=".g:default_shiftwidth
set expandtab
set ruler
set laststatus=2

if &term =~ "xterm"
  if has("terminfo")
    set t_Co=8
    set t_Sf=[3%p1%dm
    set t_Sb=[4%p1%dm
  else
    set t_Co=8
    set t_Sf=[3%dm
    set t_Sb=[4%dm
  endif
elseif &term =~ "screen"
  set noicon
endif

syntax enable
colorscheme pablo
"set background=dark
"highlight Normal guifg=#e0e0ff guibg=#404040

"function! Toggle_background()
"  if &background == "light"
"    syntax off
"    set background=dark
"    highlight Normal guifg=#e0e0ff guibg=#404040
"    syntax on
"  else
"    syntax off
"    set background=light
"    highlight Normal guibg=#e0e0ff guifg=#404040
"    syntax on
"  endif
"endfunction

set keywordprg=Man

map <F2> :next<CR>
map <C-F2> :prev<CR>
map <F3> :update<CR>:chdir .<CR><C-G>
map <M-F3> :w!<CR>:chdir .<CR><C-G>
"map <S-F3> :wa<CR>:chdir .<CR><C-G>
map <S-F3> :tabnew<CR>:bufdo! update<CR>:tabclose<CR>
map <F9> :q!<CR>
map <S-F9> :bd!<CR>
map <F11> :confirm q<CR>
map <F12> :e!<CR>
map <C-N> :n<CR>:chdir .<CR><C-G>
map <C-P> :N<CR>:chdir .<CR><C-G>
"noremap / :se hls<CR>/
"noremap ? :se hls<CR>?
map <PageDown> 10jzz
map <PageUp> 10kzz
map <S-Home> 1G<C-G>
map <S-End> G<C-G>
map <S-PageDown> <C-F>M
map <S-PageUp> <C-B>M
map <M-Up> 10<Up>
map <M-Down> 10<Down>
map <M-Left> 10<Left>
map <M-Right> 10<Right>
"map <ESC><Up> 10<Up>
"map <ESC><Down> 10<Down>
"map <ESC><Left> 10<Left>
"map <ESC><Right> 10<Right>
map <C-Up> 10<Up>
map <C-Down> 10<Down>
"noremap n :se hls<CR>n
"noremap N :se hls<CR>N
noremap <S-LeftMouse> :se hls<CR><S-LeftMouse>
map <C-Left> b
map <S-Left> B
map <C-Right> w
map <S-Right> W
map <Leader>l :se list!<CR>
"map <ESC>l :se list!<CR>
"map <ESC>L :se hls<CR>/.\{80\}<CR>
map <C-Space> /[ 	]\{1,\}$/<CR>
map <Leader><Space> :%s@[ 	]\{1,\}$@@g<CR>
"map <ESC><Space> :%s@[ 	]\{1,\}$@@g<CR>
map <C-S-Space> /^.\{80\}<CR>
map + <C-E><Down>
map - <C-Y><Up>
map <kPlus> <C-E><Down>
map <kMinus> <C-Y><Up>
map <C-MouseUp> <C-E><Down>
map <C-MouseDown> <C-Y><Up>
imap <C-+> <ESC><C-E>a
imap <C--> <ESC><C-Y>a
map <C-kPlus> <ESC><C-E>a
map <C-kMinus> <ESC><C-Y>a
map <C-TAB> :wnext<CR>

map <C-S-Down> <C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down>
map <C-S-Up> <C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up>
map <M-MouseUp> <C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down><C-E><Down>
map <M-MouseDown> <C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up><C-Y><Up>
map <MouseUp> 3<C-E>
map <MouseDown> 3<C-Y>

"map [7^ <C-Home>
"map [8^ <C-End>
"map [5^ <C-PageUp>
"map [6^ <C-PageDown>
"map Oa <C-Up>
"map Ob <C-Down>
"map Oc <C-Right>
"map Od <C-Left>
"map [a <S-Up>
"map [b <S-Down>
"map [c <S-Right>
"map [d <S-Left>

"map OQ /
"map OS <kMinus>
"map Ol <kPlus>
"map OM <CR>
"map Ow <Home>
"map Ox <Up>
"map Oy <PageUp>
"map Ot <Left>
"map Ov <Right>
"map Oq <End>
"map Or <Down>
"map Os <PageDown>
"map [1~ <Home>
"map [4~ <End>
"map [5~ <PageUp>
"map [6~ <PageDown>
"map [2~ i
"map ] :tn<CR>

inoremap <M-2> ""<Esc>i
inoremap <M-'> ''<Esc>i
inoremap <M-9> ()<Esc>i
inoremap <M-[> []<Esc>i
inoremap <M-5> <Space>% ()<Esc>i

cmap <S-Insert> <MiddleMouse>
imap <M-BS> 

nnoremap <silent> gf :lchdir .<CR>:echo "Trying to find file ".'"'.expand("<cfile>").'" in path'<CR>gf
noremap <C-O> <C-O>:chdir .<CR><C-G>
noremap <C-I> <C-I>:chdir .<CR><C-G>

"cab cd chdir

function! Enter_enscriptable()
    amenu 10.510 File.&Print :let answer=system ("enscript -2r -C -Ecpp -DDuplex:false")<CR>
endfunction

function! Leave_enscriptable()
  if &ft == 'cpp'
    amenu 10.510 File.&Print :hardcopy<CR>
  endif
endfunction

function! Toggle_num()
  if !exists("g:grow")
    let g:grow = 8
  endif
  set number!
  if &number
    exec "set columns+=" . g:grow
  else
    exec "set columns-=" . g:grow
  endif
endfunction

"map <ESC>n :call Toggle_num()<CR>
map <Leader>n :call Toggle_num()<CR>

set runtimepath^=$HOME/.dotFiles/vim
set rtp+=~/.dotFiles/powerline/powerline/bindings/vim

runtime search.vim
runtime build.vim
"runtime mate.vim
runtime tags.vim
"runtime texperts.vim

"runtime trigenix.vim
"cal T5GrowPath()
runtime craig.vim

let @c = "ce/* \" */F/"
let @u = "3xf/2XxB"
let @d = "O/*  */hhi"

let g:BufferListWidth=40
map <silent> <M-,> :call BufferList()<CR>
hi BufferSelected term=reverse ctermfg=white ctermbg=red cterm=bold
hi BufferNormal term=NONE ctermfg=black ctermbg=darkcyan cterm=NONE

command! BVN belowright vertical new
command! BVS belowright vertical split
command! TN tabnew

if has("win32")
  let g:cvs_command=substitute($CYGWIN_1_5_12, '\\', '/', 'g') . "/bin/cvs.exe"
endif

"runtime version_control-cvs.vim

noremap <C-W><C-Left> <C-W><Left>
noremap <C-W><C-Right> <C-W><Right>
noremap <C-W><C-Up> <C-W><Up>
noremap <C-W><C-Down> <C-W><Down>

runtime patch.vim

"runtime vala.vim

noremap <Leader>gf :execute(":bel vsplit ".expand("<cfile>"))<CR>

let g:NERDTreeOpenVSplitBelowRight=1

" I find the following saved session options cause problems, best to 'just get the buffers and tabs' and that's about it
set sessionoptions-=folds
set sessionoptions-=options

" vim:shiftwidth=2
