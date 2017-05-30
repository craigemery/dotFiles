if !exists("built_pmake_menu")
  let built_pmake_menu = 1
else
  aunmenu Pmake
endif

function! OpenCurrentPmakeFile()
  let pmake = expand ("%:p:h") . "/" . expand ("%:p:h:t") . ".pmake"
  if filereadable(pmake)
    exec "edit " . pmake
  else
    let choice = confirm (":edit " . pmake . " failed!", "Oh")
  endif
endfunction

function! OpenParentPmakeFile()
  let pmake = expand ("%:p:h:h") . "/" . expand ("%:p:h:h:t") . ".pmake"
  if filereadable(pmake)
    exec "edit " . pmake
  else
    let choice = confirm (":edit " . pmake . " failed!", "Oh")
  endif
endfunction

amenu 100.10 &Pmake.Open\ pmake\ file\ in\ &current\ directory :call OpenCurrentPmakeFile ()<CR>
amenu 100.20 &Pmake.Open\ pmake\ file\ in\ &parent\ directory :call OpenParentPmakeFile ()<CR>

function! SetPmakeDebugLevel(level)
  if a:level == "silent"
    let $T4PMDEBUGLEVEL = a:level
  elseif a:level == "error"
    let $T4PMDEBUGLEVEL = a:level
  elseif a:level == "warn"
    let $T4PMDEBUGLEVEL = a:level
  elseif a:level == "info"
    let $T4PMDEBUGLEVEL = a:level
  elseif a:level == "verbose"
    let $T4PMDEBUGLEVEL = a:level
  elseif a:level == "annoy"
    let $T4PMDEBUGLEVEL = a:level
  endif
  echo "$T4PMDEBUGLEVEL is now " . $T4PMDEBUGLEVEL
endfunction

amenu 100.30.10 &Pmake.debug_&level.&silent :call SetPmakeDebugLevel ("silent")<CR>
amenu 100.30.20 &Pmake.debug_&level.&error :call SetPmakeDebugLevel ("error")<CR>
amenu 100.30.30 &Pmake.debug_&level.&warn :call SetPmakeDebugLevel ("warn")<CR>
amenu 100.30.40 &Pmake.debug_&level.&info :call SetPmakeDebugLevel ("info")<CR>
amenu 100.30.50 &Pmake.debug_&level.&verbose :call SetPmakeDebugLevel ("verbose")<CR>
amenu 100.30.60 &Pmake.debug_&level.&annoy :call SetPmakeDebugLevel ("annoy")<CR>

function! SetPmakeDebugVia(via)
  if a:via == "output"
    let $T4PMDEBUGVIA = a:via
  elseif a:via == "file"
    let $T4PMDEBUGVIA = a:via
  elseif a:via == "socket"
    let $T4PMDEBUGVIA = a:via
  endif
  echo "$T4PMDEBUGVIA is now " . $T4PMDEBUGVIA
endfunction

amenu 100.40.10 &Pmake.debug_&via.&output :call SetPmakeDebugVia ("output")<CR>
amenu 100.40.20 &Pmake.debug_&via.&file :call SetPmakeDebugVia ("file")<CR>
amenu 100.40.30 &Pmake.debug_&via.&socket :call SetPmakeDebugVia ("socket")<CR>

function! SetPmakeStyle(style)
  if a:style == "dbg"
    let $T4PMSTYLE = a:style
  elseif a:style == "rel"
    let $T4PMSTYLE = a:style
  endif
  echo "$T4PMSTYLE is now " . $T4PMSTYLE
endfunction

amenu 100.50.10 &Pmake.&style.&dbg :call SetPmakeStyle ("dbg")<CR>
amenu 100.50.20 &Pmake.&style.&rel :call SetPmakeStyle ("rel")<CR>

function! SetPmakeTesting(testing)
  if a:testing == "ptest"
    let $T4PMTESTING = a:testing
  elseif a:testing == "ntest"
    let $T4PMTESTING = a:testing
  endif
  echo "$T4PMTESTING is now " . $T4PMTESTING
endfunction

amenu 100.60.10 &Pmake.&testing.&ptest :call SetPmakeTesting ("ptest")<CR>
amenu 100.60.20 &Pmake.&testing.&ntest :call SetPmakeTesting ("ntest")<CR>

function! SetPmakeTrackMem(track)
  if a:track == "tm"
    let $T4PMTRACKMEM = a:track
  elseif a:track == "ntm"
    let $T4PMTRACKMEM = a:track
  endif
  echo "$T4PMTRACKMEM is now " . $T4PMTRACKMEM
endfunction

amenu 100.70.10 &Pmake.&trackmem.&tm :call SetPmakeTrackMem ("tm")<CR>
amenu 100.70.20 &Pmake.&trackmem.&ntm :call SetPmakeTrackMem ("ntm")<CR>

function! SetPbuildVariety(var)
  if a:var == "REL"
    call SetPmakeDebugLevel("silent")
    call SetPmakeDebugVia("output")
    call SetPmakeStyle("rel")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("ntm")
  elseif a:var == "DBG"
    call SetPmakeDebugLevel("info")
    call SetPmakeDebugVia("output")
    call SetPmakeStyle("dbg")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("ntm")
  elseif a:var == "CHATTY"
    call SetPmakeDebugLevel("info")
    call SetPmakeDebugVia("file")
    call SetPmakeStyle("rel")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("ntm")
  elseif a:var == "PROTEST"
    call SetPmakeDebugLevel("info")
    call SetPmakeDebugVia("output")
    call SetPmakeStyle("rel")
    call SetPmakeTesting("ptest")
    call SetPmakeTrackMem("ntm")
  elseif a:var == "REL-TRACKMEM"
    call SetPmakeDebugLevel("silent")
    call SetPmakeDebugVia("output")
    call SetPmakeStyle("rel")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("tm")
  elseif a:var == "DBG-TRACKMEM"
    call SetPmakeDebugLevel("info")
    call SetPmakeDebugVia("output")
    call SetPmakeStyle("dbg")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("tm")
  elseif a:var == "CHATTY-TRACKMEM"
    call SetPmakeDebugLevel("info")
    call SetPmakeDebugVia("file")
    call SetPmakeStyle("rel")
    call SetPmakeTesting("ntest")
    call SetPmakeTrackMem("tm")
  endif
endfunction

amenu 100.999.10 &Pmake.&Varieties.&REL :call SetPbuildVariety("REL")<CR>
amenu 100.999.20 &Pmake.&Varieties.&DBG :call SetPbuildVariety("DBG")<CR>
amenu 100.999.30 &Pmake.&Varieties.&CHATTY :call SetPbuildVariety("CHATTY")<CR>
amenu 100.999.40 &Pmake.&Varieties.&PROTEST :call SetPbuildVariety("PROTEST")<CR>
amenu 100.999.50 &Pmake.&Varieties.&REL-TRACKMEM :call SetPbuildVariety("REL-TRACKMEM")<CR>
amenu 100.999.60 &Pmake.&Varieties.&DBG-TRACKMEM :call SetPbuildVariety("DBG-TRACKMEM")<CR>
amenu 100.999.70 &Pmake.&Varieties.&CHATTY-TRACKMEM :call SetPbuildVariety("CHATTY-TRACKMEM")<CR>

" vim:shiftwidth=2
