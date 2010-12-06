" compile, build etc

set makeprg=cc.bat
compiler msvc

function! Toggle_makeprg()
    if &makeprg == "make"
        compiler msvc
        set makeprg=cc.bat
    elseif &makeprg == "cc.bat"
        compiler pc-lint
        set makeprg=lint.bat
    else
        compiler gcc
        set makeprg=make
    endif
    echo "makeprg now = " . &makeprg
endfunction

map <Leader>m :call Toggle_makeprg()<CR>

function! Craig_compile()
    let ftail = expand ("%:p:t")
    let fbase = expand ("%:t:r")

    if ftail ==? "Makefile"
        exec ":make"
    else
        exec "make " . fbase . ".o"
    endif
endfunction

"map <F4> :mak %<.o<CR>
"map <F4> :call Craig_compile()<CR>
"map <F5> :cd .<CR>:mak depend<CR>:mak build/ipaq_linux/obj/%<.o<CR>
map <F6> :cd .<CR>:mak %<.o<CR>

function! CompileT2Linux ()
    cd .
    silent mak depend
    mak build/linux/obj/%<.o
endfunction

function! FindMakefile ()
   let mf = FindUpTree("/Makefile")
   if filereadable (mf)
      exec "lcd " . fnamemodify (mf, ":h")
   endif
endfunction

function! CompileT3Linux ()
    silent mak depend
    mak build/i686/Linux/debug/%<.o
endfunction

function! CompileT3Arm ()
    silent mak depend
    mak build/ARM/OSE/debug/%<.o
endfunction

function! CompileT3 ()
    silent mak depend
    mak build/$BUILDARCH/$BUILDOS/$BUILDCHAIN/$PROFILE/%<.o
endfunction

function! CompileT4 ()
    if &makeprg == "pcompile"
        mak -d -V '<%:h>%:t:r.obj'
    else
        silent mak depend
        mak build/$T4BUILDARCH/$T4BUILDOS/$T4BUILDCHAIN/$T4PROFILE/%<.o
    endif
endfunction

function! DeLint ()
    call FindPmakeDotBat ()
    make %
    call MyCopen()
endfunction

function! CompileCcompiler ()
    call FindPmakeDotBat ()
    make %
    call MyCopen()
endfunction

function! Compile ()
    if &makeprg == "make"
    elseif &makeprg == "cc.bat"
       call CompileCcompiler()
    elseif &makeprg == "lint.bat"
       call DeLint()
    endif
endfunction

function! FindPmakeDotBat ()
   let f = FindUpTree ("/pmake.bat")
   if filereadable (f)
      exec "lcd " . fnamemodify (f, ":h")
   endif
endfunction

map <F5> :call DeLint()<CR>

function! CannotCompileHeaders ()
    let choice = confirm ("You cannot compile a header file!", "Oh! Okay. :-)")
endfunction

function! MyCopen ()
   botright copen
   wincmd p
endfunction

map <M-PageDown> :cn<CR>
map <M-PageUp> :cp<CR>
map <M-Home> :cfirst<CR>
map <M-End> :clast<CR>
map <M-Del> :cclose<CR>
"map <M-Ins> :botright copen<CR><C-W>p
map <M-Ins> :cal MyCopen()<CR>
map <F4> :botright copen<CR><C-W>p:call Compile()<CR>
"map <C-F4> :mak<CR>
map <C-F4> :cd .<CR>:mak -d -V dist<CR>

if !exists("tools_grown")
    let tools_grown = 1
    if filereadable($VIMRUNTIME . "/macros/explorer.vim")
        source $VIMRUNTIME/macros/explorer.vim
        amenu Tools.-SEP2- :
        amenu Tools.Open\ Explorer\ Window :call ExplInitiate(0)<cr>
        amenu Tools.Split\ To\ Explorer\ Window :call ExplInitiate(1)<cr>
    endif
endif

function! LintSummaryOpenOutput()
    let b:dir = substitute(expand("%:p:h"), "\\", "/", "g")
    let b:lo = b:dir."/".fnamemodify(expand("<cfile>"), ":t:r").".lo"
    if filereadable(b:lo)
       exec "edit ".b:lo
    endif
endfunction

map <Leader>L :call LintSummaryOpenOutput()<CR>
