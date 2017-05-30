
set patchexpr=CygPatch()
function! CygPatch()
  :call system("c:\\util\\bin\\patch -o " . v:fname_out . " " . v:fname_in .
  \  " < " . v:fname_diff)
endfunction

set diffopt+=context:9999

command! DiffOrig vert new | set bt=nofile | r # | 0d_ | diffthis
	 	\ | wincmd p | diffthis

function! EnteredDiff()
   if &diff
      if ! exists("b:diffmappings")
         let b:diffmappings=1
         "echo "Diff key mappings enabled"
         map <M-S-Left> dp
         map <M-S-Right> do
         map <M-S-Up> [czz
         map <M-S-Down> ]czz
      endif
   endif
endfunction

function! LeavingDiff()
   if &diff
      if exists("b:diffmappings")
         "echo "Diff key mappings disabled"
         unlet b:diffmappings
         unmap <M-S-Left>
         unmap <M-S-Right>
         unmap <M-S-Up>
         unmap <M-S-Down>
      endif
   endif
endfunction

augroup MyDiff
autocmd! MyDiff
autocmd! MyDiff BufEnter * call EnteredDiff()
autocmd! MyDiff BufLeave * call LeavingDiff()
augroup end
