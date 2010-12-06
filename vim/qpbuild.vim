
function! FindQpbuildCfg ()
   let cfg = FindUpTree("/qpbuild.cfg")
   if filereadable (cfg)
      exec "lcd " . fnamemodify (cfg, ":h")
   endif
endfunction
