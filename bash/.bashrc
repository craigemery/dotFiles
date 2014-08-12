#!/bin/bash
if ! shopt -q login_shell ; then
   export PATH=/usr/bin:/bin:/usr/X11R6/bin:$PATH
   #export PATH=C:\\utils\\cygwin\\bin:C:\\utils\\cygwin\\usr\\bin:$PATH
   export USER=cemery
fi
. ~/.dotFiles/bash/bootstrap.bash
alias 'll=ls --color=auto -lAF'
. dropbox.bash
