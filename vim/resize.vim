" Resizing the window

function! Make_wider()
  exec "set columns+=" . 10
endfunction

map <Leader>w :call Make_wider()<CR>

function! Make_thinner()
  exec "set columns-=" . 10
endfunction

map <Leader>t :call Make_thinner()<CR>

function! Make_higher()
  exec "set lines+=" . 10
endfunction

map <Leader>h :call Make_higher()<CR>

function! Make_shorter()
  exec "set lines-=" . 10
endfunction

map <Leader>s :call Make_shorter()<CR>
