"set background=
"syntax on
if has ("win32") || has("unix")
"   set guifont=Lucida_Console:h8
"    set guifont=Lucida_Console:h8:cANSI
    "set guifont=Lucida_Console:h11:cANSI
"   set guifont=Bitstream_Vera_Sans_Mono:h9:cANSI
    set guifont=Consolas:h10:cANSI
endif

set showtabline=2
"set lines=64
"set columns=161
winpos 75 0

if has("mac")
    set transparency=5
    for i in range(1, 9) 
        exec "nnoremap <D-".i."> ".i."gt" 
    endfor
endif

set menuitems=50

set guioptions+=h
set guioptions+=b

"source ~/.dotFiles/vim/version_control-perforce.vim
"source ~/.dotFiles/vim/craig.vim
"runtime craig.vim
"if has("unix")
"elseif has("win32")
""   source ~/vim/version_control.vim
""   source ~/vim/craig.vim
"endif

if has ("unix") && !has("mac")
"   call CraigsFont("misc-fixed", 12)
"   call CraigsFont("lucinda-type", 10)
    call CraigsFont("monospace", 8)
    "set guifont=Menlo\ Regular:h13
endif

"source ~/.dotFiles/vim/resize.vim
runtime resize.vim
set lines=65
set columns=220
"set lines=44
"set columns=126
colorscheme koehler
