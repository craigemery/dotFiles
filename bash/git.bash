#!/bin/bash

function gitroot ()
{
    [[ "${1}" && -d "${1}/.git" ]] && cd "${1}"
    while [[ ! -d .git && $(pwd) != "/" ]] ; do
        cd .. ;
    done ;
    test -d .git
}

function __gitst ()
{
    local -r q="${1}" ; shift
    git status --short "${@}" | sed -ne "s/^${q} //p"
}

function __gitst_count ()
{
    __gist "${@}" | wc -l
}

#function __gitst_test ()
#{
    #local -r q="${1}" ; shift
    #git status "${@}" | egrep -qe "^${q}\>"
#}

function gitnottracked ()
{
    __gitst '??' "${@}"
}

function gitmodified ()
{
    __gitst '[ M]M' "${@}"
}

function gitadded ()
{
    __gitst 'A[ MD]' "${@}"
}

function gitdeleted ()
{
    __gitst '[ D]D' "${@}"
}

function gitmissing ()
{
    gitdeleted "${@}"
}

function gitneedscommit ()
{
    __gitst "[MADR]" "${@}"
}

function gitneedscommit_count ()
{
    __gitst_count "[MADR]" "${@}"
}

function __gitmytemp ()
{
    declare -r keep_gittemp="y"
}

function __gitdo ()
{
    ( export gittemp=/tmp/git.$$ ; gitroot && "${@}" ; declare -ri ret=${?} ; if [[ -z "${keep_gittemp}" ]] ; then rm -f "${gittemp}" ; fi ; exit ${ret} ; )
}

function __gitdo_eval ()
{
    __gitdo eval "${@}"
}

function __gitdiff_eval ()
{
    if [[ -f "${1}" ]] ; then
        local -r s='git diff '"${1}"' > ${gittemp} '
        shift
    else
        local -r s='git diff $(gitmodified) > ${gittemp} '
    fi
    __gitdo_eval "${s}"${*}
}

function gitdiff ()
{
    __gitdiff_eval $1 '; fileBiggerThanScreen ${gittemp} && out=less || out=cat ; colordiff < ${gittemp} | $out'
}

function __git ()
{
    . ~/.dotFiles/bash/git.bash
}
