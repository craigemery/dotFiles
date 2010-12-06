" Change searching behaviour

function! Toggle_ic()
   set ic!
   if &ic
      echo "Searches will now ignore case"
   else
      echo "Searches will now respect case"
   endif
endfunction

map <M-?> :call Toggle_ic()<CR>
map <Esc>? :call Toggle_ic()<CR>

function! Toggle_hls()
   set hls!
   if &hls
      echo "Searches will now be hilitied"
   else
      echo "Searches will now NOT be hilitied"
   endif
endfunction

"map <M-/> :call Toggle_hls()<CR>

map <M-/> :let @/=""<CR><C-G>
map <Esc>/ :let @/=""<CR><C-G>

function! Toggle_CentreSearches()
   if !exists("g:centresearches")
      let g:centresearches = 1
      noremap n nzz
      noremap N Nzz
      noremap * *zz
      noremap # #zz
      echo "Searches will now auto-centre"
   else
      unlet g:centresearches
      unmap n
      unmap N
      unmap *
      unmap #
      echo "Searches will no longer auto-centre"
   endif
endfunction

map <Leader>/ :call Toggle_CentreSearches()<CR>

function! Cycle_CentreSearches()
   if !exists("g:search_style")
      let g:search_style = 1 " centre
      noremap n nzz
      noremap N Nzz
      noremap * *zz
      noremap # #zz
      echo "Searches will now auto-centre"
   elseif g:search_style == 1
      let g:search_style = 2 " top
      noremap n nzt
      noremap N Nzt
      noremap * *zt
      noremap # #zt
      echo "Searches will now auto-'top'"
   else
      unlet g:search_style
      unmap n
      unmap N
      unmap *
      unmap #
      echo "Searches will behave normally"
   endif
endfunction

map <Leader>? :call Cycle_CentreSearches()<CR>

function! FiF(pattern, files)
   let @/ = a:pattern
   if exists("g:PerforceSetUp") && ! ToggleP4P4IsDisabled()
      let g:reenableP4 = 1
      call ToggleP4DisableP4()
      "echo "Perforce disabled"
   endif
   exec "lvimgrep! /" . a:pattern . "/gj " . a:files
   if exists("g:reenableP4")
      unlet g:reenableP4
      call ToggleP4EnableP4()
      "echo "Perforce enabled"
   endif
endfunction

function! FiFI(pattern, files)
   return FiF("\\c".a:pattern, a:files)
endfunction

function! FiSrc(pattern)
   "call FiF(a:pattern, "**/*.[ch] **/*.[ch]pp **/*.py **/*.inl **/*.pmake **/*.*rb **/*.yml **/*.rhtml **/*.js **/*.erb")
   call FiF(a:pattern, "**/*.[ch] **/*.[ch]pp **/*.py **/*.*rb **/*.yml **/*.rhtml **/*.js **/*.erb **/*.m")
endfunction

function! FiSrcI(pattern)
   call FiSrc("\\c".a:pattern)
endfunction

function! FiVim(pattern)
   call FiF(a:pattern, "**/*.vim")
endfunction

function! FiVimI(pattern)
   call FiF("\\c".a:pattern, "**/*.vim")
endfunction

map <Leader>*s *:silent cal FiSrc(@/)<CR>
map <Leader>*S *:silent cal FiSrcI(@/)<CR>
map <Leader>*v *:silent cal FiVim(@/)<CR>
map <Leader>*V *:silent cal FiVimI(@/)<CR>
map <Leader>** *:silent cal FiF(@/, "**/*")<CR>

command! -nargs=1 FiSrc silent call FiSrc(<f-args>)
command! -nargs=+ FiF silent call FiF(<f-args>)
command! -nargs=+ FiVim silent call FiVim(<f-args>)
command! -nargs=1 FiSrcI silent call FiSrcI(<f-args>)
command! -nargs=+ FiFI silent call FiFI(<f-args>)
command! -nargs=+ FiVimI silent call FiVimI(<f-args>)
