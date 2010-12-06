if !exists("built_craig_menu")
  let built_craig_menu = 1
else
  aunmenu Craig
endif

function! Delete_object ()
  chdir %:p:h
  let obj="Debug/" . expand ("%:p:t:r") . ".o"
  if filereadable (obj)
    let success=delete (obj)
  else
    echo "Object file " . obj . " doesn't exist so I can't delete it for you"
  endif
  chdir -
endfunction

function! Strip_ws ()
  %s@[ 	]\{1,\}$@@g
endfunction

function! Strip_bl ()
  normal 1G
  g@/^$/.,/./-1j
endfunction

function! InsertFileName ()
  normal a""
endfunction

function! Toggle_wide_78 ()
  if &columns != 78
    let g:prev_columns=&columns
    set columns=78
  else
    exec "set columns=" . g:prev_columns
  endif
endfunction

if has("unix")
  amenu 90.20 &Craig.Make\ this\ file\ &executable :!chmod a+x "%"<CR>:e!<CR>
  amenu 90.30 &Craig.Make\ this\ file\ &writeable :!chmod a+w "%"<CR>:e!<CR>
  amenu 90.40 &Craig.Make\ this\ file\ &read-only :!chmod a-w "%"<CR>:e!<CR>
endif

function! GetCwdString ()
  return substitute(getcwd(),"\\", "&&", "g")
endfunction

function! ShowCwd ()
  exec ":echo \"current working directory is '".GetCwdString ()."'\""
endfunction

amenu 90.50 &Craig.&CD\ to\ current\ file's\ parent\ directory :chdir %:p:h<CR>:call ShowCwd ()<CR>

amenu 90.60 &Craig.&Navigate\ the\ current\ file's\ parent\ directory :edit %:p:h<CR><C-G>

amenu 90.70 &Craig.&Source\ current\ file :source %<CR>

amenu 90.80 &Craig.Source\ Your\ \.&gvimrc\ file :source ~/.dotFiles/vim/.gvimrc<CR>:echo "Sourced your .gvimrc file"<CR>

amenu 90.90 &Craig.Source\ Your\ \.&vimrc\ file :source ~/.dotFiles/vim/.vimrc<CR>:echo "Sourced your .vimrc file"<CR>

amenu 90.100 &Craig.&Delete\ the\ object\ file\ for\ current\ source\ file :call Delete_object()<CR>

amenu 90.110 &Craig.&Remove\ extraneous\ white\ space :call Strip_ws()<CR>

amenu 90.120 &Craig.Toggle\ between\ &132\ and\ 78\ columns :call Toggle_wide_78()<CR>
map <M-1> :call Toggle_wide_78()<CR>

if has("unix")
  function! Save_Timestamp ()
    let lines=system ("timestamp --save " . expand ("%:p"))
  endfunction
  function! Restore_Timestamp ()
    let lines=system ("timestamp --restore " . expand ("%:p"))
    execute "edit!"
  endfunction
  function! Save_Same_Timestamp ()
    call Save_Timestamp ()
    execute "write"
    call Restore_Timestamp ()
  endfunction
  amenu 90.130 &Craig.Save\ File\'s\ Timestamp :call Save_Timestamp ()<CR>
  amenu 90.140 &Craig.Restore\ File\'s\ Timestamp :call Restore_Timestamp ()<CR>
  amenu 10.351 &File.Save\ \(Leave\ &Timestamp\ Unaffected\) :call Save_Same_Timestamp()<CR>

  map <C-F3> :call Save_Same_Timestamp ()<CR>

  function! DiffFile ()
    let other=input ("What's the name of other file? ")
    if "" != other
      new
      "exec "r!diff " . expand ("#:p") . " " . other
      exec "%!bash -c 'diff " . expand ("#") . " " . other . "; exit 0'"
      set filetype=diff
      set nomodified
    endif
  endfunction

  amenu 90.150 &Craig.Diff\ this\ file\ with\ another\ file :call DiffFile ()<CR>
  map <Esc>d :call DiffFile ()<CR>

  function! Age_Timestamp ()
    let lines=system ("timestamp --age " . expand ("%:p"))
  endfunction
  function! UnAge_Timestamp ()
    let lines=system ("timestamp --restore " . expand ("%:p"))
    execute "edit!"
  endfunction
  amenu 90.160 &Craig."&Age"\ File\'s\ Timestamp :call Age_Timestamp ()<CR>
  amenu 90.170 &Craig."&UnAge"\ File\'s\ Timestamp :call UnAge_Timestamp ()<CR>

  amenu 90.180 &Craig.cd\ to\ $T&4_HOME :call GotoT4 ()<CR>
endif

"amenu 90.150 &Craig.Remove\ extraneous\ &blank\ lines :call Strip_bl()<CR>

"amenu 90.160 &Craig.&Insert\ current\ file\ name :call InsertFileName ()<CR>

function! CppExpand ()
  let fname = expand ("%<") . "_E." . expand ("%:e")
  silent exec ":mak " . fname . " NODEPS=y"
  silent exec ":edit " . fname
endfunction

amenu 90.200 &Craig.Generate\ macro\ expanded\ version\ of\ current\ file :call CppExpand ()<CR>

function! CraigsFont (name, size)
  if a:name == "misc-fixed"
    if a:size == 12
      set guifont=-misc-fixed-medium-r-semicondensed-*-*-120-*-*-c-*-koi8-r
    endif
  elseif a:name == "lucinda-type"
    if a:size == 10
      set guifont=-b&h-lucidatypewriter-medium-r-normal-*-*-100-*-*-m-*-iso8859-1
    endif
  elseif a:name == "adobe-courier"
    if a:size == 9
      set guifont=-adobe-courier-medium-r-normal-*-*-90-*-*-m-*-iso8859-1
    endif
  endif
endfunction

amenu 90.210.10 &Craig.Set\ Your\ T&5\ Directory.&HEAD :call GotoT5("HEAD")<CR>:call ShowCwd ()<CR>
amenu 90.210.20 &Craig.Set\ Your\ T&5\ Directory.5\.&1\.x :call GotoT5("5.1.x")<CR>:call ShowCwd ()<CR>
amenu 90.210.30 &Craig.Set\ Your\ T&5\ Directory.5\.&2\.x :call GotoT5("5.2.x")<CR>:call ShowCwd ()<CR>
amenu 90.210.30 &Craig.Set\ Your\ T&5\ Directory.5\.&3\.1 :call GotoT5("5.3.1")<CR>:call ShowCwd ()<CR>
amenu 90.210.40 &Craig.Set\ Your\ T&5\ Directory.&6\.0\.0 :call GotoT5("6.0.0")<CR>:call ShowCwd ()<CR>

amenu 90.220.10 &Craig.&Launch\ New\ gvim :let lines=system("gvim")<CR><C-G>

amenu 90.999.10.10 &Craig.Favourite\ &Fonts.&Misc\ Fixed.&12\ point :call CraigsFont("misc-fixed", 12)<CR>
amenu 90.999.20.10 &Craig.Favourite\ &Fonts.&Lucinda\ Typewriter.&10\ point :call CraigsFont("lucinda-type", 10)<CR>
amenu 90.999.30.10 &Craig.Favourite\ &Fonts.&Adobe\ Courier.&9\ point :call CraigsFont("adobe-courier", 9)<CR>

autocmd InsertLeave * se nocul
autocmd InsertEnter * se cul

function! DiffFixAddresses()
  windo! silent exec "%s@0x0\\{8\\}@NULL@g"
  windo! silent exec "%s@0x\\x\\{6,8\\}@0xcafebabe@g"
endfunction

amenu 90.230 &Craig.Saniti&ze\ Addresses\ For\ Diff  :call DiffFixAddresses()<CR>

" vim:shiftwidth=2
