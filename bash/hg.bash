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

function hgdiff ()
{
    ( hgroot && ( f=/tmp/hgdiff.$$ ; hg diff $(hgmodified) > $f ; fileBiggerThanScreen $f && out=less || out=cat ; colordiff < $f | $out ) ) ;
}

function ghgdiff ()
{
    ( hgroot && ( f=/tmp/ghgdiff.$$ ; hg diff $(hgmodified) > $f && gvimdiff -c 'se modified! | se guifont="Monospace 16"' - < $f 2>&- ) ) ;
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
