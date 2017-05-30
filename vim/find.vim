" Increment the number below for a dynamic #include guard
let s:find_vim_version=1

if exists("g:find_vim_version_sourced")
   if s:find_vim_version <= g:find_vim_version_sourced
      finish
   endif
endif

let g:find_vim_version_sourced=s:find_vim_version

function! FindUpTreeFrom (name, startDir)
   let oldcwd = getcwd()
   exec "silent lcd " . a:startDir
   let old_dir = ""
   let dir = getcwd()
   let path = dir . a:name
   while ! filereadable (path) && ! isdirectory (path) && dir != old_dir
      lcd ..
      let old_dir = dir
      let dir = getcwd()
      let path = dir . a:name
   endwhile
   lcd .
   if filereadable (path) || isdirectory (path)
      let ret = path
   else
      let ret = ""
   endif
   exec "silent lcd " . oldcwd
   return ret
endfunction

function! FindUpTree (name)
   return FindUpTreeFrom(a:name, expand ("%:p:h"))
endfunction

function! FindDirUpTree (name)
   return FindUpTreeFrom(a:name, expand ("%:p:h"))
endfunction

function! FindHgRoot ()
   let root = FindUpTreeFrom("/.hg", expand ("%:p:h"))
   if isdirectory (root)
      exec "silent lcd " . fnamemodify (root, ":h")
      return 1
   endif
   return 0
endfunction

function! FindGitRoot ()
   let root = FindUpTreeFrom("/.git", expand ("%:p:h"))
   if isdirectory (root)
      exec "silent lcd " . fnamemodify (root, ":h")
      return 1
   endif
  return 0
endfunction

" vim:shiftwidth=4:ts=4
