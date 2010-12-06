if !exists("built_qpmake_menu")
    let built_qpmake_menu = 1
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

function! FindPmakeFile()
    let pmake = expand ("%:p:h:h") . "/" . expand ("%:p:h:h:t") . ".pmake"
    if filereadable(pmake)
        exec "edit " . pmake
    else
        let choice = confirm (":edit " . pmake . " failed!", "Oh")
    endif
endfunction

function! SetPmakeStyle(style)
    if a:style == "dbg" ||
      \a:style == "rel"
        let $T5PMSTYLE = a:style
        echo "$T5PMSTYLE is now " . $T5PMSTYLE
    endif
endfunction

function! SetPmakeSDK(sdk)
    if a:sdk == "210" ||
      \a:sdk == "312"
        let $T5PMSDK = a:sdk
        echo "$T5PMSDK is now " . $T5PMSDK
    endif
endfunction

function! SetPmakeDebugLevel(level)
    if a:level == "silent"      ||
      \a:level == "error"       ||
      \a:level == "warn"        ||
      \a:level == "info"        ||
      \a:level == "verbose"     ||
      \a:level == "annoy"
        let $T5PMDEBUGLEVEL = a:level
        echo "$T5PMDEBUGLEVEL is now " . $T5PMDEBUGLEVEL
    endif
endfunction

function! SetPmakeCCompiler(ccomp)
    if a:ccomp == "vc6"         ||
      \a:ccomp == "ads"         ||
      \a:ccomp == "gcc"
        let $T5PMCCOMPILER = a:ccomp
        echo "$T5PMCCOMPILER is now " . $T5PMCCOMPILER
    endif
endfunction

function! SetPmakeDebugVia(via)
    if a:via == "output"        ||
      \a:via == "file"          ||
      \a:via == "socket"
        let $T5PMDEBUGVIA = a:via
        echo "$T5PMDEBUGVIA is now " . $T5PMDEBUGVIA
    endif
endfunction

function! SetPmakeTrackMem(track)
    if a:track == "tm" ||
      \a:track == "ntm"
        let $T5PMTRACKMEM = a:track
        echo "$T5PMTRACKMEM is now " . $T5PMTRACKMEM
    endif
endfunction

function! SetPmakeTrackPerf(track)
    if a:track == "tp" ||
      \a:track == "ntp"
        let $T5PMTRACKPERF = a:track
        echo "$T5PMTRACKPERF is now " . $T5PMTRACKPERF
    endif
endfunction

function! SetPbuildVariety(var)
    if a:var == "REL"
        call SetPmakeStyle("rel")
        call SetPmakeDebugLevel("silent")
        call SetPmakeDebugVia("output")
        call SetPmakeTrackMem("ntm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "DBG"
        call SetPmakeStyle("dbg")
        call SetPmakeDebugLevel("info")
        call SetPmakeDebugVia("output")
        call SetPmakeTrackMem("ntm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "CHATTY"
        call SetPmakeStyle("rel")
        call SetPmakeDebugLevel("info")
        call SetPmakeDebugVia("file")
        call SetPmakeTrackMem("ntm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "PROTEST"
        call SetPmakeStyle("rel")
        call SetPmakeDebugLevel("info")
        call SetPmakeDebugVia("output")
        call SetPmakeTrackMem("ntm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "REL-TRACKMEM"
        call SetPmakeStyle("rel")
        call SetPmakeDebugLevel("silent")
        call SetPmakeDebugVia("output")
        call SetPmakeTrackMem("tm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "DBG-TRACKMEM"
        call SetPmakeStyle("dbg")
        call SetPmakeDebugLevel("info")
        call SetPmakeDebugVia("output")
        call SetPmakeTrackMem("tm")
        call SetPmakeTrackPerf("ntp")
    elseif a:var == "CHATTY-TRACKMEM"
        call SetPmakeStyle("rel")
        call SetPmakeDebugLevel("info")
        call SetPmakeDebugVia("file")
        call SetPmakeTrackMem("tm")
        call SetPmakeTrackPerf("ntp")
    endif
endfunction

" style
" sdk
" debug_level
" ccompiler
" debug_via
" trackmem
" trackperf

amenu 100.10 &Pmake.Open\ pmake\ file\ in\ &current\ directory :call OpenCurrentPmakeFile ()<CR>
amenu 100.20 &Pmake.Open\ pmake\ file\ in\ &parent\ directory :call OpenParentPmakeFile ()<CR>

amenu 100.30.10 &Pmake.&style.&dbg :call SetPmakeStyle ("dbg")<CR>
amenu 100.30.20 &Pmake.&style.&rel :call SetPmakeStyle ("rel")<CR>

amenu 100.40.10 &Pmake.sd&k.&2\.1\.0 :call SetPmakeSDK ("210")<CR>
amenu 100.40.20 &Pmake.sd&k.&3\.1\.2 :call SetPmakeSDK ("312")<CR>

amenu 100.50.10 &Pmake.debug_&level.&silent :call SetPmakeDebugLevel ("silent")<CR>
amenu 100.50.20 &Pmake.debug_&level.&error :call SetPmakeDebugLevel ("error")<CR>
amenu 100.50.30 &Pmake.debug_&level.&warn :call SetPmakeDebugLevel ("warn")<CR>
amenu 100.50.40 &Pmake.debug_&level.&info :call SetPmakeDebugLevel ("info")<CR>
amenu 100.50.50 &Pmake.debug_&level.&verbose :call SetPmakeDebugLevel ("verbose")<CR>
amenu 100.50.60 &Pmake.debug_&level.&annoy :call SetPmakeDebugLevel ("annoy")<CR>

amenu 100.60.10 &Pmake.&ccompiler.&vc6 :call SetPmakeCCompiler ("vc6")<CR>
amenu 100.60.20 &Pmake.&ccompiler.&ads :call SetPmakeCCompiler ("ads")<CR>
amenu 100.60.30 &Pmake.&ccompiler.&gcc :call SetPmakeCCompiler ("gcc")<CR>

amenu 100.70.10 &Pmake.debug_&via.&output :call SetPmakeDebugVia ("output")<CR>
amenu 100.70.20 &Pmake.debug_&via.&file :call SetPmakeDebugVia ("file")<CR>
amenu 100.70.30 &Pmake.debug_&via.&socket :call SetPmakeDebugVia ("socket")<CR>

amenu 100.80.10 &Pmake.&trackmem.&tm :call SetPmakeTrackMem ("tm")<CR>
amenu 100.80.20 &Pmake.&trackmem.&ntm :call SetPmakeTrackMem ("ntm")<CR>

amenu 100.90.10 &Pmake.&trackperf.&tp :call SetPmakeTrackPerf ("tp")<CR>
amenu 100.90.20 &Pmake.&trackperf.&ntp :call SetPmakeTrackPerf ("ntp")<CR>

amenu 100.999.10 &Pmake.&Varieties.&REL :call SetPbuildVariety("REL")<CR>
amenu 100.999.20 &Pmake.&Varieties.&DBG :call SetPbuildVariety("DBG")<CR>
amenu 100.999.30 &Pmake.&Varieties.&CHATTY :call SetPbuildVariety("CHATTY")<CR>
amenu 100.999.40 &Pmake.&Varieties.&PROTEST :call SetPbuildVariety("PROTEST")<CR>
amenu 100.999.50 &Pmake.&Varieties.&REL-TRACKMEM :call SetPbuildVariety("REL-TRACKMEM")<CR>
amenu 100.999.60 &Pmake.&Varieties.&DBG-TRACKMEM :call SetPbuildVariety("DBG-TRACKMEM")<CR>
amenu 100.999.70 &Pmake.&Varieties.&CHATTY-TRACKMEM :call SetPbuildVariety("CHATTY-TRACKMEM")<CR>
