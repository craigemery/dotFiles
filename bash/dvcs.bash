#!/bin/bash

. $(dirname $(readlink -f "${BASH_SOURCE[0]}"))/hg.bash
. $(dirname $(readlink -f "${BASH_SOURCE[0]}"))/git.bash

DVCS_ROOT=""

function _is_git_dir ()
{
    test -d "${1}/.git"
    return $?
}

function _is_hg_dir ()
{
    test -d "${1}/.hg"
    return $?
}

function _is_dvcs_dir ()
{
    _is_git_dir "${1}" || _is_hg_dir "${1}"
    return $?
}

function _find_dvcs_dir ()
{
    (
    [[ "${1}" ]] && _is_dvcs_dir "${1}" && cd "${1}"
    while ! _is_dvcs_dir . && [[ $(pwd) != "/" ]] ; do
        cd .. ;
    done ;
    pwd ;
    )
}

function _guess_dvcs ()
{
    local -r candidate=$(_find_dvcs_dir "${@}")
    if _is_git_dir "${candidate}" ; then
        DVCS_ROOT="${candidate}"
        RESULT="git"
    elif _is_hg_dir "${candidate}" ; then
        DVCS_ROOT="${candidate}"
        RESULT="hg"
    fi
}

function Dguess ()
{
    local RESULT
    _guess_dvcs
    echo "${RESULT}"
}

function _make_Dfunc ()
{
    while [[ $# -gt 0 ]] ; do
        eval 'D'"${1}"' () { local RESULT ; _guess_dvcs ; [[ "${RESULT}" ]] && ${RESULT}'"${1}" \"\${@}\"' ; DVCS_ROOT=""; }'
        shift
    done
}

function _make_Dsimplefunc ()
{
    while [[ $# -gt 0 ]] ; do
        eval 'D'"${1}"' () { local RESULT ; _guess_dvcs ; [[ "${RESULT}" ]] && ( ${RESULT}root && ${RESULT} '"${1}" \"\${@}\"' ) ; DVCS_ROOT=""; }'
        shift
    done
}

_make_Dfunc diff modified ci needscommit{,_count} added deleted missing nottracked up view log
_make_Dsimplefunc push

function Dst ()
{
    local RESULT
    _guess_dvcs "${@}"
    [[ "${RESULT}" ]] && ${RESULT} status
}

unset _make_Dfunc

function __dvcs ()
{
    . ~/.dotFiles/bash/dvcs.bash
}
