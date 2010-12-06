" Rails stuff

function! FindAppDir ()
   let v = FindDirUpTree("/app")
   if isdirectory (v)
      exec "lcd " . fnamemodify (v, ":h")
   endif
endfunction
