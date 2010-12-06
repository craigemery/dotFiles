" Vim compiler file
" Compiler:	cc
" Maintainer:	Craig Emery <craig.emery@qualcomm.com>
" URL:		http://www.qualcomm.com/
" Last Change:	2007 Aug 17

if exists("current_compiler")
  finish
endif
let current_compiler = "cc"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=cc.bat

"CompilerSet errorformat=%f(%l\\,%c):%m
"CompilerSet errorformat=%A%f(%l\\,%c):\ %t%*[^\ ]\ %n:\ %m,%C%p_,%Z%s,%t%*[\ ]\ %n:\ %m\ (line\ %l\\,\ file\ %f)%*[^`]
