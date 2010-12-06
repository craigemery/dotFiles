" set up my known file types

augroup filetype
"autocmd BufNewFile,BufRead Env* set ft=sh
autocmd BufNewFile,BufRead .make.out* set ft=sh
autocmd BufNewFile,BufRead .bash* call SetFileTypeSH("bash")
autocmd BufNewFile,BufRead *.buf set ft=sql
autocmd BufNewFile,BufRead *.tml set ft=xml
autocmd BufNewFile,BufRead *.diff set ft=diff
autocmd BufNewFile,BufRead */tag/* set ft=tags
autocmd BufNewFile,BufRead */tag/mktag call SetFileTypeSH("bash")
autocmd BufNewFile,BufRead *.tag set ft=tags
autocmd BufNewFile,BufRead *.cp set ft=cpp
autocmd BufNewFile,BufRead *.tpp set ft=cpp
autocmd BufNewFile,BufRead */ospace/* set ft=cpp
autocmd BufNewFile,BufRead,BufEnter Imake* call Enter_makefile ()
autocmd BufNewFile,BufRead,BufEnter Makefile.* call Enter_makefile ()
autocmd BufNewFile,BufRead,BufEnter Makefile call Enter_makefile ()
autocmd BufNewFile,BufRead,BufEnter *.mk call Enter_makefile ()
autocmd BufNewFile,BufRead *_[ch]pp set ft=cpp
"autocmd BufNewFile,BufRead,BufEnter *.cpp call Enter_enscriptable ()
"autocmd BufLeave,BufNew * call Leave_enscriptable()
autocmd BufNewFile,BufRead,BufNew,BufEnter * cd .
autocmd BufNewFile,BufRead *.h[ei][cptvmoi] set ft=c
autocmd BufNewFile,BufRead *.pmake* set ft=python
autocmd BufEnter,FileType * call Maybe_enter_p4_submit()
autocmd BufNewFile,BufRead *.lnt set ft=cpp
autocmd BufNewFile,BufRead,BufEnter *.py call Enter_python ()
autocmd BufNewFile,BufRead,BufEnter * call OnlyRubyHasQueryEtc ()
autocmd BufLeave,BufNew * call Leaving()
augroup end

function! Enter_makefile()
  set ft=make
  set noexpandtab
  set shiftwidth=8
endfunction

function! Maybe_enter_p4_submit()
   if &ft == 'perforce'
      set noexpandtab
      set shiftwidth=8
      setlocal spell
   endif
endfunction

let g:default_shift_width=4

function! Leaving()
   if &ft == 'make'
      set expandtab
      exec "set shiftwidth=".g:default_shift_width
   elseif &ft == 'perforce'
      set expandtab
      exec "set shiftwidth=".g:default_shift_width
   elseif &ft == 'python'
      exec "set shiftwidth=".g:default_shift_width
   elseif &ft == 'ruby'
      exec "set shiftwidth=".g:default_shift_width
   endif
endfunction

function! Enter_python()
  if &ft == 'python'
    set shiftwidth=4
  endif
endfunction

function! OnlyRubyHasQueryEtc()
  if &ft == 'ruby'
    set iskeyword+=?
    set iskeyword+=!
  else
    set iskeyword-=?
    set iskeyword-=!
  endif
endfunction

function! EolSavePre()
   let b:save_bin = &bin
   if ! &eol
      let &l:bin = 1
   endif
endfunction

function! EolSavePost()
   let &l:bin = b:save_bin
endfunction

augroup EOL
autocmd!
autocmd BufWritePre * call EolSavePre()
autocmd BufWritePost * call EolSavePost()
augroup END

