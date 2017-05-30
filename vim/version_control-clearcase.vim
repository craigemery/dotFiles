if !exists("built_version_control_menu")
  let built_version_control_menu = 1
else
  aunmenu Version\ Control
endif

function! CT_post (thecom)
  autocmd! BufLeave comment.txt
  let bnum = bufnr (bufname ("comment.txt"))
  let text=""
  let ln = 1
  let lns = line("$")
  while ln <= lns
	let thisln = getline(ln)
	if 0 != match (thisln, "^#")
	  let text = text . thisln . "\n"
	endif
	let ln = ln + 1
  endwhile
" echo "text = " . text
  execute "bdelete! " . bnum
  if filereadable ("comment.txt")
	let lines = system ("cleartool " . a:thecom . " -cfile comment.txt " . g:cofilename)
	let success=delete ("comment.txt")
  endif
endfunction

function! CT_comment (filename, funname)
  let success=0
  if filereadable ("comment.txt")
	let success=delete ("comment.txt")
  endif
  if (0 == success)
	sp comment.txt
	resize 10
	set ft=sh
	let @f="#Please supply your comments here"
	put! f
	normal 2G
	let g:cofilename = a:filename
	execute "autocmd BufLeave comment.txt call CT_post (\"" . a:funname . "\")"
  endif
endfunction

function! CT_co (...)
  if a:0 == 0
	let f = expand ("%:p")
	call CT_comment (f, "checkout")
  else
	call CT_comment (a:1, "checkout")
  endif
endfunction

function! CT_co_unres ()
  let f = expand ("%:p")
  call CT_comment (f, "checkout -unreserved")
endfunction

function! CT_ci ()
  cd %:p:h
  execute "!cleartool checkin " . expand ("%")
  cd -
endfunction

function! CT_mkelem ()
  cd %:p:h
  execute "!cleartool mkelem -ci -ptime " . expand ("%")
  cd -
endfunction

function! CT_ls ()
  cd %:p:h
  execute "!cleartool ls -long " . expand ("%")
  cd -
endfunction

function! CT_lsco (...)
  let cmd = "!cleartool lscheckout"
  let idx = 1
  while idx <= a:0
	execute "let arg = a:" . idx
	let cmd = cmd . " " . arg
	let idx = idx + 1
  endwhile
  if has ("win32")
	execute cmd . " | more"
  elseif has ("unix")
	execute cmd . " | " . $PAGER
  endif
endfunction

function! CT_unco ()
  cd %:p:h
  let f = expand ("%")
  let choice=confirm("Save private copy of \"" . f . "\"?", "&Yes\n&No", 2, "Question")
  if choice == 1
	let keep = "-keep "
  else
	let keep = "-rm "
  endif
  let lines = system ("cleartool uncheckout " . keep . f)
  cd -
endfunction

amenu 80 &Version\ Control.Check\ &out\ current\ file :call CT_co()<CR>
amenu 80 &Version\ Control.Check\ &in\ current\ file :call CT_ci()<CR><CR>:e!<CR>
amenu 80 &Version\ Control.&Undo\ Check\ out\ current\ file :call CT_unco()<CR><CR>:e!<CR>
amenu 80 &Version\ Control.Check\ out\ current\ file\ un&reserved :call CT_co_unres()<CR>:e!<CR><CR><C-G>
amenu 80 &Version\ Control.Check\ out\ current\ file's\ &directory :call CT_co (expand ("%:p:h"))<CR>
amenu 80 &Version\ Control.Check\ In\ current\ file's\ director&y :!cleartool checkin %:p:h<CR><CR>:e!<CR><C-G>
amenu 80 &Version\ Control.Make\ &New\ Element\ from\ current\ file :call CT_mkelem()<CR><CR>:e!<CR>
amenu 80 &Version\ Control.List\ &My\ checked\ out\ files :call CT_lsco ("-recurse", "-me")<CR>
amenu 80 &Version\ Control.List\ &All\ checked\ out\ files :call CT_ls ("-recurse")<CR>
amenu 80 &Version\ Control.&Compare\ This\ File\ with\ the\ Previous\ version :!cleartool diff -predecessor -graphical %<CR>
if has("unix")
amenu 80 &Version\ Control.Show\ &History\ of\ current\ file :!xterm -iconic -e cleartool lshistory -graphical %<CR>
elseif has("win32")
amenu 80 &Version\ Control.Show\ &History\ of\ current\ file :!cleartool lshistory -graphical %<CR>
endif
amenu 80 &Version\ Control.&List\ Details\ of\ current\ file :call CT_ls()<CR>
amenu 80 &Version\ Control.-SEP1- :
amenu 80 &Version\ Control.Cleartool\ &Shell :!cleartool<CR>

" vim:shiftwidth=2
