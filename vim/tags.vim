" Increment the number below for a dynamic #include guard
let s:tags_vim_version=1

if exists("g:tags_vim_version_sourced")
   if s:tags_vim_version != g:tags_vim_version_sourced
      finish
   endif
endif

let g:tags_vim_version_sourced=s:tags_vim_version

" this is where everything to do with tags will happen

map <M-]> :tn<CR>:chdir .<CR><C-G>
map <D-]> :tn<CR>:chdir .<CR><C-G>
map <M-[> :tp<CR>:chdir .<CR><C-G>
map <D-[> :tp<CR>:chdir .<CR><C-G>
map <C-MiddleMouse> :tn<CR>
map <Leader><C-]> :exec("bel vert stselect ".expand("<cword>"))<CR>
map <Leader>g<C-]> :exec("tab tselect ".expand("<cword>"))<CR>

"source ~/.dotFiles/vim/find.vim
runtime find.vim

function! FindTagsFile ()
   let f = FindUpTree("/tags")
   if filereadable (f)
      exec "lcd " . fnamemodify (f, ":h")
   endif
endfunction

function! AddTagFileIfReadable (filename)
    if filereadable(a:filename)
        exec "set tags+=".a:filename
        return " succeeded"
    else
        return " failed"
    endif
endfunction

if !exists("g:tags_sandbox") && exists("g:sandbox")
   let g:tags_sandbox=g:sandbox
   if has("win32")
       let g:tags_sb=g:tags_sandbox."\\"
   else
       let g:tags_sb=g:tags_sandbox."/"
   endif
endif

if has("win32")
  let g:ctags_command=substitute($CYGWIN_1_5_12, '\\', '/', 'g') . "/bin/ctags.exe"
endif

function! BuildTagsFile()
    echo "Building tags file (in '" . getcwd() . "') with '" . expand(g:ctags_command) . "'"
    let lines=system (expand(g:ctags_command))
    redraw
    file
endfunction

function! TagsAction (action, tf)
    let ret = ""
    if a:action == "add"
      let ret = AddTagFileIfReadable(a:tf)
    elseif a:action == "del"
        exec "set tags-=".a:tf
    elseif a:action == "rebuild"
        let dir = fnamemodify(a:tf, ":h")
        if isdirectory(dir)
            let olddir = getcwd()
            exec "cd " . dir
            call BuildTagsFile()
            exec "cd " . olddir
        endif
    endif
    return ret
endfunction

let g:autotagVerbosityLevel=1
if has("win32")
  let g:autotagCtagsCmd=g:ctags_command
endif
"source ~/.dotFiles/vim/autotag.vim
runtime autotag.vim

function! PreviewWord()
  if &previewwindow			" don't do this in the preview window
    return
  endif
  let w = expand("<cword>")		" get the word under cursor
  if w =~ '\a'			" if the word contains a letter

    " Delete any existing highlight before showing another tag
    silent! wincmd P			" jump to preview window
    if &previewwindow			" if we really get there...
      match none			" delete existing highlight
      wincmd p			" back to old window
    endif

    " Try displaying a matching tag for the word under the cursor
    try
       exe "ptag " . w
    catch
      return
    endtry

    silent! wincmd P			" jump to preview window
    if &previewwindow		" if we really get there...
	 if has("folding")
	   silent! .foldopen		" don't want a closed fold
	 endif
	 call search("$", "b")		" to end of previous line
	 let w = substitute(w, '\\', '\\\\', "")
	 call search('\<\V' . w . '\>')	" position cursor on match
	 " Add a match highlight to the word at this position
      hi previewWord term=bold ctermbg=green guibg=green
	 exe 'match previewWord "\%' . line(".") . 'l\%' . col(".") . 'c\k*"'
      wincmd p			" back to old window
    endif
  endif
endfun
"au! CursorHold *.[chCH] nested call PreviewWord()
"au! CursorHold *.[ch]pp nested call PreviewWord()
"au! CursorHold *.py nested call PreviewWord()
"au! CursorHold *.pmake nested call PreviewWord()
"au! CursorHold *.vim nested call PreviewWord()

function! ColonCmd(cmd)
  set iskeyword+=:
  let kw=expand("<cword>")
  set iskeyword-=:
  exec a:cmd." ".kw
endfunction

map c<C-]> :call ColonCmd("tag")<CR>
map cg<C-]> :call ColonCmd("tjump")<CR>

" vim:shiftwidth=4:ts=4
