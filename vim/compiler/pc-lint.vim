" Vim compiler file
" Compiler:	PC-Lint
" Maintainer:	Craig Emery <craig.emery@qualcomm.com>
" URL:		http://www.qualcomm.com/
" Last Change:	2007 Aug 13

if exists("current_compiler")
  finish
endif
let current_compiler = "pc-lint"

if exists(":CompilerSet") != 2		" older Vim always used :setlocal
  command -nargs=* CompilerSet setlocal <args>
endif

CompilerSet makeprg=lint.bat

"CompilerSet errorformat=%f(%l\\,%c):%m
CompilerSet errorformat=%A%f(%l\\,%c):\ %t%*[^\ ]\ %n:\ %m,%C%p_,%Z%s,%t%*[\ ]\ %n:\ %m\ (line\ %l\\,\ file\ %f)%*[^`]
