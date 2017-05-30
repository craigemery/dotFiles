if v:version < 700
  " module uses readlfile()!!!!
  finish
endif

if !exists("built_version_control_menu")
  let built_version_control_menu = 1
else
  aunmenu CVS
endif

if !exists("g:cvs_command")
  let g:cvs_command="cvs"
endif

function! CVS_post (thecom)
  autocmd! BufLeave comment.txt
  let commentfile = "comment.txt"
  execute "bdelete! " . bufnr(bufname (commentfile))
  if filereadable(commentfile)
    let comments = []
    for line in readfile(commentfile)
      if line !~ '^#'
        let comments += [line]
      endif
    endfor
    call delete(commentfile)
    if !empty(comments)
      call writefile(comments, commentfile)
      call system(g:cvs_command . " " . a:thecom . " -F " . commentfile . " " . g:cofilename)
      call delete(commentfile)
    endif
    unlet comments
  endif
  unlet commentfile
endfunction

function! CVS_comment (filename, funname)
  let success=0
  if filereadable ("comment.txt")
	let success=delete ("comment.txt")
  endif
  if (0 == success)
	split comment.txt
        setlocal nobuflisted
        setlocal noswapfile
	resize 10
	setlocal ft=sh
	let @"="#Please supply your comments here\n#Lines starting with '#' are removed, quit this window without saving to abort the checkin"
	put! "
	normal G
        setlocal modified!
	let g:cofilename = a:filename
	execute "autocmd BufLeave comment.txt call CVS_post (\"" . a:funname . "\")"
  endif
endfunction

function! CVS_update (...)
  let cwd=getcwd()
  lcd %:p:h
  if a:0 == 0
	let lines = system (g:cvs_command . " update -Pd " . expand ("%:p:t"))
  else
	let lines = system (g:cvs_command . " update -Pd .")
  endif
  exec "lcd " . cwd
  edit!
  unlet cwd
endfunction

function! CVS_fresh (...)
  let cwd=getcwd()
  lcd %:p:h
  if a:0 == 0
	let f = expand ("%:p:t")
        call delete (f)
	call system (g:cvs_command . " update -Pd " . f)
        unlet f
        edit!
  else
	call system (g:cvs_command . " update -Pd .")
  endif
  exec "lcd " . cwd
  edit!
  unlet cwd
endfunction

"function! CVS_co_unres ()
"  let f = expand ("%:p")
"  call CVS_comment (f, "checkout -unreserved")
"endfunction

function! CVS_ci ()
  let cwd=getcwd()
  if a:0 == 0
	call CVS_comment (escape(expand ("%:p"), ' \'), "commit")
  else
	call CVS_comment (a:1, "commit")
  endif
endfunction

function! CVS_mkelem ()
  let cwd=getcwd()
  lcd %:p:h
  execute "!" . g:cvs_command . " add " . expand ("%")
  exec "lcd " . cwd
  unlet cwd
endfunction

"function! CVS_ls ()
"  cd %:p:h
"  execute "!cleartool ls -long " . expand ("%")
"  cd -
"endfunction

"function! CVS_lsco (...)
"  let cmd = "!cleartool lscheckout"
"  let idx = 1
"  while idx <= a:0
"	execute "let arg = a:" . idx
"	let cmd = cmd . " " . arg
"	let idx = idx + 1
"  endwhile
"  if has ("win32")
"	execute cmd . " | more"
"  elseif has ("unix")
"	execute cmd . " | " . $PAGER
"  endif
"endfunction

"function! CVS_unco ()
"  cd %:p:h
"  let f = expand ("%")
"  let choice=confirm("Save private copy of \"" . f . "\"?", "&Yes\n&No", 2, "Question")
"  if choice == 1
"	let keep = "-keep "
"  else
"	let keep = "-rm "
"  endif
"  let lines = system ("cleartool uncheckout " . keep . f)
"  cd -
"endfunction

function! CVS_diff (what, how)
  let cwd=getcwd()
  if a:what == "dir"
    new
    setlocal modifiable
    setlocal noswapfile
    setlocal buftype=nofile
    setlocal filetype=diff
    echo "Running CVS diff on current directory"
    lcd #:p:h
    exec "silent r!" . g:cvs_command . " diff"
    exec "silent file Differences\\ in\\ all\\ files"
    setlocal modified!
    setlocal nobuflisted
    normal 1G
    exec "lcd " . cwd
  else
    if a:how == "xxdiff"
      let b:dir=expand("%:p:h")
      let b:file=expand ("%:p:t")
      echo "Running CVS diff (using xxdiff) on current file"
      exec "silent !bash -c 'orphan cvsdiff -w " . b:file . " ; exit 0'"
    else
      new
      setlocal modifiable
      setlocal noswapfile
      setlocal filetype=diff
      let b:dir=expand("#:p:h")
      let b:file=expand ("#:p:t")
      lcd #:p:h
      echo "Running CVS diff on " . b:file . " (in directory " . b:dir . ")"
      exec "silent r!" . g:cvs_command . " diff " . b:file
      exec "lcd " . cwd
      exec "silent file Differences\\ in\\ " . b:file
      setlocal buftype=nofile
      setlocal modified!
      setlocal nobuflisted
      normal 1G
    endif
    unlet b:dir
    unlet b:file
  endif
  unlet cwd
endfunction

function! CVS_history ()
  new
  setlocal modifiable
  setlocal noswapfile
  setlocal buftype=nofile
  let cwd=getcwd()
  let b:file=expand ("#:p:t")
  lcd #:p:h
  exec "silent r!" . g:cvs_command . " status -v " . b:file
  exec "silent r!" . g:cvs_command . " annotate " . b:file
  exec "lcd " . cwd
  exec "silent file History\\ of\\ " . expand ("#")
  setlocal modified!
  setlocal nobuflisted
  normal 1G
  unlet cwd
  unlet b:file
endfunction

amenu 100 C&VS.&Update\ current\ file :call CVS_update()<CR>
amenu 100 C&VS.Fetch\ &Fresh\ copy\ of\ current\ file :call CVS_fresh()<CR>
amenu 100 C&VS.Check\ &in\ current\ file :call CVS_ci()<CR><CR>:e!<CR>
"amenu 100 C&VS.&Undo\ Check\ out\ current\ file :call CVS_unco()<CR><CR>:e!<CR>
"amenu 100 C&VS.Check\ out\ current\ file\ un&reserved :call CVS_co_unres()<CR>:e!<CR><CR><C-G>
""amenu 100 C&VS.Check\ out\ current\ file's\ &directory :call CVS_co (expand ("%:p:h"))<CR>
"amenu 100 C&VS.Check\ In\ current\ file's\ director&y :!cleartool checkin %:p:h<CR><CR>:e!<CR><C-G>
amenu 100 C&VS.Make\ &New\ Element\ from\ current\ file :call CVS_mkelem()<CR><CR>:e!<CR>
"amenu 100 C&VS.List\ &My\ checked\ out\ files :call CVS_lsco ("-recurse", "-me")<CR>
"amenu 100 C&VS.List\ &All\ checked\ out\ files :call CVS_ls ("-recurse")<CR>
amenu 100 C&VS.&Compare\ This\ File\ with\ the\ CVS\ version :call CVS_diff("currentfile", "CVS")<CR>
amenu 100 C&VS.Compare\ This\ File\ with\ the\ CVS\ version\ (use\ &xxdiff) :call CVS_diff("currentfile", "xxdiff")<CR>
amenu 100 C&VS.Compare\ &All\ Files\ with\ the\ CVS\ versions :call CVS_diff("dir", "CVS")<CR>
amenu 100 C&VS.Show\ &History\ of\ current\ file :call CVS_history()<CR>
amenu 100 C&VS.Show\ &History\ of\ current\ file :call CVS_history()<CR>
"amenu 100 C&VS.&List\ Details\ of\ current\ file :call CVS_ls()<CR>
"amenu 100 C&VS.-SEP1- :
"amenu 100 C&VS.Cleartool\ &Shell :!cleartool<CR>

function! CVS_checkItIn (comment)
  let cwd=getcwd()
  lcd %:p:h
  call system(g:cvs_command . " ci -m '" . a:comment . "' " . expand("%:p:t"))
  exec "lcd " . cwd
endfunction

amenu 100.999 C&VS.&Pre-filled\ Checkins."&oops" :call CVS_checkItIn("oops")<CR><C-G>
amenu 100.999 C&VS.&Pre-filled\ Checkins."&reduced\ verbosity\ of\ some\ diagnostics" :call CVS_checkItIn("reduced the verbosity of some diagnostics")<CR><C-G>
amenu 100.999 C&VS.&Pre-filled\ Checkins."fixed\ compiler\ &warnings" :call CVS_checkItIn("fixed compiler warnings")<CR><C-G>
amenu 100.999 C&VS.&Pre-filled\ Checkins."white\ &space" :call CVS_checkItIn("extraneous white space removed")<CR><C-G>

" vim:shiftwidth=2
