function! OpenFilesMate()
  let suffix = expand ("%:e")
  let head = expand ("%:p:r")
  let incdir = expand ("%:p:h:h") . "/inc"
  let srcdir = expand ("%:p:h:h") . "/src"
  let inchead = incdir . "/" . expand ("%:p:t:r")
  let srchead = srcdir . "/" . expand ("%:p:t:r")
  let editing = 0
  let goaway = 0

  if suffix ==? "cpp" || suffix ==? "c" || suffix ==? "cc"
    let file_h = head . ".h"
    let file_hh = head . ".hh"
    let file_H = head . ".H"
    let file_hpp = head . ".hpp"
    let file_HPP = head . ".hpp"
    let file_l = head . ".l"

    let incfile_h = inchead . ".h"
    let incfile_hh = inchead . ".hh"
    let incfile_H = inchead . ".H"
    let incfile_hpp = inchead . ".hpp"
    let incfile_HPP = inchead . ".hpp"
    let incfile_l = inchead . ".l"

    if bufexists (bufname (file_h))
      exec ":buffer " . file_h
    elseif filereadable (file_h)
      exec ":edit " . file_h
    elseif bufexists (bufname (file_hh))
      exec ":buffer " . file_hh
    elseif filereadable (file_hh)
      exec ":edit " . file_hh
    elseif bufexists (bufname (file_H))
      exec ":buffer " . file_H
    elseif filereadable (file_H)
      exec ":edit " . file_H
    elseif bufexists (bufname (file_hpp))
      exec ":buffer " . file_hpp
    elseif filereadable (file_hpp)
      exec ":edit " . file_hpp
    elseif bufexists (bufname (file_HPP))
      exec ":buffer " . file_HPP
    elseif filereadable (file_HPP)
      exec ":edit " . file_HPP
    elseif bufexists (bufname (file_l))
      exec ":buffer " . file_l
    elseif filereadable (file_l)
      exec ":edit " . file_l
    elseif bufexists (bufname (incfile_h))
      exec ":buffer " . incfile_h
    elseif filereadable (incfile_h)
      exec ":edit " . incfile_h
    elseif bufexists (bufname (incfile_hh))
      exec ":buffer " . incfile_hh
    elseif filereadable (incfile_hh)
      exec ":edit " . incfile_hh
    elseif bufexists (bufname (incfile_H))
      exec ":buffer " . incfile_H
    elseif filereadable (incfile_H)
      exec ":edit " . incfile_H
    elseif bufexists (bufname (incfile_hpp))
      exec ":buffer " . incfile_hpp
    elseif filereadable (incfile_hpp)
      exec ":edit " . incfile_hpp
    elseif bufexists (bufname (incfile_HPP))
      exec ":buffer " . incfile_HPP
    elseif filereadable (incfile_HPP)
      exec ":edit " . incfile_HPP
    elseif bufexists (bufname (incfile_l))
      exec ":buffer " . incfile_l
    elseif filereadable (incfile_l)
      exec ":edit " . incfile_l
    else
      if filewritable (incdir)
	let choice = confirm ("Would you like to create " . incfile_hpp . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	if choice == 3
	  let goaway = 1
	elseif choice == 1
	  exec ":edit " . incfile_hpp
	  let editing = 1
	elseif choice == 2
	  let choice = confirm ("Would you like to create " . incfile_h . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	  if choice == 3
	    let goaway = 1
	  elseif choice == 1
	    exec ":edit " . incfile_h
	    let editing = 1
	  endif
	endif
      endif
      if goaway != 1 && editing != 1
	let choice = confirm ("Would you like to create " . file_hpp . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	if choice == 3
	  let goaway = 1
	elseif choice == 1
	  exec ":edit " . file_hpp
	  let editing = 1
	elseif choice == 2
	  let choice = confirm ("Would you like to create " . file_h . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	  if choice == 3
	    let goaway = 1
	  elseif choice == 1
	    exec ":edit " . file_h
	    let editing = 1
	  endif
	endif
      endif
    endif
  elseif suffix ==? "h" || suffix ==? "hpp" || suffix ==? "hh" || suffix ==? "l"
    let file_y = head . ".y"
    let file_cpp = head . ".cpp"
    let file_CPP = head . ".cpp"
    let file_c = head . ".c"
    let file_C = head . ".C"
    let file_cc = head . ".cc"
    let file_CC = head . ".CC"
    let srcfile_y = srchead . ".y"
    let srcfile_cpp = srchead . ".cpp"
    let srcfile_CPP = srchead . ".cpp"
    let srcfile_c = srchead . ".c"
    let srcfile_C = srchead . ".C"
    let srcfile_cc = srchead . ".cc"
    let srcfile_CC = srchead . ".CC"

    if bufexists (bufname (file_y))
      exec ":buffer " . file_y
    elseif filereadable (file_y)
      exec ":edit " . file_y
    elseif bufexists (bufname (file_cpp))
      exec ":buffer " . file_cpp
    elseif filereadable (file_cpp)
      exec ":edit " . file_cpp
    elseif bufexists (bufname (file_CPP))
      exec ":buffer " . file_CPP
    elseif filereadable (file_CPP)
      exec ":edit " . file_CPP
    elseif bufexists (bufname (file_c))
      exec ":buffer " . file_c
    elseif filereadable (file_c)
      exec ":edit " . file_c
    elseif bufexists (bufname (file_C))
      exec ":buffer " . file_C
    elseif filereadable (file_C)
      exec ":edit " . file_C
    elseif bufexists (bufname (file_cc))
      exec ":buffer " . file_cc
    elseif filereadable (file_cc)
      exec ":edit " . file_cc
    elseif bufexists (bufname (file_CC))
      exec ":buffer " . file_CC
    elseif filereadable (file_CC)
      exec ":edit " . file_CC
    elseif bufexists (bufname (srcfile_y))
      exec ":buffer " . srcfile_y
    elseif filereadable (srcfile_y)
      exec ":edit " . srcfile_y
    elseif bufexists (bufname (srcfile_cpp))
      exec ":buffer " . srcfile_cpp
    elseif filereadable (srcfile_cpp)
      exec ":edit " . srcfile_cpp
    elseif bufexists (bufname (srcfile_CPP))
      exec ":buffer " . srcfile_CPP
    elseif filereadable (srcfile_CPP)
      exec ":edit " . srcfile_CPP
    elseif bufexists (bufname (srcfile_c))
      exec ":buffer " . srcfile_c
    elseif filereadable (srcfile_c)
      exec ":edit " . srcfile_c
    elseif bufexists (bufname (srcfile_C))
      exec ":buffer " . srcfile_C
    elseif filereadable (srcfile_C)
      exec ":edit " . srcfile_C
    elseif bufexists (bufname (srcfile_cc))
      exec ":buffer " . srcfile_cc
    elseif filereadable (srcfile_cc)
      exec ":edit " . srcfile_cc
    elseif bufexists (bufname (srcfile_CC))
      exec ":buffer " . srcfile_CC
    elseif filereadable (srcfile_CC)
      exec ":edit " . srcfile_CC
    else
      if filewritable (srcdir)
	let choice = confirm ("Would you like to create " . srcfile_cpp . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	if choice == 3
	  let goaway = 1
	elseif choice == 1
	  exec ":edit " . srcfile_cpp
	  let editing = 1
	elseif choice == 2
	  let choice = confirm ("Would you like to create " . srcfile_c . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	  if choice == 3
	    let goaway = 1
	  elseif choice == 1
	    exec ":edit " . srcfile_c
	    let editing = 1
	  endif
	endif
      endif
      if goaway != 1 && editing != 1
	let choice = confirm ("Would you like to create " . file_cpp . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	if choice == 3
	  let goaway = 1
	elseif choice == 1
	  exec ":edit " . file_cpp
	  let editing = 1
	elseif choice == 2
	  let choice = confirm ("Would you like to create " . file_c . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
	  if choice == 3
	    let goaway = 1
	  elseif choice == 1
	    exec ":edit " . file_c
	    let editing = 1
	  endif
	endif
      endif
    endif
  elseif suffix ==? "y"
    let file_c = head . ".c"

    if bufexists (bufname (file_c))
      exec ":buffer " . file_c
    elseif filereadable (file_c)
      exec ":edit " . file_c
    endif

  elseif suffix ==? "py"
    let file_pmake = head . ".pmake"
    if bufexists (bufname (file_pmake))
      exec ":buffer " . file_pmake
    elseif filereadable (file_pmake)
      exec ":edit " . file_pmake
    else
      let choice = confirm ("Would you like to create " . file_pmake . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
      if choice == 3
        let goaway = 1
      elseif choice == 1
        exec ":edit " . file_pmake
        let editing = 1
      endif
    endif

  elseif suffix ==? "pmake"
    let file_py = head . ".py"
    if bufexists (bufname (file_py))
      exec ":buffer " . file_py
    elseif filereadable (file_py)
      exec ":edit " . file_py
    else
      let choice = confirm ("Would you like to create " . file_py . "?", "&Yes Please\n&No Way\n&Go Away!", "Q")
      if choice == 3
        let goaway = 1
      elseif choice == 1
        exec ":edit " . file_py
        let editing = 1
      endif
    endif

  elseif suffix ==? "mk"
    let head = expand ("%:p:h")
    let tail = expand ("%:p:t")
    let _vars = "vars.mk"
    let file_vars =  head . "/" . _vars
    let _targets = "targets.mk"
    let file_targets = head . "/" . _targets
    if tail == _targets
      if bufexists (bufname (file_vars))
	exec ":buffer " . file_vars
      elseif filereadable (file_vars)
	exec ":edit " . file_vars
      elseif filewritable (head)
        let choice = confirm ("Would you like to create " . file_vars . "?", "&Yes Please\n&No Way", "Q")
        if choice == 1
          exec ":edit " . file_targets
        endif
      endif
    elseif tail == _vars
      if bufexists (bufname (file_targets))
	exec ":buffer " . file_targets
      elseif filereadable (file_targets)
	exec ":edit " . file_targets
      elseif filewritable (head)
        let choice = confirm ("Would you like to create " . file_targets . "?", "&Yes Please\n&No Way", "Q")
        if choice == 1
          exec ":edit " . file_targets
        endif
      endif
    endif

  endif

endfunction

map <Leader>o :call OpenFilesMate ()<CR>
amenu 90.10 &Craig.&Open\ current\ file's\ mate :call OpenFilesMate ()<CR>

function! FindFilesMate (thecom)
    let suffix = expand ("%:e")
    let target = ""
    if suffix ==? "cpp"
        let target = "hpp"
    elseif suffix ==? "c"
        let target = "h"
    elseif suffix ==? "cc"
        let target = "hpp"
    elseif suffix ==? "hpp"
        let target = "cpp"
    elseif suffix ==? "h"
        let target = "c"
    endif

    if target != ""
        exec ":" . a:thecom . " " . expand ("%:t:r") . "." . target
    endif
endfunction

map <Leader>f :call FindFilesMate ("find")<CR>
amenu 90.15 &Craig.&Find\ current\ file's\ mate :call FindFilesMate ("find")<CR>
map <Leader><S-f> :call FindFilesMate ("bel sfind")<CR>
amenu 90.16 &Craig.Find\ current\ file's\ mate\ (and\ &split\ the\ current\ window) :call FindFilesMate ("bel sfind")<CR>
