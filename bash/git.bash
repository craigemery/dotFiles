#!/bin/bash

function gitroot ()
{
    [[ "${1}" && -d "${1}/.git" ]] && cd "${1}"
    while [[ ! -d .git && $(pwd) != "/" ]] ; do
        cd .. ;
    done ;
    test -d .git
}

function __gitrealpath ()
{
    ( gitroot ; xargs -n1 -r readlink -f )
}

function __gitrelpath ()
{
    __gitrealpath | sed -e "s@^$(readlink -f .)/@@"
}


function __gitst ()
{
    local -r q="${1}" ; shift
    local post=cat
    if [[ "${1}" = "-c" ]] ; then
        shift
        post="wc -l"
    elif [[ "${1}" = "-r" ]] ; then
        shift
        post="__gitrealpath"
    fi
    git status --short "${@}" | sed -ne "s/^${q} //p" | ${post}
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
    __gitst ".[MADR]" "${@}"
}

function gitneedscommit_count ()
{
    gitneedscommit "${@}" | wc -l
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

function gitup ()
{
    ( gitroot && git pull )
}

function gitview ()
{
    ( gitroot && orphan qgit )
}

function gitci ()
{
    local push=no
    local echo=trace
    local auto=""
    local dry=""
    local add=(true)
    while [[ $# -gt 0 ]] ; do
        case "${1}" in
        -*)
            case "${1}" in
            -p|--push) push=yes ;;
            -d|--dry) echo=diag ; dry="--dry-run" ;;
            -h|-\?|--help) echo "Usage gitci [-p|--push] file... [--] comment" >&2 ; return ;;
            *) echo "Invalid switch" >&2 ; return ;;
            esac
            shift
        ;;
        *) break ;;
        esac
    done
    if [[ $(gitneedscommit_count) -gt 0 ]] ; then
        local -a files=()
        while [[ $# -gt 0 ]] ; do
            if [[ "${1}" == "--" ]] ; then
                break
            elif [[ -f "${1}" ]] ; then
                files[${#files[@]}]="${1}"
            elif [[ -d "${1}" ]] ; then
                files[${#files[@]}]="${1}"
            else
                break
            fi
            shift
        done
        if [[ ${#files[@]} -eq 0 ]] ; then
            auto="a"
        else
            add=( ${echo} git add "${files[@]}" )
        fi
        local -r msg="${*}"
        ( ${echo} git pull && ${add[@]} && trace git commit ${dry} -${auto}m "${msg}" "${files[@]}" && [[ ${push} == yes ]] && ${echo} git push )
    else
        echo "Nothing modified" >&2
    fi
}

function __git ()
{
    . ~/.dotFiles/bash/git.bash
}
