" Everything that's Trigenix specific

"function! AutoTag()
"    let f = expand ("%:p")
"    let lines = system ("autoTag " . f)
"endfunction

function! Craig_insert_template()
    exec "r!mktempl " . expand ("%:p")
endfunction

map <C-F11> :call Craig_insert_template()<CR>

function! Craig_insert_singleton()
    exec "r!mktempl -s " . expand ("%:p")
endfunction

map <C-F12> :call Craig_insert_singleton()<CR>

function! CheckSourceFile ()
    new
    r!sclc #
    r!checker.pl #
    set nomodified
endfunction

map <Leader><S-c> :call CheckSourceFile()<CR>

function! GotoT3 ()
    let t3home=expand ("$T3_HOME")
    exec "cd " . t3home
endfunction

function! T3Startup ()
    call Make_higher ()
    copen
    call GotoT3 ()
    winc w
endfunction

function! GotoT4 ()
    let t3home=expand ("$T4_HOME")
    exec "cd " . t3home . "/code/player/portable"
endfunction

function! T4Startup ()
    call Make_higher ()
    copen
    call GotoT4 ()
    winc w
endfunction

function! GotoT5 (branch)
    let d = ""
    if a:branch == "HEAD"
       let d=g:t5srchome
    elseif a:branch == "5.3.1"
       if has("unix")
           let d = g:sandbox."/5.3.1/rel"
       else
           let d = g:sandbox."\\5.3.1\\rel"
       endif
    elseif a:branch == "5.2.x"
       if has("unix")
           let d = g:sandbox."/5.2.x/dev"
       else
           let d = g:sandbox."\\5.2.x\\dev"
       endif
    elseif a:branch == "5.1.x"
       if has("unix")
           let d = g:sandbox."/5.1.x/dev"
       else
           let d = g:sandbox."\\5.1.x\\dev"
       endif
    elseif a:branch == "6.0.0"
       if has("unix")
           let d = g:sandbox."/6.0.0/rel"
       else
           let d = g:sandbox."\\6.0.0\\rel"
       endif
    elseif isdirectory(a:branch)
       let d = a:branch
       echo "Setting T5 to ".d
       call NewT5SrcHome(d)
    endif
    if d != ""
       call TagsT5(a:branch)
       exec "chdir " . d
    endif
    unlet d
endfunction

function! T5GrowPath ()
    if !exists("g:trigenix_path_added") && exists("g:sandbox")
        let g:trigenix_path_added = 1
        if has("unix")
            let sep = "/"
        else
            let sep = "\\\\"
        endif
        let to_add = sep . "**"
        exec "set path+=" . g:sandbox . to_add
    endif
endfunction

function! T5Startup ()
    call GotoT5 ("HEAD")
    call T5GrowPath ()
endfunction

function! FindProtestParcel ()
   let p = expand ("<cfile>")
   let par = FindUpTree ("/testcontent/" . p)
   if filereadable (par)
      exec "edit " . par
   else
      redraw
      exec "echo \"parcel '" . p . "' not found\""
   endif
endfunction

map gP :call FindProtestParcel()<CR>
