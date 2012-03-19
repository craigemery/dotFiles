#!/bin/bash

##############################
# commands for invoking pbuild
##############################

function t4PbDefaultProduct ()
{
    t4RcOrDefault DEFAULT_PRODUCT TONKA
}

function t4PbValidProductArray ()
{
    if [[ -z "${T4_HOME}" ]] ; then
        echo 'You *must* have $T4_HOME set' >&2
        return 1
    fi
    local -r product_file="${T4_HOME%/*/*}/tmp/cm-tools/src/XMLAutoBuild/product-cvs-mapping.xml"
    if [[ ! -f "${product_file}" ]] ; then
        echo 'You *must* have a *valid* $T4_HOME set' >&2
        return 1
    fi

    RESULT=( $(sed -n -e 's@^[[:space:]]*<PRODUCT[[:space:]]\+name[[:space:]]*=[[:space:]]*"\([^"]\+\)">[[:space:]]*$@\1@p' < "${product_file}") )
}

function t4PbIsValidProduct ()
{
    local -a RESULT
    local -r test="${1}"
    t4PbValidProductArray || return ${?}
    local product
    for product in "${RESULT[@]}" ; do
        [[ "${test}" == "${product}" ]] && return 0
    done
    return 1
}

function t4PbIsInvalidProduct ()
{
    t4PbIsValidProduct "${1}" || return 0
    return 1
}

[[ -z "${NO_COMPLETE}" ]] && complete -W "$(t4ChPmStyle --list-sep=' ' --list)" t4ChPmStyle

# timing and colouring
function pb ()
{
    local -r start=$(secondsSinceEpoch)
    case "${1}" in
    co|checkout) ;;
    *)
        if [[ -z "${T4_HOME}" ]] ; then
            echo 'You *must* have $T4_HOME set' >&2
            return 1
        fi

        local -a args=("${@}")
        local -i idx=${#args[@]}
        let idx=--idx
        if t4PbIsInvalidProduct ${args[${idx}]} ; then
            local -r product="$(t4PbDefaultProduct)"
            echo "Using default product '${product}'" >&2
            set -- "${@}" "${product}"
        fi
    ;;
    esac
    t4MakeTitle pbuild "${@}"
    export RETFILE=/tmp/pb.${$}
    export MYPLATFORM="$(uname -s)"
    trap "rm -f ${RETFILE}" EXIT INT
    (
        date +%D\ %H:%M.%S
        cd "${T4_HOME%/*/*}"
        if [[ "${MYPLATFORM}" == "CYGWIN_NT-5.1" ]] ; then
            export SYMBIAN_6_1=c:\\Symbian\\6.1
            export SYMBIAN_7_0=c:\\Symbian\\7.0s
            export PMAKE_2=$(_Pw ${PMAKE_2})
            local py23=/cygdrive/c/Python23
            export PYTHON_2_3=$(_Pw ${py23})
            ${py23}/python.exe -u ${PMAKE_2%\\*}\\pythonbuild\\pbuild.py "${@}" 2>&1
        else
            export CVS_CL_TOOL=$(which cvs)
            local py23=$(which python2.3)
            py23=${py23%/*}
            export PYTHON_2_3=${py23}
            ${py23}/python2.3 -u ${PMAKE_2%/*}/pythonbuild/pbuild.py "${@}" 2>&1
        fi
        declare -r -i ret=${?}
        echo ${ret} > ${RETFILE}
        date +%D\ %H:%M.%S
        echo "pbuild returned ${ret} (and took $(elapsed ${start}))"
    ) |
    if [[ "${mf}" ]] ; then
        if [[ "${MYPLATFORM}" == "CYGWIN_NT-5.1" ]] ; then
            tr -d \\015 | tee ${mf}
        else
            tee ${mf}
        fi
    else
        cat
    fi | fmo
    declare -r -i ret=$(cat ${RETFILE})
    unset RETFILE
    unset MYPLATFORM
    return ${ret}
}

# timing, colouring and recording
function dpb ()
{
    local mf="${PWD}/.${USER}.pbuild.out"
    # tput cup $(tput lines)
    pb "${@}"
    return ${?}
}

# last recorded
function dpbo ()
{
    local mf="${PWD}/.${USER}.pbuild.out"
    if [[ -f ${mf} ]] ; then
        if fileBiggerThanScreen ${mf} ; then
            fmo < ${mf} 2>&1 | less
        else
            fmo < ${mf} 2>&1
        fi
    fi
}

# Use pbuild to do a checkout or update
function pbcvs ()
{
    local cmd="${1}"
    local product="${2}"
    if [[ -z "${product}" ]] ; then
        product="$(t4PbDefaultProduct)"
        echo "Using default product '${product}'" >&2
    fi
    case "${cmd}" in
    up|update) cmd="up" ;;
    co|checkout) cmd="co" ;;
    *) return ;;
    esac
    pb ${cmd} -u ${USER} --connect=ext "${product}"
}

function pbcheckout ()
{
    pbcvs checkout "${1}"
}

function pbco
{
    pbcheckout "${@}"
}

function pbupdate ()
{
    pbcvs update "${1}"
}

function pbup
{
    pbupdate "${@}"
}

# Functions for building all varieties that match a string / re
function pbmatch ()
{
    local spec="${1}"
    local product="${2}"
    if [[ -z "${product}" ]] ; then
        product="$(t4PbDefaultProduct)"
        echo "Using default product '${product}'" >&2
    fi
    local variety_args=$(t4MatchVarietyArgs "${spec}" ${product})
    if [[ "${variety_args}" ]] ; then
        echo pb build --verbose ${variety_args} ${product}
        pb build --verbose ${variety_args} ${product}
    else
        echo "No varieties match '${spec}'" >&2
    fi
}
function dpbmatch ()
{
    local spec="${1}"
    local product="${2}"
    if [[ -z "${product}" ]] ; then
        product="TONKA"
    fi
    local variety_args=$(t4MatchVarietyArgs "${spec}" ${product})
    if [[ "${variety_args}" ]] ; then
        echo dpb build --verbose ${variety_args} ${product}
        dpb build --verbose ${variety_args} ${product}
    else
        echo "No varieties match '${spec}'" >&2
    fi
}

function t4CompletePbuild ()
{
    if [[ "${3}" = "-V" ]] ; then
        COMPREPLY=($(t4MatchVariety "${2}"))
    else
        COMPREPLY=()
    fi
}

if [[ -z "${NO_COMPLETE}" ]] ; then
    complete -F t4CompletePbuild pBuild
    complete -F t4CompletePbuild dpBuild
fi

function pBuild
{
    pb build --verbose "${@}"
}

function dpBuild
{
    dpb build --verbose "${@}"
}

