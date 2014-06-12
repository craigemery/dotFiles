#!/bin/bash

function hgroot ()
{
    [[ "${1}" && -d "${1}/.hg" ]] && cd "${1}"
    while [[ ! -d .hg && $(pwd) != "/" ]] ; do
        cd .. ;
    done ;
    test -d .hg
}

function __hgst ()
{
    local -r q="${1}" ; shift
    if [[ "${1}" = "-c" ]] ; then
        shift
        awk='{count+=1;};END{print count;};'
    else
        awk='{print $2};'
    fi
    hg st "${@}" | awk 'BEGIN{count=0}; $1 ~ /^'"${q}"'$/ '"${awk}" ;
}

function __hgst_count ()
{
    local -r q="${1}" ; shift
    hg st "${@}" | egrep -ce "^${q}\>"
}

function __hgst_test ()
{
    local -r q="${1}" ; shift
    hg st "${@}" | egrep -qe "^${q}\>"
}

#function HgIsTracked ()
#{
    #__hgst_test '[MARC!]' "${@}"
#}

function hgnottracked ()
{
    __hgst '\?' "${@}"
}

function hgmodified ()
{
    __hgst M "${@}"
}

function hgadded ()
{
    __hgst A "${@}"
}

function hgdeleted ()
{
    __hgst D "${@}"
}

function hgmissing ()
{
    __hgst '!' "${@}"
}

function hgneedscommit ()
{
    __hgst "[MADR]" "${@}"
}

function hgneedscommit_count ()
{
    __hgst_count "[MADR]" "${@}"
}

function __hgmytemp ()
{
    declare -r keep_hgtemp="y"
}

function __hgdo ()
{
    ( export hgtemp=/tmp/hg.$$ ; hgroot && "${@}" ; declare -ri ret=${?} ; if [[ -z "${keep_hgtemp}" ]] ; then rm -f "${hgtemp}" ; fi ; exit ${ret} ; )
}

function __hgdo_eval ()
{
    __hgdo eval "${@}"
}

function __hgdiff_eval ()
{
    if [[ -f "${1}" ]] ; then
        local -r s='hg diff '"${1}"' > ${hgtemp} '
        shift
    else
        local -r s='hg diff $(hgmodified) > ${hgtemp} '
    fi
    __hgdo_eval "${s}"${*}
}

function hgdiff ()
{
    __hgdiff_eval $1 '; fileBiggerThanScreen ${hgtemp} && out=less || out=cat ; colordiff < ${hgtemp} | $out'
}

function __gvimdiff ()
{
    gvim -c 'se ft=diff | se modified! | se guifont="Monospace 16"' "${@}" 2> /dev/null
}

function ghgdiff ()
{
    __hgdiff_eval '&& __hgmytemp && cat ${hgtemp} | __gvimdiff -'
}

function hgview ()
{
    ( hgroot ${1} && orphan /usr/bin/hgview )
}

hgci ()
{
    local push=no
    local echo=""
    while [[ $# -gt 0 ]] ; do
        case "${1}" in
        -*)
            case "${1}" in
            -p|--push) push=yes ;;
            -d|--dry) echo=echo ;;
            -h|-\?|--help) echo "Usage hgci [-p|--push] file... [--] comment" >&2 ; return ;;
            *) echo "Invalid switch" >&2 ; return ;;
            esac
            shift
        ;;
        *) break ;;
        esac
    done
    if [[ $(hgneedscommit | wc -l) -gt 0 ]] ; then
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
            files=(.)
        fi
        local -r msg="${*}"
        ( set -x; ${echo} hg pul -u && ${echo} hg ci -m "${msg}" "${files[@]}" && [[ ${push} == yes ]] && ${echo} hg push )
    else
        echo "Nothing modified" >&2
    fi
}

function hgstash ()
{
    local -r name="${1}" ; shift ;
    local -r stash=/tmp/hg.stash.${name}.tar.gz ;
    hgroot ;
    if [[ $(hgmodified -c) -gt 0 ]] ; then
        echo $stash ;
        tar zcvf ${stash} $(hgmodified) ;
        echo reverting $(hgmodified) ;
        hg revert $(hgmodified) ;
    fi ;
}

function hgunstash ()
{
    local -r name="${1}" ; shift ;
    local -r base=/tmp/hg.stash. ;
    local -r suff=.tar.gz ;
    local -r stash=${base}${name}${suff} ;
    if [[ -f ${stash} ]] ; then
        hgroot ;
        tar zxvf ${stash} ;
        rm -f ${stash} ;
    else
        echo "Stash ${name} doesn't exist"
        ls -lAF ${base}*${suff} ;
    fi ;
}

#hgcipush ()
#{
    #if [[ $(hgneedscommit | wc -l) -gt 0 ]] ; then
        #local -a files=()
        #while [[ $# -gt 0 ]] ; do
            #if [[ "${1}" == "--" ]] ; then
                #break
            #elif [[ -f "${1}" ]] ; then
                #files[${#files[@]}]="${1}"
            #elif [[ -d "${1}" ]] ; then
                #files[${#files[@]}]="${1}"
            #else
                #break
            #fi
            #shift
        #done
        #if [[ ${#files[@]} -gt 0 ]] ; then
            #local -r msg="${*}"
            #( set -x; hg pul -u && hg ci -m "${msg}" "${files[@]}" && hg push )
        #else
            #echo No files specified
        #fi
    #else
        #echo "Nothing modified" >&2
    #fi
#}

function findOrigFiles ()
{
    findNamed -X -n '*.orig'
}

function rmOrigFiles ()
{
    findOrigFiles | xargs -rtn1 rm
}

function __hg ()
{
    . ~/.dotFiles/bash/hg.bash
}
