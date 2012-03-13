#!/bin/bash

function hgroot ()
{
    while [[ ! -d .hg && $(pwd) != "/" ]] ; do
        cd .. ;
    done ;
    test -d .hg
}

function __hgst ()
{
    hg st | awk '$1 ~ /^'"${1}"'$/ {print $2};' ;
}

function __hgst_count ()
{
    hg st | egrep -ce "^${1}\>"
}

function hgmodified ()
{
    __hgst M
}

function hgadded ()
{
    __hgst A
}

function hgdeleted ()
{
    __hgst D
}

function hgneedscommit ()
{
    __hgst "[MAD]"
}

function hgneedscommit_count ()
{
    __hgst_count "[MAD]"
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
    __hgdo_eval 'hg diff $(hgmodified) > ${hgtemp} '${*}
}

function hgdiff ()
{
    __hgdiff_eval '; fileBiggerThanScreen ${hgtemp} && out=less || out=cat ; colordiff < ${hgtemp} | $out'
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
    ( hgroot && orphan hg view )
}

hgci ()
{
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
        if [[ ${#files[@]} -gt 0 ]] ; then
            local -r msg="${*}"
            ( set -x; hg pul -u && hg ci -m "${msg}" "${files[@]}" && hg push )
        else
            echo No files specified
        fi
    else
        echo "Nothing modified" >&2
    fi
}

function __hg ()
{
    . ~/.dotFiles/bash/hg.bash
}
