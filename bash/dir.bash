#!/bin/bash

function npwd ()
{
    case "${PWD}" in
    ${HOME}/*)  echo "~${PWD#${HOME}}" ;;
    ${HOME}*)   echo "~/${PWD#${HOME}}" ;;
    /cygdrive/*)echo "${PWD}" | sed -e 's@/cygdrive/\(.\)@\1:@' ;;
    *)          echo "${PWD}" ;;
    esac
}

function cd ()
{
    if [ "${1}" ] ; then
        pushd "${1}" > /dev/null
    else
        pushd ~/ > /dev/null
    fi
}

function with_cd ()
{
    cd "${1}" ; shift
    "${@}"
    back
}

function with_cd_eval ()
{
    local -r d="${1}" ; shift
    with_cd "${d}" eval "${*}"
}

function cdl ()
{
    local -i count=0
    local -r -i limit=${#DIRSTACK[@]}
    while [ ${count} -lt ${limit} ] ; do
        local d="${DIRSTACK[${count}]}"
        echo "${count}:${d/${HOME}/~}"
        count=$((++count))
    done
}

function cdc ()
{
    cd
    dirs -c
}

function swap ()
{
    if [ "${1}" ] ; then
        pushd +1 > /dev/null
    else
        pushd +${1} > /dev/null
    fi
}

function chdir ()
{
    if [ -n "${CDPATH}" ] ; then
        local old="${CDPATH}"
        unset CDPATH
        cd "${1}"
        export CDPATH="${old}"
    else
        cd "${1}"
    fi
}

function back
{
    popd > /dev/null 2>&1 "${@}"
}

function b
{
    back "${@}"
}

function s
{
    swap "${@}"
}

function s1
{
    swap 1 "${@}"
}

function s2
{
    swap 2 "${@}"
}

function s3
{
    swap 3 "${@}"
}

function make_listing ()
{
    local -r dir="${1}"
    if [[ -d "${dir}" ]] ; then
        local -r -a names=(desktop.ini .ds_store thumbs.db)
        local -a excluded=()
        local ex
        for ex in "${names[@]}" ; do
            if [[ ${#excluded[@]} -gt 0 ]] ; then
                excluded[${#excluded[@]}]='-o'
            fi
            excluded[${#excluded[@]}]='-iname'
            excluded[${#excluded[@]}]="${ex}"
        done
        find "${dir}" -type f -a \! \( ${excluded[@]} \) -print |
        sed -e '/\.jpg/d' -e '/\.jpeg/d' -e 's@^'${dir}/'@@' -e 's@^ABBA/@Abba/@' |
        sort
    fi
}

function __dir ()
{
   . dir.bash
}
