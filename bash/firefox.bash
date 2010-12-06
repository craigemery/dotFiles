#!/usr/bin/env bash

function _ff-pdir ()
{
    #assume local RESULT
    RESULT="${HOME}/Library/Application Support/Firefox/Profiles"
}

function ff-pdir ()
{
    local RESULT
    _ff-pdir
    echo "${RESULT}"
}

function ff-cd-pdir ()
{
    local RESULT
    _ff-pdir
    cd "${RESULT}"
}

function ff-np
{
    local RESULT
    _ff-pdir
    local -r pdir="${RESULT}"
    unset RESULT
    local profile="${1}"
    shift
    if [[ ! -d "${profile}" && ! -d "${pdir}/${profile}" ]] ; then
        trace mkdir -p "${pdir}/${profile}"
        eval "alias 'ff-"${profile}"=ff-p "${profile}"'"
        eval "alias ff-"${profile}
    fi
}

function ff ()
{
    __versioned_mac_app Firefox "${@}"
}

function ff-fr ()
{
    __versioned_mac_app Firefox-fr "${@}"
}

function ff-p ()
{
    local RESULT
    _ff-pdir
    local -r pdir="${RESULT}"
    unset RESULT
    local profile="${1}"
    shift
    local then_quit=""
    if [[ "${1}" == "-q" ]] ; then
        then_quit=y
        shift
    fi
    if [[ ! -d "${profile}" && "${pdir}/${profile}" ]]; then
        profile="${pdir}/${profile}"
    fi
    ff -profile "${profile}" "${@}"
    [[ "${then_quit}" ]] && exit
}

function ff-kill-p ()
{
    local RESULT
    _ff-pdir
    local -r pdir="${RESULT}"
    unset RESULT
    local profile="${1}"
    shift
    if [[ ! -d "${profile}" && "${pdir}/${profile}" ]]; then
        profile="${pdir}/${profile}"
    fi
    trace rm -fr "${profile}"
}

function ff-tp ()
{
    local RESULT
    _ff-pdir
    local -r d=${RESULT}/temp
    unset RESULT
    [[ -d "${d}" ]] || mkdir -p "${d}" 2>&-
    [[ -d "${d}" ]] || return 0
    local -r p=$(mktemp -d "${d}/XXXXXX" 2>&-)
    [[ -d "${p}" ]] || return 1
    trace ff-p "${p}" "${@}"
}

function __ff_profile_list ()
{
    #assume local -a RESULT=()
    _ff-pdir
    local -r pdir=${RESULT}
    RESULT=()
    local entry
    for entry in "${pdir}"/* ; do
        if [[ -d "${entry}" && -f "${entry}/prefs.js" && ! "${entry##*/}" =~ " " ]] ; then
            RESULT[${#RESULT[@]}]="${entry##*/}"
        fi
    done
}

function __make_ff_p_aliases ()
{
    local RESULT=()
    __ff_profile_list
    local profile=""
    for profile in "${RESULT[@]}" ; do
        #eval "function ff-"${profile}" () { ff-p "${profile}" "'"${@}"'"; } "
        eval "alias 'ff-"${profile}"=ff-p "${profile}"'"
    done
}
__make_ff_p_aliases


function __make_ff_aliases ()
{
    local RESULT=()
    __app_versions Firefox
    local ver=""
    for ver in "${RESULT[@]}" ; do
        [[ "${ver}" ]] && eval "alias 'ff_"${ver}"=ff -v "${ver}"'"
    done
}
__make_ff_aliases
