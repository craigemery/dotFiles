#!/bin/bash

export EDITOR=vim
export WINEDITOR=${EDITOR}
export CVS_RSH=/usr/bin/ssh
export CVSEDITOR="${EDITOR} -f"
export XEDITOR=${EDITOR}

appendToPath /usr/sbin
appendToPath /sbin
appendToPath .
appendToPath /etc/profile.d
appendToPath /usr/local/bin
appendToPath ~/dist/shell
appendToPath ~/dist/python

export ESHELL=${SHELL}

# Files you make look like rw-rw-r
umask 002

export HOST=${HOSTNAME}

# Things
export FIGNORE=".o"	# Suffixes to ignore for filename completion

# History
#export HISTCONTROL=ignoreboth
export HISTSIZE=1000

#export LS_COLORS='no=00:fi=00:di=01;94:ln=32:pi=40;33:so=01;95:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;92:*.tar=01;91:*.tgz=01;91:*.arj=01;91:*.taz=01;91:*.lzh=01;91:*.zip=01;91:*.z=01;91:*.Z=01;91:*.gz=01;91:*.deb=01;91:*.jpg=01;95:*.gif=01;95:*.bmp=01;95:*.ppm=01;95:*.tga=01;95:*.xbm=01;95:*.xpm=01;95:*.tif=01;95:*.mpg=01;97:*.avi=01;97:*.gl=01;97:*.dl=01;97:*.idl=01;96:*.c=01;96:*.cpp=01;96:*.h=36:*.o=96:*.a=92:*.in=95:*.so=30:*.cvsignore=01;30:*.depend=30:*.depend_debug=30:*.depend_release=30:*.bak=30:*.swp=30:*.swo=30:*.dsp=01;95:*.dsw=01;95:*.make.out=30:*.mak=33:*.mk=33:*.txt=92:*.ps=92:*.pdf=92:*makefile=33:*Imakefile=01;93:*Makefile=01;33:*-=30

# include colorls.bash

export CDPATH=.:${HOME}
export PAGER=less

complete -d -X \*CVS cd
complete -A alias alias
complete -c nohup

export CTIME_HELP_DIR=/usr/share/corptime

xtermTitle '${USER}@${HOSTNAME%%.*}:$(tty | sed -e s/\\/dev\\/tty//):cwd=$(npwd)'
rxvtTitle '$(tty | sed -e s/\\/dev\\/tty//):$(npwd)'

case $TERM in
    cygwin*|screen*|xterm*)
        if [ ! -e /etc/sysconfig/bash-prompt-xterm ]; then
            PS1=""
            PROMPT_COMMAND='echo -n "$(titles both '${XTERM_TITLE}')"'
        fi
    ;;

    *rxvt)
        PS1=""
        PROMPT_COMMAND='echo -n "$(titles both '${RXVT_TITLE}')"'
    ;;

    linux)
        PS1="\[$(colour fg green 2>&-)\]\w: "
    ;;
esac

PS1="${PS1}\[$(colour fg blue 2>&-)\]\t \[$(colour fg red 2>&-)\]\$\[$(colour reset 2>&-)\] "

# . ads.profile

export TRIG_DEBUG_VERBOSE_COLOUR="FG_Yellow"
