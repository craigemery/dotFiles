#!/bin/bash

prependDistToEnv ${HOME}/dist

if [ -z "${CDPATH}" ] ; then
    CDPATH=.
fi
CDPATH=${CDPATH}:${dist}

#uniqList=${dist_shell}/uniqList
#if [ -x ${uniqList} ] ; then
#	export PATH=`${uniqList} ${PATH}`
#	export MANPATH=`${uniqList} ${MANPATH}`
#	export LD_LIBRARY_PATH=`${uniqList} ${LD_LIBRARY_PATH}`
#fi
